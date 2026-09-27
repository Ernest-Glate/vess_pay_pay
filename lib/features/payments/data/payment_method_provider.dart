import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentCard {
  final String id;
  final String last4;
  final String brand;
  final String expiry;
  final String holderName;
  final String color;
  final bool isDefault;

  PaymentCard({
    required this.id,
    required this.last4,
    required this.brand,
    required this.expiry,
    required this.holderName,
    required this.color,
    this.isDefault = false,
  });

  factory PaymentCard.initial() => PaymentCard(
    id: '1',
    last4: '4242',
    brand: 'VISA',
    expiry: '12/26',
    holderName: 'ALEXANDER VESSPAY',
    color: '0xFFD4AF37',
  );
}

class PaymentMethodNotifier extends StateNotifier<List<PaymentCard>> {
  PaymentMethodNotifier() : super([
    PaymentCard(
      id: '1',
      last4: '4242',
      brand: 'VISA',
      expiry: '12/26',
      holderName: 'ALEXANDER VESSPAY',
      color: '0xFFD4AF37', // Royal Gold
    ),
    PaymentCard(
      id: '2',
      last4: '8812',
      brand: 'MASTERCARD',
      expiry: '08/25',
      holderName: 'ALEXANDER VESSPAY',
      color: '0xFF1A1A1A', // Carbon Black
    ),
  ]);

  void addCard(PaymentCard card) {
    state = [...state, card];
  }

  void removeCard(String id) {
    state = state.where((card) => card.id != id).toList();
  }
}

final paymentMethodProvider = StateNotifierProvider<PaymentMethodNotifier, List<PaymentCard>>((ref) {
  return PaymentMethodNotifier();
});

final selectedPaymentCardProvider = StateProvider<PaymentCard?>((ref) {
  final cards = ref.watch(paymentMethodProvider);
  return cards.isNotEmpty ? cards.first : null;
});
