import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_service.dart';
import '../network/api_endpoints.dart';
import '../../shared/models/user_model.dart';

class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  /// POST /api/v1/auth/register
  /// Backend returns: { success: true, data: { token, refreshToken, user } }
  Future<({UserModel user, String token})> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? nationality,
    String? countryOfResidence,
    String? phone,
  }) async {
    final response = await _api.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (nationality != null) 'nationality': nationality,
        if (countryOfResidence != null)
          'countryOfResidence': countryOfResidence,
        if (phone != null) 'phone': phone,
      },
    );

    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final refreshToken = data['refreshToken'] as String?;

    await _api.setToken(token);
    if (refreshToken != null) {
      await _api.setRefreshToken(refreshToken);
    }

    return (
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      token: token,
    );
  }

  /// POST /api/v1/auth/login
  /// Backend returns: { success: true, data: { token, refreshToken, user } }
  Future<({UserModel user, String token, double walletBalance})> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await _api.getDeviceId();

    final response = await _api.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
        'deviceId': deviceId,
      },
    );

    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final refreshToken = data['refreshToken'] as String?;

    await _api.setToken(token);
    if (refreshToken != null) {
      await _api.setRefreshToken(refreshToken);
    }

    final userMap = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userMap);
    final wallet = userMap['wallet'] as Map<String, dynamic>?;
    final balance = (wallet?['balance'] as num?)?.toDouble() ?? 0.0;

    return (user: user, token: token, walletBalance: balance);
  }

  /// POST /api/v1/auth/logout
  Future<void> logout() async {
    try {
      final refreshToken = await _api.getRefreshToken();
      await _api.post(
        ApiEndpoints.logout,
        data: {
          if (refreshToken != null) 'refreshToken': refreshToken,
        },
      );
    } catch (_) {
      // Always clear local tokens even if API call fails
    } finally {
      await _api.clearToken();
      await _api.clearRefreshToken();
    }
  }

  /// POST /api/v1/auth/verify-email
  Future<String?> verifyEmail(String token) async {
    final response = await _api.post(
      ApiEndpoints.verifyEmail,
      data: {'token': token},
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    return data?['token'] as String?;
  }

  /// POST /api/v1/auth/forgot-password
  Future<void> forgotPassword(String email) async {
    await _api.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  /// POST /api/v1/auth/reset-password
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.post(
      ApiEndpoints.resetPassword,
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  /// POST /api/v1/auth/refresh-token
  /// Sends stored refresh token, receives new access + refresh tokens
  Future<String> refreshToken() async {
    final storedRefreshToken = await _api.getRefreshToken();
    final response = await _api.post(
      ApiEndpoints.refreshToken,
      data: {
        if (storedRefreshToken != null) 'refreshToken': storedRefreshToken,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final newToken = data['tokens']?['accessToken'] as String? ?? data['token'] as String;
    final newRefreshToken = data['tokens']?['refreshToken'] as String?;
    await _api.setToken(newToken);
    if (newRefreshToken != null) {
      await _api.setRefreshToken(newRefreshToken);
    }
    return newToken;
  }

  /// GET /api/v1/users/me
  Future<UserModel?> getMe() async {
    final token = await _api.getToken();
    if (token == null) return null;

    try {
      final response = await _api.get(ApiEndpoints.getMe);
      final body = response.data as Map<String, dynamic>;
      // Handle both { data: {...} } and flat response
      final data = body.containsKey('data')
          ? body['data'] as Map<String, dynamic>
          : body;
      return UserModel.fromJson(data);
    } catch (_) {
      await _api.clearToken();
      await _api.clearRefreshToken();
      return null;
    }
  }

  /// Check if user has a stored token
  Future<bool> hasToken() async {
    final token = await _api.getToken();
    return token != null;
  }
}

final authRepositoryProvider = Provider((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepository(apiService);
});
