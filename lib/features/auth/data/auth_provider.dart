import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../shared/models/user_model.dart';

/// Auth state
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final double walletBalance;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.walletBalance = 0.0,
  });

  bool get isAuthenticated => user != null;
  bool get isEmailVerified => user?.emailVerified ?? false;
  bool get isKycVerified => user?.isKycVerified ?? false;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    double? walletBalance,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  /// Check if user has a stored token and fetch their profile
  Future<void> checkCurrentUser() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.getMe();
      state = state.copyWith(user: user, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  /// POST /api/v1/auth/login
  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    // --- DEMO LOGIN INTERCEPT ---
    if (email == 'demo@vesspay.com' && password == 'Demo@1234') {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
      final demoUser = UserModel(
        id: 'demo_user_123',
        email: email,
        firstName: 'Demo',
        lastName: 'User',
        phone: '+233 24 123 4567',
        nationality: 'Ghana',
        countryOfResidence: 'Ghana',
        kycStatus: 'verified',
        kycTier: 2,
        emailVerified: true,
        walletBalance: 15420.50,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        user: demoUser,
        walletBalance: 15420.50,
        isLoading: false,
      );
      return;
    }
    // ----------------------------

    try {
      final result = await _repo.login(email: email, password: password);
      state = state.copyWith(
        user: result.user,
        walletBalance: result.walletBalance,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// POST /api/v1/auth/register
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? nationality,
    String? countryOfResidence,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        nationality: nationality,
        countryOfResidence: countryOfResidence,
        phone: phone,
      );
      state = state.copyWith(user: result.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// POST /api/v1/auth/logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.logout();
    } finally {
      state = const AuthState();
    }
  }

  /// POST /api/v1/auth/verify-email
  Future<bool> verifyEmail(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final newToken = await _repo.verifyEmail(token);
      if (newToken != null) {
        // Refresh user profile after email verification
        final user = await _repo.getMe();
        state = state.copyWith(user: user, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  /// POST /api/v1/auth/forgot-password
  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.forgotPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// POST /api/v1/auth/reset-password
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.resetPassword(token: token, newPassword: newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  /// Update local user state (e.g., after profile edit)
  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  /// Update wallet balance after transaction
  void updateWalletBalance(double newBalance) {
    state = state.copyWith(walletBalance: newBalance);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid email or password') || msg.contains('AUTH_002')) {
      return 'Invalid email or password';
    }
    if (msg.contains('Account locked') || msg.contains('AUTH_003')) {
      return 'Account locked. Try again later.';
    }
    if (msg.contains('Account is blocked') || msg.contains('AUTH_004')) {
      return 'Your account has been blocked. Contact support.';
    }
    if (msg.contains('AUTH_001')) {
      return 'An account with this email already exists';
    }
    if (msg.contains('Cannot reach VessPay') || msg.contains('CONNECTION_ERROR')) {
      return 'Cannot reach VessPay servers. Please check your connection and try again.';
    }
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Cannot reach VessPay servers. Please try again in a moment.';
    }
    if (msg.contains('timed out')) {
      return 'Connection timed out. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

// Convenience providers
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
