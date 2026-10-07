import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/inventory_repository.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _animController;
  late Animation<double> _scanLineAnimation;

  bool _isProcessing = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  String? _unrecognizedBarcode;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
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
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    final repository = context.read<InventoryRepository>();
    final product = await repository.getProductByBarcode(barcode);

    if (!mounted) return;

    if (product != null) {
      // Case 1: Match Found
      HapticFeedback.mediumImpact();
      context.pushReplacement('/count/${product.sku}');
    } else {
      // Case 2: Unknown Barcode
      HapticFeedback.heavyImpact();
      setState(() {
        _unrecognizedBarcode = barcode;
      });

      // Auto re-enable scanning after 1.5 seconds
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _unrecognizedBarcode = null;
            _isProcessing = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionDeniedView();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Viewfinder
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // 2. Translucent Cutout Overlay & Reticle
          _buildReticleOverlay(),

          // 3. Top Control Bar
          _buildTopBar(),

          // 4. Bottom Controls & Feedback
          _buildBottomOverlay(),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Camera Permission'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2C3240)),
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                color: AppTheme.statusShortage,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera Access Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'StockPulse needs camera access to instantly recognize and count physical inventory barcodes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final status = await Permission.camera.request();
                  if (status.isPermanentlyDenied) {
                    await openAppSettings();
                  } else if (status.isGranted) {
                    setState(() {
                      _hasPermission = true;
                    });
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Grant Camera Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Cancel & Enter Manually',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReticleOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = (constraints.maxWidth * 0.72).clamp(240.0, 320.0);
        final topOffset = (constraints.maxHeight - boxSize) / 2.4;
        final leftOffset = (constraints.maxWidth - boxSize) / 2;
        final cutoutRect =
            Rect.fromLTWH(leftOffset, topOffset, boxSize, boxSize);

        return Stack(
          children: [
            // Darkened surroundings with clean transparent cutout window
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScannerCutoutPainter(
                cutoutRect: cutoutRect,
                borderRadius: 16.0,
                overlayColor: Colors.black.withValues(alpha: 0.65),
              ),
            ),

            // Reticle Frame with corner brackets
            Positioned(
              top: topOffset,
              left: (constraints.maxWidth - boxSize) / 2,
              child: SizedBox(
                width: boxSize,
                height: boxSize,
                child: Stack(
                  children: [
                    // Corner Brackets
                    CustomPaint(
                      size: Size(boxSize, boxSize),
                      painter: _ReticlePainter(
                        borderColor: _unrecognizedBarcode != null
                            ? AppTheme.statusShortage
                            : (_isProcessing
                                ? AppTheme.statusMatch
                                : AppTheme.primaryBlue),
                      ),
                    ),

                    // Animated Scanning Laser Line
                    if (_unrecognizedBarcode == null)
                      AnimatedBuilder(
                        animation: _scanLineAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: boxSize * _scanLineAnimation.value,
                            left: 14,
                            right: 14,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 1.5,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            _buildCircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: 'Back',
              onPressed: () => context.pop(),
            ),

            const Text(
              'Barcode Scanner',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),

            // Flash & Camera Toggle Controls
            Row(
              children: [
                _buildCircleIconButton(
                  icon: _isTorchOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  iconColor: _isTorchOn ? AppTheme.statusSurplus : Colors.white,
                  tooltip: 'Flash',
                  onPressed: () async {
                    await _controller.toggleTorch();
                    setState(() {
                      _isTorchOn = !_isTorchOn;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildCircleIconButton(
                  icon: Icons.flip_camera_ios_rounded,
                  tooltip: 'Flip Camera',
                  onPressed: () => _controller.switchCamera(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color iconColor = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E222B).withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF333B4A)),
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Unrecognized Barcode Alert Banner
              if (_unrecognizedBarcode != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.statusShortage.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Barcode "$_unrecognizedBarcode" not recognized in catalog.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _unrecognizedBarcode = null;
                            _isProcessing = false;
                          });
                        },
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Bottom Target Guidance Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2C3240)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.crop_free_rounded,
                          color: AppTheme.primaryBlue,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Align barcode inside target frame',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.pushReplacement('/stock-take');
                        },
                        icon: const Icon(
                          Icons.keyboard_outlined,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        label: const Text(
                          'Enter SKU Manually',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for industrial HUD corner brackets
class _ReticlePainter extends CustomPainter {
  final Color borderColor;

  _ReticlePainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 28.0;
    const strokeWidth = 3.5;

    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top Left
    canvas.drawLine(const Offset(0, cornerLength), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);

    // Top Right
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) {
    return oldDelegate.borderColor != borderColor;
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

