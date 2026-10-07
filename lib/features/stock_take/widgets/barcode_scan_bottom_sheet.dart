import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';

class BarcodeScanBottomSheet extends StatefulWidget {
  final Product product;
  final ValueChanged<String>? onBarcodeMatched;
  final MobileScannerController? scannerController;

  const BarcodeScanBottomSheet({
    super.key,
    required this.product,
    this.onBarcodeMatched,
    this.scannerController,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    ValueChanged<String>? onBarcodeMatched,
    MobileScannerController? scannerController,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BarcodeScanBottomSheet(
        product: product,
        onBarcodeMatched: onBarcodeMatched,
        scannerController: scannerController,
      ),
    );
  }

  @override
  State<BarcodeScanBottomSheet> createState() => BarcodeScanBottomSheetState();
}

class BarcodeScanBottomSheetState extends State<BarcodeScanBottomSheet>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _animController;
  late Animation<double> _scanLineAnimation;

  bool _isProcessing = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isTorchOn = false;
  String? _feedbackMessage;
  bool _isMatchSuccess = false;
  int _scannedCountInSession = 0;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.scannerController ??
        MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
          torchEnabled: false,
        );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        if (mounted) {
          setState(() {
            _hasPermission = true;
            _isCheckingPermission = false;
          });
        }
      } else {
        final requested = await Permission.camera.request();
        if (mounted) {
          setState(() {
            _hasPermission = requested.isGranted;
            _isCheckingPermission = false;
          });
        }
      }
    } catch (_) {
      // In test / simulator environments where permission handler throws
      if (mounted) {
        setState(() {
          _hasPermission = true;
          _isCheckingPermission = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _animController.dispose();
    if (widget.scannerController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleBarcodeDetected(String rawCode) {
    if (_isProcessing) return;

    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return;

    final expected = widget.product.barcode?.trim() ?? '';
    final isMatch = trimmed.toLowerCase() == expected.toLowerCase();

    setState(() {
      _isProcessing = true;
    });

    if (isMatch) {
      HapticFeedback.mediumImpact();
      _scannedCountInSession++;
      setState(() {
        _isMatchSuccess = true;
        _feedbackMessage = 'Verified ${widget.product.name} (+1 unit added)';
      });

      widget.onBarcodeMatched?.call(trimmed);

      // Brief feedback delay before allowing next scan or returning
      _feedbackTimer?.cancel();
      _feedbackTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _feedbackMessage = null;
          });
        }
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isMatchSuccess = false;
        _feedbackMessage =
            'Barcode mismatch: "$trimmed"\nExpected: "$expected"';
      });

      _feedbackTimer?.cancel();
      _feedbackTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _feedbackMessage = null;
          });
        }
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null) {
      _handleBarcodeDetected(code);
    }
  }

  /// For programmatic testing and verification
  void testTriggerDetection(String code) {
    _handleBarcodeDetected(code);
  }

  @override
  Widget build(BuildContext context) {
    final expectedBarcode = widget.product.barcode ?? 'None';

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF333B4A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan Item Barcode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Expected: $expectedBarcode',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _isTorchOn ? 'Torch Off' : 'Torch On',
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: _isTorchOn ? Colors.amber : const Color(0xFF94A3B8),
                  ),
                  onPressed: () async {
                    try {
                      await _controller.toggleTorch();
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    } catch (_) {}
                  },
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF2C3240)),

          // Viewfinder / Permission area
          Expanded(
            child: _isCheckingPermission
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF10B981),
                    ),
                  )
                : !_hasPermission
                    ? _buildPermissionFallback()
                    : Stack(
                        children: [
                          // Camera Preview
                          ClipRRect(
                            child: MobileScanner(
                              controller: _controller,
                              onDetect: _onDetect,
                            ),
                          ),

                          // Target Viewfinder Reticle Overlay
                          _buildReticleOverlay(),

                          // Status or Feedback Banner
                          if (_feedbackMessage != null)
                            Positioned(
                              top: 20,
                              left: 20,
                              right: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _isMatchSuccess
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF991B1B),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isMatchSuccess
                                          ? Icons.check_circle_rounded
                                          : Icons.error_outline_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _feedbackMessage!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
          ),

          // Bottom Bar & Simulation Options
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF13171F),
                border: Border(
                  top: BorderSide(color: Color(0xFF2C3240)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _scannedCountInSession > 0
                              ? '+$_scannedCountInSession units verified'
                              : 'Ready to scan',
                          style: TextStyle(
                            color: _scannedCountInSession > 0
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _scannedCountInSession > 0
                          ? 'Done ($_scannedCountInSession)'
                          : 'Done',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReticleOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth * 0.78;
        const boxHeight = 160.0;
        final leftOffset = (constraints.maxWidth - boxWidth) / 2;
        final topOffset = (constraints.maxHeight - boxHeight) / 2;
        final cutoutRect =
            Rect.fromLTWH(leftOffset, topOffset, boxWidth, boxHeight);

        return Stack(
          children: [
            // Darkened surroundings with clean transparent cutout window
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScannerCutoutPainter(
                cutoutRect: cutoutRect,
                borderRadius: 12.0,
                overlayColor: Colors.black.withValues(alpha: 0.65),
              ),
            ),

            // Reticle Border & Moving laser
            Positioned(
              top: topOffset,
              left: leftOffset,
              child: Container(
                width: boxWidth,
                height: boxHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isMatchSuccess
                        ? const Color(0xFF10B981)
                        : const Color(0xFF34D399).withValues(alpha: 0.8),
                    width: 2,
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _scanLineAnimation,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          top: boxHeight * _scanLineAnimation.value,
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Hint label below reticle
            Positioned(
              top: topOffset + boxHeight + 16,
              left: 20,
              right: 20,
              child: const Center(
                child: Text(
                  'Align product barcode within frame to count',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionFallback() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          const Text(
            'Camera Access Needed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Grant camera permission to scan physical item barcodes, or use simulator fallback below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final status = await Permission.camera.request();
              if (mounted) {
                setState(() {
                  _hasPermission = status.isGranted;
                });
              }
            },
            icon: const Icon(Icons.lock_open),
            label: const Text('Grant Camera Access'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerCutoutPainter extends CustomPainter {
  final Rect cutoutRect;
  final double borderRadius;
  final Color overlayColor;

  const _ScannerCutoutPainter({
    required this.cutoutRect,
    required this.borderRadius,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          cutoutRect,
          Radius.circular(borderRadius),
        ),
      );

    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(finalPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerCutoutPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}

