import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_input.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameController = TextEditingController(text: 'Alexander Vesspay');
  final _emailController = TextEditingController(text: 'alex@vesspay.com');
  final _phoneController = TextEditingController(text: '+233 24 123 4567');
  
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'GHS - Cedi';

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
                      _buildProfilePictureSection(),
                      const SizedBox(height: 40),
                      _buildGeneralSection(),
                      const SizedBox(height: 24),
                      _buildPreferencesSection(),
                      const SizedBox(height: 40),
                      AppButton(
                        label: 'Save Changes',
                        onPress: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 40),
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
            'ACCOUNT SETTINGS',
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

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3), width: 2),
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.forestDepths,
                child: Icon(Icons.person_outline_rounded, size: 60, color: AppColors.royalGold),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.royalGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: AppColors.black, size: 20),
            ),
          ],
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        const Text(
          'Alexander Vesspay',
          style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGeneralSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GENERAL INFORMATION',
            style: TextStyle(color: AppColors.royalGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 24),
          FormInput(
            label: 'FULL NAME',
            controller: _nameController,
            hint: 'Full Name',
          ),
          const SizedBox(height: 20),
          FormInput(
            label: 'EMAIL ADDRESS',
            controller: _emailController,
            hint: 'Email Address',
          ),
          const SizedBox(height: 20),
          FormInput(
            label: 'PHONE NUMBER',
            controller: _phoneController,
            hint: 'Phone Number',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPreferencesSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PREFERENCES',
            style: TextStyle(color: AppColors.royalGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 24),
          _buildDropdownRow('LANGUAGE', _selectedLanguage, ['English', 'French', 'Spanish'], (val) => setState(() => _selectedLanguage = val!)),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          _buildDropdownRow('PRIMARY CURRENCY', _selectedCurrency, ['GHS - Cedi', 'USD - Dollar', 'GBP - Pound'], (val) => setState(() => _selectedCurrency = val!)),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDropdownRow(String label, String value, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.deepGreen1,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.royalGold),
            items: options.map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val, style: const TextStyle(color: AppColors.white, fontSize: 14)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
