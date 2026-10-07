import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/enums.dart';
import '../../../models/product.dart';
import '../../../services/ai_api_service.dart';
import '../bloc/stock_take_bloc.dart';
import '../widgets/barcode_scan_bottom_sheet.dart';
import '../widgets/voice_count_bottom_sheet.dart';

class CountScreen extends StatefulWidget {
  final String sku;
  final ImagePicker? imagePicker;
  final AiApiService? aiApiService;

  const CountScreen({
    super.key,
    required this.sku,
    this.imagePicker,
    this.aiApiService,
  });

  @override
  State<CountScreen> createState() => _CountScreenState();
}

class _CountScreenState extends State<CountScreen> {
  late TextEditingController _controller;
  late final ImagePicker _picker;
  late final AiApiService _aiService;

  int _currentQty = 0;
  IdentificationMethod _currentMethod = IdentificationMethod.manual;
  bool _isAnalyzingVision = false;
  String? _statusBanner;

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
    _aiService = widget.aiApiService ?? AiApiService.instance;

    final state = context.read<StockTakeBloc>().state;
    final existingCount = state.counts[widget.sku];

    if (existingCount != null) {
      _currentQty = existingCount.physicalQty;
      _currentMethod = existingCount.method;
    } else {
      // Uncounted items start fresh at 0
      _currentQty = 0;
    }

