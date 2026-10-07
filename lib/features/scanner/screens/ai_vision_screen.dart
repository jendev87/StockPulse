import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/enums.dart';
import '../../../models/product.dart';
import '../../../services/ai_api_service.dart';
import '../../stock_take/bloc/stock_take_bloc.dart';
import '../../stock_take/widgets/voice_count_bottom_sheet.dart';

class AiVisionScreen extends StatefulWidget {
  final AiApiService? aiApiService;
  final ImagePicker? imagePicker;

  const AiVisionScreen({
    super.key,
    this.aiApiService,
    this.imagePicker,
  });

  @override
  State<AiVisionScreen> createState() => _AiVisionScreenState();
}

class _AiVisionScreenState extends State<AiVisionScreen>
    with SingleTickerProviderStateMixin {
  late final ImagePicker _picker;
  late final AiApiService _aiService;
  late final AnimationController _pulseController;

  XFile? _capturedImage;
  bool _isAnalyzing = false;
  AiVisionResult? _analysisResult;
  int _editableQuantity = 1;
  String? _errorMessage;
  bool _addToExisting = true;

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
    _aiService = widget.aiApiService ?? AiApiService.instance;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _capturedImage = photo;
          _isAnalyzing = true;
          _analysisResult = null;
          _errorMessage = null;
        });

        _analyzeCapturedImage(photo);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not access camera/photo: $e';
      });
    }
  }

  Future<void> _analyzeCapturedImage(XFile image) async {
    final state = context.read<StockTakeBloc>().state;
    final products = state.products;

    try {
      final rawResult = await _aiService.identifyProduct(
        imageFile: image,
        catalog: products,
      );

      if (mounted) {
        String canonicalSku = rawResult.sku;
        try {
          canonicalSku = products.firstWhere((p) => p.sku.toUpperCase() == rawResult.sku.toUpperCase()).sku;
        } catch (_) {}

        final result = AiVisionResult(
          sku: canonicalSku,
          name: rawResult.name,
          confidence: rawResult.confidence,
          detectedQuantity: rawResult.detectedQuantity,
        );

        final existingCount = state.counts[result.sku];
        final previousQty = existingCount?.physicalQty ?? 0;

        setState(() {
          _isAnalyzing = false;
          _analysisResult = result;
          _editableQuantity = result.detectedQuantity > 0
              ? result.detectedQuantity
              : 1;
          _addToExisting = previousQty > 0;
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Vision analysis failed: $e';
        });
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _analysisResult = null;
      _isAnalyzing = false;
      _errorMessage = null;
      _editableQuantity = 1;
      _addToExisting = true;
    });
  }

  void _confirmAndCount() {
    final result = _analysisResult;
    if (result == null) return;

    final existingCount =
        context.read<StockTakeBloc>().state.counts[result.sku];
    final previousQty = existingCount?.physicalQty ?? 0;
    final int finalQuantity = (previousQty > 0 && _addToExisting)
        ? (previousQty + _editableQuantity)
        : _editableQuantity;

    HapticFeedback.mediumImpact();
    context.read<StockTakeBloc>().add(
          UpdateCount(
            sku: result.sku,
            physicalQty: finalQuantity,
            method: IdentificationMethod.ai,
          ),
        );

    final String snackText = (previousQty > 0 && _addToExisting)
        ? 'Added $_editableQuantity units to ${result.name} (Total: $finalQuantity)'
        : 'Counted $_editableQuantity units of ${result.name} (AI Vision)';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.statusMatch,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                snackText,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/stock-take');
      }
    } catch (_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 20),
            SizedBox(width: 8),
            Text('AI Vision Auditor'),
          ],
        ),
        actions: [
          if (_analysisResult != null && !_isAnalyzing)
            IconButton(
              icon: const Icon(Icons.mic_rounded, color: AppTheme.primaryBlue),
              tooltip: 'Adjust Count by Voice',
              onPressed: () {
                VoiceCountBottomSheet.show(
                  context,
                  initialSku: _analysisResult!.sku,
                  onQuantitySelected: (spokenQty) {
                    setState(() {
                      _editableQuantity = spokenQty;
                    });
                    HapticFeedback.mediumImpact();
                  },
                );
              },
            ),
          if (_capturedImage != null && !_isAnalyzing)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Retake Photo',
              onPressed: _retakePhoto,
            ),
        ],
      ),
      body: SafeArea(
        child: _capturedImage == null
            ? _buildCapturePrompt()
            : _buildImagePreviewAndResults(),
      ),
    );
  }

  Widget _buildCapturePrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Viewfinder-styled box
          Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Corner targeting brackets
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.primaryBlue, width: 3),
                        left: BorderSide(color: AppTheme.primaryBlue, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.primaryBlue, width: 3),
                        right: BorderSide(color: AppTheme.primaryBlue, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.primaryBlue, width: 3),
                        left: BorderSide(color: AppTheme.primaryBlue, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.primaryBlue, width: 3),
                        right: BorderSide(color: AppTheme.primaryBlue, width: 3),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 40,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'AI Visual Item Detection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Point camera at the inventory shelf or item. Gemini Vision will identify SKU and count quantity automatically.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.statusShortage, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 36),
          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _captureImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text(
                'Capture with Camera',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _captureImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text(
                'Upload from Photo Library',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF333B4A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewAndResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo Preview with Spinner Overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isAnalyzing
                      ? AppTheme.primaryBlue.withValues(alpha: 0.7)
                      : const Color(0xFF2C3240),
                  width: _isAnalyzing ? 2 : 1,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (kIsWeb)
                    Image.network(
                      _capturedImage!.path,
                      fit: BoxFit.cover,
                    )
                  else
                    Image.file(
                      File(_capturedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  if (_isAnalyzing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.75),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.1),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primaryBlue,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: AppTheme.statusMatch,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Analyzing with Gemini Vision...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Matching SKU against locked warehouse catalog',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Analysis Output Card
          if (_analysisResult != null) ...[
            _buildMatchResultCard(_analysisResult!),
            const SizedBox(height: 20),
            _buildActionsRow(_analysisResult!),
          ] else if (!_isAnalyzing && _errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.statusShortage.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.statusShortage.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.statusShortage,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _retakePhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C3240),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchResultCard(AiVisionResult result) {
    final confidencePct = (result.confidence * 100).toInt();

    // Check catalog for visual description
    final state = context.read<StockTakeBloc>().state;
    final existingCount = state.counts[result.sku];
    final previousQty = existingCount?.physicalQty ?? 0;
    Product? matchedProduct;
    try {
      matchedProduct = state.products.firstWhere(
        (p) => p.sku.toUpperCase() == result.sku.toUpperCase(),
      );
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.statusMatch.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121418),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF333B4A)),
                          ),
                          child: Text(
                            'SKU: ${result.sku}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.statusMatch.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.statusMatch.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: AppTheme.statusMatch,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$confidencePct% Confidence',
                                style: const TextStyle(
                                  color: AppTheme.statusMatch,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (matchedProduct != null) ...[
            const SizedBox(height: 12),
            Text(
              matchedProduct.visualDescription,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFF2C3240)),
          const SizedBox(height: 16),
          // Detected Quantity Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DETECTED QUANTITY',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Adjust with +/- or mic',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              // Counter & Voice Input
              Row(
                children: [
                  _buildStepperButton(
                    icon: Icons.remove,
                    onPressed: () {
                      if (_editableQuantity > 1) {
                        setState(() {
                          _editableQuantity--;
                        });
                        HapticFeedback.selectionClick();
                      }
                    },
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$_editableQuantity',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _buildStepperButton(
                    icon: Icons.add,
                    onPressed: () {
                      setState(() {
                        _editableQuantity++;
                      });
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(width: 8),
                  // Mic Speak Button
                  Material(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        VoiceCountBottomSheet.show(
                          context,
                          initialSku: result.sku,
                          onQuantitySelected: (spokenQty) {
                            setState(() {
                              _editableQuantity = spokenQty;
                            });
                            HapticFeedback.mediumImpact();
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (previousQty > 0) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFF2C3240)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141820),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _addToExisting
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.6)
                      : const Color(0xFF333B4A),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded,
                                size: 15, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Previous Count: $previousQty units',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+$_editableQuantity in photo',
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _addToExisting = true);
                            HapticFeedback.selectionClick();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _addToExisting
                                  ? AppTheme.primaryBlue
                                  : const Color(0xFF1E222B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _addToExisting
                                    ? AppTheme.primaryBlue
                                    : const Color(0xFF333B4A),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '➕ Add (${previousQty + _editableQuantity} Total)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: _addToExisting
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _addToExisting = false);
                            HapticFeedback.selectionClick();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_addToExisting
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF1E222B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !_addToExisting
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF333B4A),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🔄 Replace ($_editableQuantity Total)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: !_addToExisting
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsRow(AiVisionResult result) {
    final state = context.read<StockTakeBloc>().state;
    final existingCount = state.counts[result.sku];
    final previousQty = existingCount?.physicalQty ?? 0;
    final effectiveTotal = (previousQty > 0 && _addToExisting)
        ? (previousQty + _editableQuantity)
        : _editableQuantity;

    final confirmLabel = (previousQty > 0 && _addToExisting)
        ? 'Add (+$_editableQuantity → $effectiveTotal Total)'
        : (previousQty > 0 && !_addToExisting)
            ? 'Replace ($effectiveTotal Total)'
            : 'Confirm & Count ($effectiveTotal)';

    final confirmIcon = (previousQty > 0 && _addToExisting)
        ? Icons.add_task_rounded
        : Icons.check_circle;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _confirmAndCount,
              style: ElevatedButton.styleFrom(
                backgroundColor: (previousQty > 0 && !_addToExisting)
                    ? const Color(0xFFEF4444)
                    : AppTheme.statusMatch,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(confirmIcon, size: 20),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      confirmLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _retakePhoto,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF333B4A)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Retake',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: const Color(0xFF242A36),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
