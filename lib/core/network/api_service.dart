import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'error_handler.dart';

/// Web-safe storage wrapper.
/// On web, FlutterSecureStorage requires HTTPS (Web Crypto API) and can hang
/// or crash in development (localhost HTTP). SharedPreferences is used instead.
class _SafeStorage {
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  Future<String?> read({required String key}) async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      } catch (e) {
        debugPrint('⚠️ Web storage read failed: $e');
        return null;
      }
    }
    try {
      return await _secure.read(key: key);
    } catch (e) {
      debugPrint('⚠️ Secure storage read failed: $e');
      return null;
    }
  }

  Future<void> write({required String key, required String value}) async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      } catch (e) {
        debugPrint('⚠️ Web storage write failed: $e');
      }
      return;
    }
    try {
      await _secure.write(key: key, value: value);
    } catch (e) {
      debugPrint('⚠️ Secure storage write failed: $e');
    }
  }

  Future<void> delete({required String key}) async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      } catch (e) {
        debugPrint('⚠️ Web storage delete failed: $e');
      }
      return;
    }
    try {
      await _secure.delete(key: key);
    } catch (e) {
      debugPrint('⚠️ Secure storage delete failed: $e');
    }
  }
}

class ApiService {
  late final Dio _dio;
  final _SafeStorage _storage = _SafeStorage();
  bool _isRefreshing = false;

  // Web fallback for device ID (sync, no async storage needed on web)
  String? _cachedDeviceId;

  ApiService() {
    var baseUrl = AppConfig.current.baseUrl;

    // Adjust localhost for Android Emulator
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1')) {
        baseUrl = baseUrl
            .replaceFirst('localhost', '10.0.2.2')
            .replaceFirst('127.0.0.1', '10.0.2.2');
        debugPrint('Android URL adjusted: $baseUrl');
      }
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _storage.read(key: 'auth_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            // Attach device ID header
            options.headers['X-Device-ID'] = await getDeviceId();
          } catch (e) {
            debugPrint('⚠️ Storage read failed in interceptor: $e');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // Attempt silent token refresh on 401
          if (e.response?.statusCode == 401 && !_isRefreshing) {
            final refreshed = await _attemptTokenRefresh();
            if (refreshed) {
              // Retry the original request with the new token
              try {
                final newToken = await _storage.read(key: 'auth_token');
                final opts = e.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (retryError) {
                // Refresh succeeded but retry failed — fall through
              }
            }
            // Refresh failed — clear tokens
            await clearToken();
            await clearRefreshToken();
          }
          final appError = ErrorHandler.handle(e);
          return handler.next(DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: appError,
            message: appError.message,
          ));
        },
      ),
    );
  }

  /// Attempt to refresh the access token using the stored refresh token
  Future<bool> _attemptTokenRefresh() async {
    _isRefreshing = true;
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        headers: {'Content-Type': 'application/json'},
      )).post('/auth/refresh', data: {'refreshToken': refreshToken});

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      final newAccessToken = data['tokens']?['accessToken'] as String?;
      final newRefreshToken = data['tokens']?['refreshToken'] as String?;

      if (newAccessToken != null) {
        await setToken(newAccessToken);
        if (newRefreshToken != null) {
          await setRefreshToken(newRefreshToken);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<String> getDeviceId() async {
    // Use cached value to avoid repeated async storage lookups on web
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      var deviceId = await _storage.read(key: 'device_id');
      if (deviceId == null) {
        deviceId = kIsWeb
            ? 'web_${DateTime.now().millisecondsSinceEpoch}'
            : 'flutter_${DateTime.now().millisecondsSinceEpoch}';
        await _storage.write(key: 'device_id', value: deviceId);
      }
      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (e) {
      debugPrint('⚠️ getDeviceId failed: $e');
      _cachedDeviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      return _cachedDeviceId!;
    }
  }

  Dio get client => _dio;

  // Access token management
  Future<String?> getToken() async {
    return _storage.read(key: 'auth_token');
  }

  Future<void> setToken(String token) async {
    return _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    return _storage.delete(key: 'auth_token');
  }

  // Refresh token management
  Future<String?> getRefreshToken() async {
    return _storage.read(key: 'refresh_token');
  }

  Future<void> setRefreshToken(String token) async {
    return _storage.write(key: 'refresh_token', value: token);
  }

  Future<void> clearRefreshToken() async {
    return _storage.delete(key: 'refresh_token');
  }

  /// Extract data from standard success response envelope
  /// Backend format: { "success": true, "data": {...} }
  dynamic extractData(Response response) {
    final body = response.data;
    if (body is Map && body['success'] == true) {
      return body['data'];
    }
    return body;
  }

  /// Extract error message from backend error response
  String extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      return data['error']['message'] ?? 'Unknown error';
    }
    if (data is Map && data['message'] != null) {
      return data['message'];
    }
    return e.message ?? 'Network error';
  }

  /// Extract error code from backend error response
  String? extractErrorCode(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      return data['error']['code'];
    }
    return null;
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await _dio.delete(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }
}

final apiServiceProvider = Provider((ref) => ApiService());
