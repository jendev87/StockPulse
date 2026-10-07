import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/enums.dart';
import '../../../services/ai_api_service.dart';
import '../bloc/stock_take_bloc.dart';

class VoiceCountBottomSheet extends StatefulWidget {
  final String? initialSku;
  final ValueChanged<int>? onQuantitySelected;
  final AiApiService? aiApiService;
  final SpeechToText? speechToText;

  const VoiceCountBottomSheet({
    super.key,
    this.initialSku,
    this.onQuantitySelected,
    this.aiApiService,
    this.speechToText,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialSku,
    ValueChanged<int>? onQuantitySelected,
    AiApiService? aiApiService,
    SpeechToText? speechToText,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => VoiceCountBottomSheet(
        initialSku: initialSku,
        onQuantitySelected: onQuantitySelected,
        aiApiService: aiApiService,
        speechToText: speechToText,
      ),
    );
  }

  @override
  State<VoiceCountBottomSheet> createState() => _VoiceCountBottomSheetState();
}

enum VoiceFlowState { listening, parsing, resolved, error }

class _VoiceCountBottomSheetState extends State<VoiceCountBottomSheet>
    with SingleTickerProviderStateMixin {
  late final SpeechToText _speech;
  late final AiApiService _aiService;
  late final AnimationController _waveController;
  late final TextEditingController _manualTextController;

  VoiceFlowState _flowState = VoiceFlowState.listening;
  bool _speechEnabled = false;
  bool _isListening = false;
  double _soundLevel = 0.0;
  String _currentTranscript = '';
  AiVoiceResult? _resolvedResult;
  int _editableQuantity = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _speech = widget.speechToText ?? SpeechToText();
    _aiService = widget.aiApiService ?? AiApiService.instance;
    _manualTextController = TextEditingController();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initSpeechAndListen();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _manualTextController.dispose();
    try {
      if (_speech.isListening) {
        _speech.cancel();
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initSpeechAndListen() async {
    try {
      // Check and request microphone permission at runtime
      try {
        final status = await Permission.microphone.status;
        if (!status.isGranted) {
          final requested = await Permission.microphone.request();
          if (requested.isPermanentlyDenied) {
            if (mounted) {
              setState(() {
                _flowState = VoiceFlowState.error;
                _errorMessage =
                    'Microphone permission is permanently denied. Please enable it in Settings or select a sample phrase below.';
                _speechEnabled = false;
                _isListening = false;
              });
            }
            return;
          } else if (!requested.isGranted) {
            if (mounted) {
              setState(() {
                _flowState = VoiceFlowState.error;
                _errorMessage =
                    'Microphone permission is required for voice counting.';
                _speechEnabled = false;
                _isListening = false;
              });
            }
            return;
          }
        }
      } catch (permErr) {
        debugPrint('[VoiceBottomSheet] Permission check note: $permErr');
      }

      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[VoiceBottomSheet] Speech status: $status');
          if (mounted) {
            setState(() {
              _isListening = _speech.isListening;
            });
          }
          if (status == 'done' || status == 'notListening') {
            if (_flowState == VoiceFlowState.listening &&
                _currentTranscript.trim().isNotEmpty) {
              _stopListeningAndProcess();
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('[VoiceBottomSheet] Speech error: ${errorNotification.errorMsg}');
          if (mounted && _flowState == VoiceFlowState.listening) {
            if (_currentTranscript.trim().isNotEmpty) {
              _stopListeningAndProcess();
            } else {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
      );

      if (mounted) {
        setState(() {
          _speechEnabled = available;
        });

        if (available) {
          _startListening();
        } else {
          setState(() {
            _flowState = VoiceFlowState.error;
            _errorMessage =
                'Speech recognition service unavailable on this device. Please select a sample phrase below.';
            _isListening = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _speechEnabled = false;
          _isListening = false;
          _flowState = VoiceFlowState.error;
          _errorMessage = 'Speech initialization error: $e';
        });
      }
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      await _initSpeechAndListen();
      return;
    }

    setState(() {
      _flowState = VoiceFlowState.listening;
      _currentTranscript = '';
      _resolvedResult = null;
      _errorMessage = null;
      _isListening = true;
    });

    try {
      try {
        await _speech.cancel();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      String? localeId;
      try {
        final loc = await _speech.systemLocale();
        localeId = loc?.localeId;
      } catch (_) {}

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (mounted) {
            setState(() {
              _currentTranscript = result.recognizedWords;
            });
            if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
              _stopListeningAndProcess();
            }
          }
        },
        onSoundLevelChange: (level) {
          if (mounted && _isListening) {
            setState(() {
              _soundLevel = level;
            });
          }
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          cancelOnError: false,
          partialResults: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          localeId: localeId,
        ),
      );
    } catch (e) {
      debugPrint('[VoiceBottomSheet] Listen exception: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  Future<void> _stopListeningAndProcess() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('[VoiceBottomSheet] stop exception: $e');
    }

    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }

    if (_currentTranscript.trim().isNotEmpty) {
      _processTranscript(_currentTranscript);
    } else {
      setState(() {
        _errorMessage =
            'No speech detected. Please speak or select a sample phrase below.';
        _flowState = VoiceFlowState.error;
      });
    }
  }

  Future<void> _processTranscript(String transcript) async {
    setState(() {
      _flowState = VoiceFlowState.parsing;
    });

    final products = context.read<StockTakeBloc>().state.products;

    try {
      final result = await _aiService.parseVoice(
        transcript: transcript,
        catalog: products,
      );

      if (mounted) {
        setState(() {
          _flowState = VoiceFlowState.resolved;
          _resolvedResult = result;
          _editableQuantity = result.quantity > 0 ? result.quantity : 1;
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _flowState = VoiceFlowState.error;
          _errorMessage = 'Voice parsing failed: $e';
        });
      }
    }
  }

  void _confirmAndApply() {
    final result = _resolvedResult;
    if (result == null) return;

    final targetSku = widget.initialSku ?? result.sku;
    final quantity = _editableQuantity;

    HapticFeedback.selectionClick();

    if (widget.onQuantitySelected != null) {
      widget.onQuantitySelected!(quantity);
    } else if (targetSku != null && targetSku.isNotEmpty) {
      context.read<StockTakeBloc>().add(
            UpdateCount(
              sku: targetSku,
              physicalQty: quantity,
              method: IdentificationMethod.voice,
            ),
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.statusMatch,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.mic, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Voice Saved: $quantity units of $targetSku',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.statusShortage,
          behavior: SnackBarBehavior.floating,
          content: Text('No catalog product matched. Please state product name or select an item.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333B4A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AI Voice Count Entry',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Flow State View
              if (_flowState == VoiceFlowState.listening) _buildListeningView(),
              if (_flowState == VoiceFlowState.parsing) _buildParsingView(),
              if (_flowState == VoiceFlowState.resolved) _buildResolvedView(),
              if (_flowState == VoiceFlowState.error) _buildErrorView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListeningView() {
    return Column(
      children: [
        // Pulsing / Interactive Microphone Button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            if (_isListening) {
              if (_currentTranscript.trim().isNotEmpty) {
                _stopListeningAndProcess();
              } else {
                try {
                  _speech.cancel();
                } catch (_) {}
                if (mounted) {
                  setState(() {
                    _isListening = false;
                  });
                }
              }
            } else {
              _startListening();
            }
          },
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final scale = _isListening
                  ? 1.0 + (_waveController.value * 0.12)
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? AppTheme.primaryBlue.withValues(
                            alpha: 0.12 + (_waveController.value * 0.15),
                          )
                        : const Color(0xFF242A36),
                    border: Border.all(
                      color: _isListening
                          ? AppTheme.primaryBlue.withValues(
                              alpha: 0.4 + (_waveController.value * 0.4),
                            )
                          : const Color(0xFF3B82F6).withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.25 * _waveController.value,
                              ),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _isListening ? AppTheme.primaryBlue : Colors.white,
                    size: 38,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isListening
              ? '🎙️ Listening... Speak count and item'
              : 'Microphone paused • Tap icon to speak',
          style: TextStyle(
            color: _isListening ? const Color(0xFF94A3B8) : AppTheme.primaryBlue,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Live Dynamic Sound Waveform
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            final soundBonus = (_soundLevel.clamp(0.0, 10.0) / 10.0) * 22.0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (index) {
                final double factor = (index % 2 == 0)
                    ? _waveController.value
                    : (1.0 - _waveController.value);
                final double height = 12.0 + (factor * 26.0) + (_isListening ? soundBonus : 0);
                return Container(
                  width: 5,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(
                      alpha: 0.5 + (factor * 0.5),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 18),

        // Live Transcript Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121418),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                _currentTranscript.isEmpty
                    ? 'Listening... Speak count and item'
                    : 'Recognized Words:',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentTranscript.isEmpty
                    ? (widget.initialSku != null
                        ? '"Twenty five"'
                        : '"Twelve bottles of tomato sauce"')
                    : '"$_currentTranscript"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _currentTranscript.isEmpty
                      ? const Color(0xFF64748B)
                      : Colors.white,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Manual Typed Entry Option
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF161A22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF282E3D)),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF64748B), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _manualTextController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Or type count (e.g. "25" or "15 cans")',
                    hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      _processTranscript(val.trim());
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppTheme.primaryBlue, size: 18),
                onPressed: () {
                  final text = _manualTextController.text.trim();
                  if (text.isNotEmpty) {
                    _processTranscript(text);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Simulated quick voice chips for emulators / tests
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (widget.initialSku != null)
              _buildSampleChip('25 units'),
            _buildSampleChip('12 bottles of Tomato Sauce'),
            _buildSampleChip('24 cans of Coca Cola'),
            _buildSampleChip('8 jars of Peanut Butter'),
          ],
        ),
        const SizedBox(height: 18),

        // Action: Done Speaking
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (_currentTranscript.isNotEmpty || _manualTextController.text.trim().isNotEmpty)
                ? () {
                    final text = _currentTranscript.isNotEmpty
                        ? _currentTranscript
                        : _manualTextController.text.trim();
                    if (text.isNotEmpty) {
                      _processTranscript(text);
                    }
                  }
                : null,
            icon: const Icon(Icons.check, size: 20),
            label: const Text('Done Speaking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              disabledBackgroundColor: const Color(0xFF2C3240),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSampleChip(String text) {
    return ActionChip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
      ),
      backgroundColor: const Color(0xFF161A22),
      side: const BorderSide(color: Color(0xFF2C3240)),
      onPressed: () {
        setState(() {
          _currentTranscript = text;
        });
        _stopListeningAndProcess();
      },
    );
  }

  Widget _buildParsingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryBlue),
          const SizedBox(height: 18),
          const Text(
            'Interpreting voice count with Groq AI...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '"$_currentTranscript"',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedView() {
    final result = _resolvedResult!;
    final confidencePct = (result.confidence * 100).toInt();
    final effectiveSku = widget.initialSku ?? result.sku;

    // Lookup product name if not returned in transcript
    String? resolvedName = result.productName;
    if (resolvedName == null && effectiveSku != null) {
      try {
        final prod = context.read<StockTakeBloc>().state.products.firstWhere(
              (p) => p.sku.toUpperCase() == effectiveSku.toUpperCase(),
            );
        resolvedName = prod.name;
      } catch (_) {}
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121418),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.statusMatch.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PARSED RESULT',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.statusMatch.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.statusMatch.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '$confidencePct% Confidence',
                      style: const TextStyle(
                        color: AppTheme.statusMatch,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Matched Product Name & SKU Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      resolvedName ??
                          (effectiveSku != null
                              ? 'Item $effectiveSku'
                              : 'Spoken Count Only'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (effectiveSku != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        effectiveSku,
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFF2C3240)),
              const SizedBox(height: 12),
              // Quantity Adjustment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recorded Quantity:',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      _buildStepperBtn(
                        icon: Icons.remove,
                        onPressed: () {
                          if (_editableQuantity > 0) {
                            setState(() {
                              _editableQuantity--;
                            });
                          }
                        },
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 44),
                        alignment: Alignment.center,
                        child: Text(
                          '$_editableQuantity',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _buildStepperBtn(
                        icon: Icons.add,
                        onPressed: () {
                          setState(() {
                            _editableQuantity++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _confirmAndApply,
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text(
                    'Confirm & Save Count',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.statusMatch,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _startListening,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF333B4A)),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.statusShortage.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.statusShortage.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.statusShortage,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _errorMessage ?? 'Speech recognition failed.',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null &&
            (_errorMessage!.contains('permission') ||
                _errorMessage!.contains('Settings'))) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => openAppSettings(),
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Open App Settings'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF333B4A)),
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Fallback simulated choices
        const Text(
          'Try one of these quick voice inputs:',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildSampleChip('12 bottles of Tomato Sauce'),
            _buildSampleChip('24 cans of Coca Cola'),
            _buildSampleChip('8 jars of Peanut Butter'),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _startListening,
            icon: const Icon(Icons.mic, size: 20),
            label: const Text('Try Speaking Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepperBtn({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: const Color(0xFF242A36),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
