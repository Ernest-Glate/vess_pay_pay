import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/models/beneficiary_model.dart';
import '../data/beneficiary_provider.dart';

class BeneficiariesScreen extends ConsumerStatefulWidget {
  const BeneficiariesScreen({super.key});

  @override
  ConsumerState<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends ConsumerState<BeneficiariesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beneficiaries = ref.watch(beneficiaryProvider);
    final beneficiaryNotifier = ref.read(beneficiaryProvider.notifier);
    
    final displayedBeneficiaries = _searchQuery.isEmpty
        ? beneficiaries
        : beneficiaryNotifier.search(_searchQuery);

    final favorites = displayedBeneficiaries.where((b) => b.isFavorite).toList();
    final recent = beneficiaryNotifier.getRecent();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Beneficiaries',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.royalGold),
            onPressed: () => _showAddBeneficiaryDialog(context),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search beneficiaries...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      icon: Icon(Icons.search_rounded, color: AppColors.royalGold),
                      suffixIcon: null,
                    ),
                  ),
                ),
              ),

              // Tabs
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.royalGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: AppColors.darkBg,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Favorites'),
                    Tab(text: 'Recent'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBeneficiaryList(displayedBeneficiaries),
                    _buildBeneficiaryList(favorites),
                    _buildBeneficiaryList(recent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeneficiaryList(List<BeneficiaryModel> beneficiaries) {
    if (beneficiaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No beneficiaries found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: beneficiaries.length,
      itemBuilder: (context, index) {
        final beneficiary = beneficiaries[index];
        return _buildBeneficiaryCard(beneficiary);
      },
    );
  }

  Widget _buildBeneficiaryCard(BeneficiaryModel beneficiary) {
    final beneficiaryNotifier = ref.read(beneficiaryProvider.notifier);
    
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.royalGold.withValues(alpha: 0.3),
                  AppColors.royalGold.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Center(
              child: Text(
                beneficiary.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.royalGold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        beneficiary.name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        beneficiary.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        color: beneficiary.isFavorite ? AppColors.royalGold : AppColors.textSecondary,
                      ),
                      onPressed: () => beneficiaryNotifier.toggleFavorite(beneficiary.id),
                    ),
                  ],
                ),
                Text(
                  beneficiary.bankName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  beneficiary.accountNumber,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            color: AppColors.cardBg,
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.send_rounded, color: AppColors.royalGold, size: 20),
                    SizedBox(width: 12),
                    Text('Send Money', style: TextStyle(color: AppColors.white)),
                  ],
                ),
                onTap: () {
                  // Navigate to send money with pre-filled beneficiary
                  context.push('/send-money', extra: beneficiary);
                },
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.edit_rounded, color: AppColors.royalGold, size: 20),
                    SizedBox(width: 12),
                    Text('Edit', style: TextStyle(color: AppColors.white)),
                  ],
                ),
                onTap: () => _showEditBeneficiaryDialog(context, beneficiary),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.delete_rounded, color: AppColors.errorRed, size: 20),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: AppColors.errorRed)),
                  ],
                ),
                onTap: () => _confirmDelete(context, beneficiary.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddBeneficiaryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final accountController = TextEditingController();
    final bankController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Add Beneficiary', style: TextStyle(color: AppColors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderGray),
                  ),
                ),
              ),
              TextField(
                controller: accountController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderGray),
                  ),
                ),
              ),
              TextField(
                controller: bankController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderGray),
                  ),
                ),
              ),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderGray),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  accountController.text.isNotEmpty &&
                  bankController.text.isNotEmpty) {
                final newBeneficiary = BeneficiaryModel(
                  id: 'ben_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  accountNumber: accountController.text,
                  bankName: bankController.text,
                  phoneNumber: phoneController.text.isEmpty ? null : phoneController.text,
                  createdAt: DateTime.now(),
                  lastUsed: DateTime.now(),
                );
                
                ref.read(beneficiaryProvider.notifier).addBeneficiary(newBeneficiary);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Beneficiary added successfully'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              }
            },
            child: const Text('Add', style: TextStyle(color: AppColors.royalGold)),
          ),
        ],
      ),
    );
  }

  void _showEditBeneficiaryDialog(BuildContext context, BeneficiaryModel beneficiary) {
    final nameController = TextEditingController(text: beneficiary.name);
    final accountController = TextEditingController(text: beneficiary.accountNumber);
    final bankController = TextEditingController(text: beneficiary.bankName);
    final phoneController = TextEditingController(text: beneficiary.phoneNumber ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Edit Beneficiary', style: TextStyle(color: AppColors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderGray),
                  ),
                ),
              ),
              TextField(
                controller: accountController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderGray),
                  ),
                ),
              ),
              TextField(
                controller: bankController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderGray),
                  ),
                ),
              ),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderGray),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final updated = beneficiary.copyWith(
                name: nameController.text,
                accountNumber: accountController.text,
                bankName: bankController.text,
                phoneNumber: phoneController.text.isEmpty ? null : phoneController.text,
              );
              
              ref.read(beneficiaryProvider.notifier).updateBeneficiary(updated);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Beneficiary updated successfully'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            child: const Text('Save', style: TextStyle(color: AppColors.royalGold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Delete Beneficiary', style: TextStyle(color: AppColors.white)),
        content: const Text(
          'Are you sure you want to delete this beneficiary?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(beneficiaryProvider.notifier).removeBeneficiary(id);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Beneficiary deleted'),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }
}
