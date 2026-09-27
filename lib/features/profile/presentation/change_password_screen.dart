import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_input.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CHANGE PASSWORD',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.lock_outline_rounded, size: 60, color: AppColors.royalGold)
                    .animate().fadeIn().scale(duration: 600.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 40),
                
                GlassContainer(
                  borderRadius: 24,
                  child: Column(
                    children: [
                      FormInput(
                        label: 'Current Password',
                        hint: '••••••••',
                        controller: _currentController,
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_open_rounded),
                      ),
                      const SizedBox(height: 24),
                      FormInput(
                        label: 'New Password',
                        hint: '••••••••',
                        controller: _newController,
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                      ),
                      const SizedBox(height: 24),
                      FormInput(
                        label: 'Confirm New Password',
                        hint: '••••••••',
                        controller: _confirmController,
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: 32),
                
                AppButton(
                  label: 'Update Password',
                  onPress: () {},
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Password must be at least 8 characters and include a special character.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
