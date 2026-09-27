import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/beneficiary_model.dart';

class BeneficiaryNotifier extends StateNotifier<List<BeneficiaryModel>> {
  BeneficiaryNotifier() : super(_mockBeneficiaries);

  // Add beneficiary
  void addBeneficiary(BeneficiaryModel beneficiary) {
    state = [...state, beneficiary];
  }

  // Remove beneficiary
  void removeBeneficiary(String id) {
    state = state.where((b) => b.id != id).toList();
  }

  // Toggle favorite
  void toggleFavorite(String id) {
    state = state.map((b) {
      if (b.id == id) {
        return b.copyWith(isFavorite: !b.isFavorite);
      }
      return b;
    }).toList();
  }

  // Update beneficiary
  void updateBeneficiary(BeneficiaryModel beneficiary) {
    state = state.map((b) {
      if (b.id == beneficiary.id) {
        return beneficiary;
      }
      return b;
    }).toList();
  }

  // Increment usage
  void incrementUsage(String id) {
    state = state.map((b) {
      if (b.id == id) {
        return b.copyWith(
          usageCount: b.usageCount + 1,
          lastUsed: DateTime.now(),
        );
      }
      return b;
    }).toList();
  }

  // Get favorites
  List<BeneficiaryModel> getFavorites() {
    return state.where((b) => b.isFavorite).toList();
  }

  // Get recent (top 5)
  List<BeneficiaryModel> getRecent() {
    final sorted = [...state];
    sorted.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return sorted.take(5).toList();
  }

  // Get frequent (by usage count)
  List<BeneficiaryModel> getFrequent() {
    final sorted = [...state];
    sorted.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return sorted.take(5).toList();
  }

  // Search beneficiaries
  List<BeneficiaryModel> search(String query) {
    if (query.isEmpty) return state;
    
    final lowerQuery = query.toLowerCase();
    return state.where((b) {
      return b.name.toLowerCase().contains(lowerQuery) ||
          b.accountNumber.contains(query) ||
          b.bankName.toLowerCase().contains(lowerQuery) ||
          (b.phoneNumber?.contains(query) ?? false);
    }).toList();
  }
}

final beneficiaryProvider = StateNotifierProvider<BeneficiaryNotifier, List<BeneficiaryModel>>((ref) {
  return BeneficiaryNotifier();
});

// Mock beneficiaries for demo
final List<BeneficiaryModel> _mockBeneficiaries = [
  BeneficiaryModel(
    id: 'ben1',
    name: 'Kwame Mensah',
    accountNumber: '1234567890',
    bankName: 'GCB Bank',
    phoneNumber: '+233244123456',
    isFavorite: true,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    lastUsed: DateTime.now().subtract(const Duration(days: 2)),
    usageCount: 12,
  ),
  BeneficiaryModel(
    id: 'ben2',
    name: 'Ama Serwaa',
    accountNumber: '0987654321',
    bankName: 'Ecobank Ghana',
    phoneNumber: '+233201234567',
    isFavorite: true,
    createdAt: DateTime.now().subtract(const Duration(days: 45)),
    lastUsed: DateTime.now().subtract(const Duration(days: 5)),
    usageCount: 8,
  ),
  BeneficiaryModel(
    id: 'ben3',
    name: 'Kofi Addo',
    accountNumber: '5555123456',
    bankName: 'Stanbic Bank',
    phoneNumber: '+233245678901',
    isFavorite: false,
    createdAt: DateTime.now().subtract(const Duration(days: 60)),
    lastUsed: DateTime.now().subtract(const Duration(days: 10)),
    usageCount: 5,
  ),
];
