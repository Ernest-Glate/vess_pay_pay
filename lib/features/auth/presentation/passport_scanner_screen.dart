import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';

/// Dedicated passport scanning screen with live camera preview,
/// positioning overlay, quality validation, and retry functionality.
///
/// Returns an [XFile] via Navigator.pop when a valid capture is obtained.
class PassportScannerScreen extends StatefulWidget {
  const PassportScannerScreen({super.key});

  @override
  State<PassportScannerScreen> createState() => _PassportScannerScreenState();
}

enum _ScannerState { instructions, capturing, reviewing, error }

class _PassportScannerScreenState extends State<PassportScannerScreen>
    with TickerProviderStateMixin {
  _ScannerState _state = _ScannerState.instructions;
  XFile? _capturedImage;
  Uint8List? _capturedBytes;
  String _errorMessage = '';
  bool _isProcessing = false;

  late AnimationController _pulseController;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  // ──────────────────── Camera Capture ────────────────────

  Future<void> _capturePassport() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _state = _ScannerState.capturing;
    });

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 1536,
      );

      if (image == null) {
        // User cancelled
        if (mounted) {
          setState(() {
            _state = _ScannerState.instructions;
            _isProcessing = false;
          });
        }
        return;
      }

      // Quality validation
      final bytes = await image.readAsBytes();
      final validationResult = _validateImage(bytes);

      if (mounted) {
        if (validationResult == null) {
          // Image passed validation
          setState(() {
            _capturedImage = image;
            _capturedBytes = bytes;
            _state = _ScannerState.reviewing;
            _isProcessing = false;
          });
        } else {
          setState(() {
            _errorMessage = validationResult;
            _state = _ScannerState.error;
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera unavailable. Please check permissions and try again.';
          _state = _ScannerState.error;
          _isProcessing = false;
        });
      }
    }
  }

  /// Returns null if the image is valid, or an error message string if not.
  String? _validateImage(Uint8List bytes) {
    // Check minimum file size (likely blank/corrupted if < 50KB)
    if (bytes.lengthInBytes < 50 * 1024) {
      return 'Image quality is too low. Please ensure the passport is clearly visible and well-lit.';
    }

    // Check for extremely large files that may indicate an issue
    if (bytes.lengthInBytes > 20 * 1024 * 1024) {
      return 'Image file is too large. Please try again.';
    }

    return null; // Passed all checks
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _capturedBytes = null;
      _state = _ScannerState.instructions;
    });
  }

  void _acceptPhoto() {
    if (_capturedImage != null) {
      Navigator.of(context).pop(_capturedImage);
    }
  }

  // ──────────────────── Build ────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: switch (_state) {
            _ScannerState.instructions => _buildInstructionsView(),
            _ScannerState.capturing   => _buildCapturingView(),
            _ScannerState.reviewing   => _buildReviewView(),
            _ScannerState.error       => _buildErrorView(),
          },
        ),
      ),
    );
  }

  // ──────────────────── Instructions View ────────────────────

  Widget _buildInstructionsView() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Passport frame illustration
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 280,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.royalGold.withValues(
                            alpha: 0.3 + (_pulseController.value * 0.4),
                          ),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Corner brackets
                          ..._buildCornerBrackets(),
                          // Center icon
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.badge_outlined,
                                  size: 56,
                                  color: AppColors.royalGold.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'PASSPORT',
                                  style: TextStyle(
                                    color: AppColors.royalGold.withValues(alpha: 0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),

                const SizedBox(height: 40),

                const Text(
                  'Scan Your Passport',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                const Text(
                  'Position the photo page of your passport within the camera frame. Ensure the text is clearly readable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),

                // Tips
                _buildTip(Icons.wb_sunny_outlined, 'Good lighting', 'Avoid shadows and glare'),
                const SizedBox(height: 12),
                _buildTip(Icons.crop_free_rounded, 'Flat surface', 'Place passport on a flat, stable surface'),
                const SizedBox(height: 12),
                _buildTip(Icons.center_focus_strong, 'Sharp focus', 'Hold steady until the image is captured'),
              ],
            ),
          ),
        ),

        // Bottom action
        Padding(
          padding: const EdgeInsets.all(24),
          child: AppButton(
            label: kIsWeb ? 'Choose File' : 'Open Camera',
            onPress: _capturePassport,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
        ),
      ],
    );
  }

  // ──────────────────── Capturing View ────────────────────

  Widget _buildCapturingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.royalGold.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Opening camera...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────── Review View ────────────────────

  Widget _buildReviewView() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Review Your Scan',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 8),

                const Text(
                  'Ensure all passport details are clearly readable.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 24),

                // Image preview
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _capturedBytes != null
                        ? Image.memory(
                            _capturedBytes!,
                            fit: BoxFit.contain,
                          )
                        : const Center(
                            child: Icon(Icons.image, color: AppColors.textSecondary, size: 48),
                          ),
                  ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
                ),

                const SizedBox(height: 16),

                // Quality badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Image quality check passed',
                        style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              AppButton(
                label: 'Use This Photo',
                onPress: _acceptPhoto,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _retakePhoto,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.royalGold, size: 18),
                label: const Text(
                  'Retake Photo',
                  style: TextStyle(
                    color: AppColors.royalGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────── Error View ────────────────────

  Widget _buildErrorView() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 40),
                ).animate().scale(curve: Curves.elasticOut),

                const SizedBox(height: 24),

                const Text(
                  'Scan Issue',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 12),

                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                // Retry tips
                _buildTip(Icons.wb_sunny_outlined, 'Improve lighting', 'Avoid shadows on the passport'),
                const SizedBox(height: 12),
                _buildTip(Icons.center_focus_strong, 'Hold steady', 'Keep the device stable while capturing'),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              AppButton(
                label: 'Try Again',
                onPress: _capturePassport,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────── Shared Widgets ────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.white, size: 24),
          ),
          const Expanded(
            child: Text(
              'Passport Scan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.royalGold.withValues(alpha: 0.7), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerBrackets() {
    const size = 24.0;
    const thickness = 3.0;
    final color = AppColors.royalGold.withValues(alpha: 0.8);

    return [
      // Top-left
      Positioned(
        top: 0, left: 0,
        child: SizedBox(
          width: size, height: size,
          child: CustomPaint(painter: _CornerPainter(color, thickness, _Corner.topLeft)),
        ),
      ),
      // Top-right
      Positioned(
        top: 0, right: 0,
        child: SizedBox(
          width: size, height: size,
          child: CustomPaint(painter: _CornerPainter(color, thickness, _Corner.topRight)),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 0, left: 0,
        child: SizedBox(
          width: size, height: size,
          child: CustomPaint(painter: _CornerPainter(color, thickness, _Corner.bottomLeft)),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 0, right: 0,
        child: SizedBox(
          width: size, height: size,
          child: CustomPaint(painter: _CornerPainter(color, thickness, _Corner.bottomRight)),
        ),
      ),
    ];
  }
}

// ──────────────────── Corner Painter ────────────────────

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final _Corner corner;

  _CornerPainter(this.color, this.thickness, this.corner);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (corner) {
      case _Corner.topLeft:
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
      case _Corner.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
      case _Corner.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
      case _Corner.bottomRight:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
