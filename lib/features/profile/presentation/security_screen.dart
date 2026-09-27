import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _mfaEnabled = true;
  bool _biometricEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildAuthenticationSection(),
                const SizedBox(height: 24),
                _buildTwoFactorSection(),
                const SizedBox(height: 24),
                _buildSessionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 20),
        Text(
          'SECURITY',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.royalGold,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ).animate().fadeIn().slideX(begin: -0.2, end: 0),
        const SizedBox(height: 8),
        const Text(
          'Protect your account with advanced authentication',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildAuthenticationSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AUTHENTICATION',
            style: TextStyle(color: AppColors.royalGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 24),
          _buildToggleRow(
            'Biometric Login',
            'Use Face ID or Fingerprint to unlock',
            _biometricEnabled,
            (val) => setState(() => _biometricEnabled = val),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Change Password', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                  Text('Update your login credentials', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.royalGold, size: 16),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTwoFactorSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TWO-FACTOR AUTH',
            style: TextStyle(color: AppColors.royalGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 24),
          _buildToggleRow(
            'Enable 2FA',
            'Requires OTP for every sensitive action',
            _mfaEnabled,
            (val) => setState(() => _mfaEnabled = val),
          ),
          if (_mfaEnabled) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backup Codes', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                    'Store these codes securely. Each can be used once.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  _buildCodeRow(['ABCD-1234', 'EFGH-5678']),
                  const SizedBox(height: 8),
                  _buildCodeRow(['IJKL-9012', 'MNOP-3456']),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Regenerate Codes',
                    onPress: () {},
                    variant: AppButtonVariant.outline,
                  ),
                ],
              ),
            ).animate().fadeIn(),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildSessionsSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE DEVICES',
                style: TextStyle(color: AppColors.royalGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              Text(
                '2 ACTIVE',
                style: TextStyle(color: AppColors.success.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSessionItem('iPhone 15 Pro', 'Accra, Ghana', 'Current Device', isCurrent: true),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          _buildSessionItem('MacBook Pro 14"', 'Lagos, Nigeria', '2 days ago'),
          const SizedBox(height: 24),
          AppButton(
            label: 'Sign out all other devices',
            onPress: () {},
            variant: AppButtonVariant.danger,
          ),
          const SizedBox(height: 32),
          const Text(
            'LOGIN HISTORY',
            style: TextStyle(color: AppColors.royalGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          _buildHistoryItem('Success', 'Feb 05, 11:42 AM', '192.168.1.1'),
          _buildHistoryItem('Success', 'Feb 04, 09:15 PM', '102.16.4.88'),
          _buildHistoryItem('Failed Attempt', 'Feb 03, 02:10 AM', '172.55.9.1', color: AppColors.error),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildToggleRow(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.royalGold,
          activeTrackColor: AppColors.royalGold.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildCodeRow(List<String> codes) {
    return Row(
      children: codes.map((code) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            code,
            style: const TextStyle(color: AppColors.royalGold, fontSize: 12, fontFamily: 'monospace'),
            textAlign: Center as TextAlign?,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildSessionItem(String device, String location, String status, {bool isCurrent = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCurrent ? AppColors.success.withValues(alpha: 0.1) : AppColors.royalGold.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCurrent ? Icons.smartphone_rounded : Icons.devices_rounded, 
            color: isCurrent ? AppColors.success : AppColors.royalGold, 
            size: 20
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
            Text('$location • $status', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryItem(String title, String time, String ip, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color ?? AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
              Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
          Text(ip, style: const TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
