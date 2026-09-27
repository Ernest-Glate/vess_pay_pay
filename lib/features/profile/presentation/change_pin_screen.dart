import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_input.dart';
import '../../../shared/widgets/success_notification.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _handleChangePin() {
    if (_newPinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PINs do not match')),
      );
      return;
    }

    SuccessNotification.show(
      context, 
      message: 'PIN Updated Successfully',
      timestamp: DateFormat('HH:mm a').format(DateTime.now()),
    );
    Future.delayed(const Duration(seconds: 1), () {
        if(mounted) Navigator.pop(context);
    });
  }

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
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'UPDATE SECURITY PIN',
                              style: TextStyle(color: AppColors.royalGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                            const SizedBox(height: 24),
                            FormInput(
                              label: 'CURRENT PIN',
                              controller: _currentPinController,
                              hint: '****',
                              obscureText: true,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 20),
                             const Divider(color: Colors.white10),
                             const SizedBox(height: 20),
                            FormInput(
                              label: 'NEW PIN',
                              controller: _newPinController,
                              hint: '****',
                              obscureText: true,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 20),
                            FormInput(
                              label: 'CONFIRM NEW PIN',
                              controller: _confirmPinController,
                              hint: '****',
                              obscureText: true,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 40),
                      
                      AppButton(
                        label: 'Update PIN',
                        onPress: _handleChangePin,
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(width: 16),
          Text(
            'CHANGE PIN',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.royalGold,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
