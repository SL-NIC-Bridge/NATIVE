import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config_provider.dart';
import '../constants/app_keys.dart';

// CORRECT: Use FutureProvider with proper async handling
final apiClientProvider = FutureProvider<Dio>((ref) async {
  // Wait for config to load completely
  final config = await ref.watch(appConfigProvider.future);
  
  print('API Client Config - Base URL: ${config.apiBaseUrl}');
  
  final dio = Dio(BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Add auth interceptor
  dio.interceptors.add(AuthInterceptor(ref));

  // Add logging in debug mode
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
    ));
  }

  return dio;
});

// Alternative: Use AsyncNotifierProvider for more control
final apiClientProvider2 = AsyncNotifierProvider<ApiClientNotifier, Dio>(() {
  return ApiClientNotifier();
});

class ApiClientNotifier extends AsyncNotifier<Dio> {
  @override
  Future<Dio> build() async {
    final config = await ref.watch(appConfigProvider.future);
    
    final dio = Dio(BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add auth interceptor
    dio.interceptors.add(AuthInterceptor(ref));

    // Add logging in debug mode
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
      ));
    }

    return dio;
  }
}

class AuthInterceptor extends Interceptor {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _storage.read(key: AppKeys.authToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // Log error but continue with request
      debugPrint('Failed to read auth token: $e');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Check if it's a token expiration error vs. other 401 errors
      final responseData = err.response?.data;
      if (responseData is Map && responseData['error']?['code'] == 'TOKEN_EXPIRED') {
        try {
          // Token expired, try to refresh it
          final refreshToken = await _storage.read(key: AppKeys.refreshToken);
          
          if (refreshToken != null && refreshToken.isNotEmpty) {
            // Create a new dio instance for refresh request to avoid infinite loops
            final config = await ref.read(appConfigProvider.future);
            final refreshDio = Dio(BaseOptions(
              baseUrl: config.apiBaseUrl,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ));
            
            // Make refresh token request
            final refreshResponse = await refreshDio.post('/auth/refresh', data: {
              'refreshToken': refreshToken,
            });
            
            if (refreshResponse.statusCode == 200) {
              final data = refreshResponse.data;
              final newAccessToken = data['accessToken'] ?? data['token'];
              final newRefreshToken = data['refreshToken'];
              
              if (newAccessToken != null) {
                // Store new tokens
                await _storage.write(key: AppKeys.authToken, value: newAccessToken);
                if (newRefreshToken != null) {
                  await _storage.write(key: AppKeys.refreshToken, value: newRefreshToken);
                }
                
                // Retry the original request with new token
                final requestOptions = err.requestOptions;
                requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                
                final response = await Dio().fetch(requestOptions);
                handler.resolve(response);
                return;
              }
            }
          }
          
          // If refresh failed or no refresh token, clear tokens and force re-login
          await _storage.delete(key: AppKeys.authToken);
          await _storage.delete(key: AppKeys.refreshToken);
          
        } catch (e) {
          debugPrint('Failed to refresh token: $e');
          // Clear tokens on refresh failure
          await _storage.delete(key: AppKeys.authToken);
          await _storage.delete(key: AppKeys.refreshToken);
        }
      } else {
        // For other 401 errors (e.g., invalid token), don't automatically clear it
        // The request might be unauthorized for other reasons
        debugPrint('Received 401 Unauthorized, but not a token expiration error.');
      }
    }
    handler.next(err);
  }
}