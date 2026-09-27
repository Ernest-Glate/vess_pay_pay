import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/auth_provider.dart';
import 'passport_scanner_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  PERSONA TYPES
// ══════════════════════════════════════════════════════════════════════════════

enum VerificationPersona {
  diasporaTraveler,
  remoteProfessional,
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final List<String> _steps = ['Why Verification', 'Identity Document', 'Liveness Check', 'Done'];

  VerificationPersona _persona = VerificationPersona.diasporaTraveler;
  XFile? _documentImage;
  XFile? _selfieImage;
  bool _isPickingImage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PERSONA HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  String get _documentLabel =>
      _persona == VerificationPersona.diasporaTraveler
          ? 'Passport'
          : 'National ID / Work Permit';

  String get _documentScanHint =>
      _persona == VerificationPersona.diasporaTraveler
          ? 'Capture the photo page of your international passport.'
          : 'Capture your national ID card or valid work permit.';

  List<String> get _documentHelperTips =>
      _persona == VerificationPersona.diasporaTraveler
          ? [
              'Avoid glare — tilt the document slightly',
              'Ensure all 4 edges are visible',
              'Place on a dark, flat surface for contrast',
            ]
          : [
              'Photograph the front of your ID card',
              'Ensure the photo and text are legible',
              'Avoid covering any part of the document',
            ];

  // ══════════════════════════════════════════════════════════════════════════
  //  NAVIGATION LOGIC
  // ══════════════════════════════════════════════════════════════════════════

  void _nextStep() async {
    // Step 1 (Document): Open scanner if no image captured yet
    if (_currentStep == 1 && _documentImage == null) {
      await _openDocumentScanner();
      return;
    }

    // Step 2 (Selfie): Open front camera if no selfie captured yet
    if (_currentStep == 2 && _selfieImage == null) {
      await _openSelfieCamera();
      return;
    }

    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: 500.ms,
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _completeOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: 500.ms,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentStep = index);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CAMERA / SCANNER
  // ══════════════════════════════════════════════════════════════════════════