    _controller = TextEditingController(text: '$_currentQty');
  }

  Product? _findProduct(StockTakeState state) {
    try {
      return state.products.firstWhere(
        (p) => p.sku.toUpperCase() == widget.sku.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateQty(int newQty) {
    final sanitized = newQty < 0 ? 0 : newQty;
    setState(() {
      _currentQty = sanitized;
      _controller.value = TextEditingValue(
        text: '$sanitized',
        selection: TextSelection.collapsed(offset: '$sanitized'.length),
      );
    });
    HapticFeedback.selectionClick();
  }

  void _increment(int delta) {
    _updateQty(_currentQty + delta);
  }

  void _decrement() {
    if (_currentQty > 0) {
      _updateQty(_currentQty - 1);
    }
  }

  void _onManualInput(String text) {
    if (text.isEmpty) {
      setState(() {
        _currentQty = 0;
      });
      return;
    }
    final parsed = int.tryParse(text);
    if (parsed != null && parsed >= 0) {
      setState(() {
        _currentQty = parsed;
      });
    }
  }

  Future<void> _takePictureWithAiVision(Product product) async {
    final allProducts = context.read<StockTakeBloc>().state.products;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF333B4A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'AI Visual Shelf Count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Capture shelf units for ${product.name}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
                ),
                title: const Text('Take Photo with Camera',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Snap the physical containers on shelf',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const Divider(color: Color(0xFF2C3240)),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF6366F1)),
                ),
                title: const Text('Choose from Photo Gallery',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Select a shelf image from device',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _isAnalyzingVision = true;
          _statusBanner = 'AI is counting ${product.name} with Groq Vision...';
        });

        final result = await _aiService.identifyProduct(
          imageFile: photo,
          catalog: allProducts.isNotEmpty ? allProducts : [product],
        );

        if (mounted) {
          final detected = result.detectedQuantity > 0 ? result.detectedQuantity : 1;

          if (result.sku.isNotEmpty &&
              result.sku.toUpperCase() != product.sku.toUpperCase()) {
            // Mismatch: The photographed item does not match the product currently being counted
            setState(() {
              _isAnalyzingVision = false;
              _statusBanner =
                  '⚠️ Photo mismatch: Detected ${result.name} (${result.sku}), not ${product.name}.';
            });
            HapticFeedback.vibrate();
            _showProductMismatchDialog(result, product, detected);
          } else {
            // Match: Apply detected units
            if (_currentQty > 0) {
              _showAddOrReplaceDialog(detected, product);
            } else {
              _updateQty(detected);
              setState(() {
                _isAnalyzingVision = false;
                _currentMethod = IdentificationMethod.ai;
                _statusBanner =
                    '📸 Groq Vision detected $detected units (${(result.confidence * 100).toInt()}% confidence)';
              });
              HapticFeedback.heavyImpact();
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzingVision = false;
          _statusBanner = 'Vision scan error: $e';
        });
      }
    }
  }

  void _showAddOrReplaceDialog(int detected, Product product) {
    setState(() {
      _isAnalyzingVision = false;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF333B4A)),
        ),
        title: const Row(
          children: [
            Icon(Icons.add_task_rounded, color: AppTheme.primaryBlue, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Accumulate Shelf Count?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI detected $detected units of ${product.name}. You previously counted $_currentQty units on shelf.',
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161A22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2C3240)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_currentQty (prev) + $detected (new)',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '= ${_currentQty + detected} Total',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _updateQty(detected);
              setState(() {
                _currentMethod = IdentificationMethod.ai;
                _statusBanner =
                    '📸 Count replaced with $detected units (${product.name})';
              });
              HapticFeedback.mediumImpact();
            },
            child: const Text(
              'Replace Count',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              final newTotal = _currentQty + detected;
              _updateQty(newTotal);
              setState(() {
                _currentMethod = IdentificationMethod.ai;
                _statusBanner =
                    '📸 Added $detected units (New total: $newTotal for ${product.name})';
              });
              HapticFeedback.heavyImpact();
            },
            child: Text('Add (${_currentQty + detected} Total)'),
          ),
        ],
      ),
    );
  }

  void _showProductMismatchDialog(
    AiVisionResult detectedResult,
    Product currentProduct,
    int detectedQty,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF333B4A)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.statusShortage, size: 24),
            SizedBox(width: 10),
            Text(
              'Item Mismatch Detected',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Groq Vision detected ${detectedResult.name} (${detectedResult.sku}) in the photo with $detectedQty units visible.',
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF161A22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2C3240)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Screen: ${currentProduct.name} (${currentProduct.sku})',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Detected in Photo: ${detectedResult.name} ($detectedQty units)',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Would you like to switch to counting the detected item instead?',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Stay Here',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pushReplacement('/count/${detectedResult.sku}');
            },
            child: Text('Switch to ${detectedResult.sku}'),
          ),
        ],
      ),
    );
  }

  void _startVoiceCount() {
    VoiceCountBottomSheet.show(
      context,
      initialSku: widget.sku,
      onQuantitySelected: (spokenQty) {
        _updateQty(spokenQty);
        setState(() {
          _currentMethod = IdentificationMethod.voice;
          _statusBanner = '🎙️ Voice count updated to $spokenQty units';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.statusMatch,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Row(
              children: [
                const Icon(Icons.mic, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Voice count: $spokenQty units of ${widget.sku}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startBarcodeScan(Product product) {
    BarcodeScanBottomSheet.show(
      context,
      product: product,
      onBarcodeMatched: (scannedBarcode) {
        _increment(1);
        setState(() {
          _currentMethod = IdentificationMethod.barcode;
          _statusBanner = '🏷️ Barcode verified: $scannedBarcode (+1 unit added)';
        });
      },
    );
  }

  void _saveCount() {
    HapticFeedback.mediumImpact();
    context.read<StockTakeBloc>().add(
          UpdateCount(
            sku: widget.sku,
            physicalQty: _currentQty,
            method: _currentMethod,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.statusMatch,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        content: Row(
          children: [
            const Icon(Icons.check, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Saved: $_currentQty units for ${widget.sku}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockTakeBloc, StockTakeState>(
      builder: (context, state) {
        final product = _findProduct(state);

        if (product == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(title: const Text('Count Item')),
            body: Center(
              child: Text(
                'Product ${widget.sku} not found.',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final variance = _currentQty - product.systemQty;

        final existingCount = state.counts[widget.sku];
        final hasExistingCount = existingCount != null;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(
              'Count: ${product.sku}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            actions: [
              if (product.hasBarcode)
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF10B981)),
                  tooltip: 'Scan Barcode',
                  onPressed: () => _startBarcodeScan(product),
                ),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF818CF8)),
                tooltip: 'Take Picture to Count',
                onPressed: () => _takePictureWithAiVision(product),
              ),
              IconButton(
                icon: const Icon(Icons.mic_rounded, color: AppTheme.primaryBlue),
                tooltip: 'Speak Count',
                onPressed: _startVoiceCount,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Info Card
                _buildProductDetailsCard(product, variance, hasExistingCount),
                const SizedBox(height: 18),

                // Visual Description Box
                _buildVisualDescriptionBox(product),
                const SizedBox(height: 18),

                // Barcode Scan Card (For items with barcode)
                if (product.hasBarcode) ...[
                  _buildBarcodeScanCard(product),
                  const SizedBox(height: 18),
                ],

                // Multimodal AI Action Banner & Buttons
                _buildAiCountButtonsCard(product),
                const SizedBox(height: 22),

                // Large Quantity Adjuster
                _buildQuantityAdjuster(product),
                const SizedBox(height: 18),

                // Quick Increment Chips
                _buildQuickChips(product),
                const SizedBox(height: 36),

                // Save Count Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saveCount,
                    icon: const Icon(Icons.check_circle_outline, size: 22),
                    label: const Text(
                      'Save Count',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductDetailsCard(
    Product product,
    int variance,
    bool hasExistingCount,
  ) {
    Color varianceColor = const Color(0xFF94A3B8);
    String varianceText = 'Not Counted';

    if (hasExistingCount || _currentQty > 0) {
      if (variance < 0) {
        varianceColor = AppTheme.statusShortage;
        varianceText = '$variance units Shortage';
      } else if (variance > 0) {
        varianceColor = AppTheme.statusSurplus;
        varianceText = '+$variance units Surplus';
      } else {
        varianceColor = AppTheme.statusMatch;
        varianceText = 'Matches System';
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C3240)),
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
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'SKU: ${product.sku}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (product.barcode != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•  Barcode: ${product.barcode}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFF2C3240)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SYSTEM EXPECTED',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.systemQty} units',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: varianceColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: varianceColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  varianceText,
                  style: TextStyle(
                    color: varianceColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualDescriptionBox(Product product) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF282E3D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.visibility_outlined,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visual Verification Description:',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.visualDescription,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeScanCard(Product product) {
    final isBarcodeVerified = _currentMethod == IdentificationMethod.barcode;
    final barcodeText = product.barcode ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBarcodeVerified
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : const Color(0xFF10B981).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFF10B981),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'BARCODE VERIFICATION',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.barcode_reader,
                      color: Color(0xFF34D399),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      barcodeText,
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _startBarcodeScan(product),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF34D399),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scan Barcode (+1)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Scan $barcodeText to verify & count',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF34D399),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isBarcodeVerified) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF34D399),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Matched & verified against barcode $barcodeText',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiCountButtonsCard(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C3240)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Color(0xFF818CF8),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'AI MULTIMODAL COUNTING',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Take Picture / AI Visual Count Button
              Expanded(
                child: Material(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _isAnalyzingVision
                        ? null
                        : () => _takePictureWithAiVision(product),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            color: Color(0xFF818CF8),
                            size: 26,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'AI Camera',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Snap shelf photo',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // AI Voice Count Button
              Expanded(
                child: Material(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _startVoiceCount,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic_rounded,
                            color: AppTheme.primaryBlue,
                            size: 26,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'AI Voice',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Speak count intent',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isAnalyzingVision) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF161A22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF818CF8),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Analyzing shelf units with Groq Vision AI...',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_statusBanner != null && !_isAnalyzingVision) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.statusMatch.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.statusMatch.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.statusMatch,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusBanner!,
                      style: const TextStyle(
                        color: AppTheme.statusMatch,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityAdjuster(Product product) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C3240)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PHYSICAL QUANTITY ON SHELF',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              if (_currentMethod != IdentificationMethod.manual) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _currentMethod == IdentificationMethod.ai
                        ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                        : _currentMethod == IdentificationMethod.barcode
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : AppTheme.primaryBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _currentMethod == IdentificationMethod.ai
                        ? 'AI VISION'
                        : _currentMethod == IdentificationMethod.barcode
                            ? 'BARCODE'
                            : 'VOICE',
                    style: TextStyle(
                      color: _currentMethod == IdentificationMethod.ai
                          ? const Color(0xFF818CF8)
                          : _currentMethod == IdentificationMethod.barcode
                              ? const Color(0xFF34D399)
                              : AppTheme.primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrement Button
              _buildAdjustButton(
                icon: Icons.remove,
                onPressed: _decrement,
              ),
              const SizedBox(width: 10),

              // Large Numeric Input Field
              Container(
                width: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF121418),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: _onManualInput,
                ),
              ),
              const SizedBox(width: 10),

              // Increment Button
              _buildAdjustButton(
                icon: Icons.add,
                onPressed: () => _increment(1),
              ),
              const SizedBox(width: 10),

              // Camera Icon Button
              Material(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _isAnalyzingVision
                      ? null
                      : () => _takePictureWithAiVision(product),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF818CF8),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Voice Speak Mic Button
              Material(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _startVoiceCount,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: AppTheme.primaryBlue,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: const Color(0xFF242A36),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildQuickChips(Product product) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(label: '+1', onPressed: () => _increment(1)),
        _buildChip(label: '+5', onPressed: () => _increment(5)),
        _buildChip(label: '+10', onPressed: () => _increment(10)),
        _buildChip(
          label: 'Expected (${product.systemQty})',
          isHighlight: true,
          onPressed: () => _updateQty(product.systemQty),
        ),
        _buildChip(
          label: 'Reset (0)',
          isReset: true,
          onPressed: () => _updateQty(0),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required VoidCallback onPressed,
    bool isReset = false,
    bool isHighlight = false,
  }) {
    Color textColor = Colors.white;
    Color bgColor = const Color(0xFF1E222B);
    Color borderColor = const Color(0xFF333B4A);

    if (isReset) {
      textColor = const Color(0xFF94A3B8);
    } else if (isHighlight) {
      textColor = AppTheme.statusMatch;
      bgColor = AppTheme.statusMatch.withValues(alpha: 0.12);
      borderColor = AppTheme.statusMatch.withValues(alpha: 0.35);
    }

    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      backgroundColor: bgColor,
      side: BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: onPressed,
    );
  }
}