  /// Opens the dedicated passport scanner screen (mobile) or file picker (web).
  Future<void> _openDocumentScanner() async {
    if (kIsWeb) {
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
          maxWidth: 2048,
        );
        if (image != null && mounted) {
          setState(() {
            _documentImage = image;
          });
        }
      } catch (e) {
        debugPrint('File picker failed for document: $e');
      }
      return;
    }

    // On mobile, use dedicated scanner screen
    final result = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(
        builder: (_) => const PassportScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _documentImage = result;
      });
    }
  }

  /// Upload document from device gallery.
  Future<void> _uploadDocumentFromGallery() async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
      );
      if (image != null && mounted) {
        setState(() {
          _documentImage = image;
        });
      }
    } catch (e) {
      debugPrint('Gallery picker failed: $e');
    } finally {
      _isPickingImage = false;
    }
  }

  /// Opens the front camera for selfie capture (mobile) or file picker (web).
  Future<void> _openSelfieCamera() async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
      final picker = ImagePicker();
      if (kIsWeb) {
        // On web, go directly to file picker
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
        );
        if (image != null && mounted) {
          setState(() {
            _selfieImage = image;
          });
        }
      } else {
        // On mobile, try camera first
        final image = await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          imageQuality: 85,
          maxWidth: 1920,
        );
        if (image != null && mounted) {
          setState(() {
            _selfieImage = image;
          });
        }
      }
    } catch (e) {
      // Fallback to gallery if camera fails
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
        );
        if (image != null && mounted) {
          setState(() {
            _selfieImage = image;
          });
        }
      } catch (_) {
        debugPrint('Camera and gallery unavailable for selfie.');
      }
    } finally {
      _isPickingImage = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ONBOARDING COMPLETION
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _completeOnboarding() async {
    // Refresh user profile from server after KYC submission
    await ref.read(authProvider.notifier).checkCurrentUser();
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      context.go('/dashboard');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Progress Tracking Bar ──────────────────────────
              _buildProgressBar(),

              _buildHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildWhyVerificationStep(),
                    _buildDocumentStep(),
                    _buildSelfieStep(),
                    _buildCompletionStep(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PROGRESS BAR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildProgressBar() {
    // Map internal steps to the user-facing 3-step journey
    // Step 0 (Why Verify) = Pre-step, Steps 1-3 = Steps 1-3
    final int userStep;
    final String stepLabel;

    switch (_currentStep) {
      case 0:
        userStep = 1;
        stepLabel = 'Getting Started';
        break;
      case 1:
        userStep = 2;
        stepLabel = 'Identity Verification';
        break;
      case 2:
        userStep = 2;
        stepLabel = 'Biometric Verification';
        break;
      case 3:
        userStep = 3;
        stepLabel = 'Complete';
        break;
      default:
        userStep = 1;
        stepLabel = '';
    }

    final progress = (_currentStep + 1) / _steps.length;

    return Column(
      children: [
        // Slim progress bar
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              height: 3,
              width: double.infinity,
              color: AppColors.white.withValues(alpha: 0.05),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.royalGold.withValues(alpha: 0.6),
                        AppColors.royalGold,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          },
        ),
        // Step label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.royalGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Step $userStep of 3',
                  style: const TextStyle(
                    color: AppColors.royalGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                stepLabel,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HEADER (back button + circular indicator)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    if (_currentStep == 0 || _currentStep == _steps.length - 1) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _prevStep,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: (_currentStep + 1) / _steps.length,
                  strokeWidth: 3,
                  backgroundColor: AppColors.white.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.royalGold),
                ),
              ),
              Text(
                '${_currentStep + 1}/${_steps.length}',
                style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STEP 0: WHY VERIFICATION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWhyVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ── Persona Selection Toggle ─────────────────────────────
          _buildPersonaToggle(),

          const SizedBox(height: 28),

          GlassContainer(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Icon(Icons.security_rounded, color: AppColors.royalGold, size: 48),
                const SizedBox(height: 24),
                const Text(
                  'Why verify identity?',
                  style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  _persona == VerificationPersona.diasporaTraveler
                      ? '\u201CWe verify identity once to keep your money safe across borders.\u201D'
                      : '\u201CVerification unlocks payroll receiving and multi-country transfers.\u201D',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.royalGold,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _persona == VerificationPersona.diasporaTraveler
                      ? 'This one-time check complies with global financial standards and anti-fraud regulations, ensuring your funds are protected 24/7.'
                      : 'Employers require verified wallets to deposit payroll. This quick check enables your account for corporate transfers instantly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 20),
                // Compliance note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: AppColors.royalGold.withValues(alpha: 0.6), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Verified via Bank of Ghana registry database',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideX(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PERSONA SELECTION TOGGLE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPersonaToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _buildPersonaOption(
            label: 'Diaspora / Traveler',
            icon: Icons.flight_takeoff_rounded,
            persona: VerificationPersona.diasporaTraveler,
          ),
          _buildPersonaOption(
            label: 'Remote Professional',
            icon: Icons.work_outline_rounded,
            persona: VerificationPersona.remoteProfessional,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildPersonaOption({
    required String label,
    required IconData icon,
    required VerificationPersona persona,
  }) {
    final isSelected = _persona == persona;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _persona = persona),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.royalGold.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.royalGold.withValues(alpha: 0.4) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.royalGold : AppColors.textSecondary.withValues(alpha: 0.5),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STEP 1: IDENTITY DOCUMENT SCAN
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDocumentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_documentLabel Scan',
            style: const TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            _documentScanHint,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 28),

          if (_documentImage != null) ...[
            // ── Captured image preview ──────────────────────────
            FutureBuilder<List<int>>(
              future: _documentImage!.readAsBytes(),
              builder: (context, snapshot) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.5), width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: snapshot.hasData
                      ? Image.memory(
                          snapshot.data as dynamic,
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: AppColors.royalGold),
                        ),
                );
              },
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$_documentLabel captured successfully.',
                      style: const TextStyle(color: AppColors.success, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _openDocumentScanner,
                    child: const Text(
                      'Retake',
                      style: TextStyle(color: AppColors.royalGold, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ] else ...[
            // ── Interactive Scanning Frame ──────────────────────
            _buildScanFrame(),
            const SizedBox(height: 20),

            // ── Dual Action Buttons ────────────────────────────
            _buildDualCaptureActions(),
            const SizedBox(height: 24),

            // ── Helper Tips ────────────────────────────────────
            ..._documentHelperTips.asMap().entries.map((entry) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildHelperTip(entry.value, delay: (entry.key * 100 + 300)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Rounded scanning frame box with visual guide corners.
  Widget _buildScanFrame() {
    return GestureDetector(
      onTap: _openDocumentScanner,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.royalGold.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Corner guide marks
            _buildCornerMark(Alignment.topLeft),
            _buildCornerMark(Alignment.topRight),
            _buildCornerMark(Alignment.bottomLeft),
            _buildCornerMark(Alignment.bottomRight),

            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.royalGold.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.document_scanner_outlined, color: AppColors.royalGold, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Position your $_documentLabel here',
                    style: const TextStyle(
                      color: AppColors.royalGold,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Align the document within the corners',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  /// Corner guide marks for the scanning frame.
  Widget _buildCornerMark(Alignment alignment) {
    final isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Positioned(
      top: isTop ? 12 : null,
      bottom: !isTop ? 12 : null,
      left: isLeft ? 12 : null,
      right: !isLeft ? 12 : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: AppColors.royalGold, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: AppColors.royalGold, width: 3)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: AppColors.royalGold, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: AppColors.royalGold, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Dual capture buttons: Take Live Photo + Upload Image File.
  Widget _buildDualCaptureActions() {
    return Row(
      children: [
        Expanded(
          child: _buildCaptureButton(
            icon: Icons.camera_alt_rounded,
            label: 'Take Live Photo',
            onTap: _openDocumentScanner,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCaptureButton(
            icon: Icons.upload_file_rounded,
            label: 'Upload Image File',
            onTap: _uploadDocumentFromGallery,
            isPrimary: false,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildCaptureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.royalGold.withValues(alpha: 0.12)
              : AppColors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? AppColors.royalGold.withValues(alpha: 0.35)
                : AppColors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isPrimary ? AppColors.royalGold : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPrimary ? AppColors.royalGold : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Individual helper tip row.
  Widget _buildHelperTip(String text, {int delay = 0}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: AppColors.royalGold.withValues(alpha: 0.5), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.white.withValues(alpha: 0.5), fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STEP 2: SELFIE / LIVENESS CHECK
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSelfieStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Liveness Check',
            style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          const Text(
            'Take a live selfie to match against your identity document via the Bank of Ghana biometric registry.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),

          // ── Circular Selfie Module ─────────────────────────────
          Center(
            child: _buildLivenessCircle(),
          ),

          const SizedBox(height: 32),

          if (_selfieImage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Selfie captured — biometric match pending.', style: TextStyle(color: AppColors.success, fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: _openSelfieCamera,
                    child: const Text('Retake', style: TextStyle(color: AppColors.royalGold, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms)
          else ...[
            _buildHelperTip('Position your head within the circle and look directly at the camera.', delay: 300),
            const SizedBox(height: 8),
            _buildHelperTip('Ensure adequate lighting on your face — avoid backlighting.', delay: 400),
          ],

          const SizedBox(height: 24),

          // ── Biometric Verification Status ──────────────────────
          _buildBiometricVerificationNote(),
        ],
      ),
    );
  }

  /// Circular selfie matching module with pulsing ring.
  Widget _buildLivenessCircle() {
    return GestureDetector(
      onTap: _openSelfieCamera,
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing ring (only when awaiting capture)
            if (_selfieImage == null)
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.royalGold.withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1500.ms)
                .fadeOut(begin: 1, duration: 1500.ms),

            // Main circle
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: _selfieImage != null
                    ? AppColors.success.withValues(alpha: 0.05)
                    : AppColors.white.withValues(alpha: 0.03),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selfieImage != null
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.royalGold.withValues(alpha: 0.25),
                  width: 3,
                ),
              ),
              child: _selfieImage != null
                  ? FutureBuilder<List<int>>(
                      future: _selfieImage!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ClipOval(
                            child: Image.memory(
                              snapshot.data as dynamic,
                              fit: BoxFit.cover,
                              width: 220,
                              height: 220,
                            ),
                          );
                        }
                        return const Center(child: CircularProgressIndicator(color: AppColors.royalGold));
                      },
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.royalGold.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.face_retouching_natural_rounded, color: AppColors.royalGold, size: 32),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Take Selfie',
                          style: TextStyle(
                            color: AppColors.royalGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          kIsWeb ? 'Upload a selfie photo' : 'Tap to open camera',
                          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 200.ms, curve: Curves.elasticOut);
  }

  /// Biometric verification status note.
  Widget _buildBiometricVerificationNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.royalGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.fingerprint_rounded, color: AppColors.royalGold.withValues(alpha: 0.6), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Automated Biometric Verification',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your selfie is matched against your document via the Bank of Ghana registry for fraud prevention.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STEP 3: COMPLETION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCompletionStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.royalGold.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat()).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 2.seconds,
              ).fadeOut(),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.royalGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.black, size: 50),
              ),
            ],
          ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
          const SizedBox(height: 40),
          Text(
            'Verification Done!',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 16),
          Text(
            _persona == VerificationPersona.diasporaTraveler
                ? "Your wallet is now unlocked and ready for international transfers across 33 African nations."
                : "Your professional wallet is verified and ready to receive corporate payroll and cross-border payments.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }



  // ══════════════════════════════════════════════════════════════════════════
  //  FOOTER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFooter() {
    String buttonLabel;
    if (_currentStep == _steps.length - 1) {
      buttonLabel = 'Go to Wallet';
    } else if (_currentStep == 1 && _documentImage == null) {
      buttonLabel = 'Continue';
    } else if (_currentStep == 2 && _selfieImage == null) {
      buttonLabel = 'Continue';
    } else {
      buttonLabel = 'Continue';
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: AppButton(
        label: buttonLabel,
        onPress: _nextStep,
      ),
    );
  }
}
