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
      try {
        // Token expired or invalid, clear it
        await _storage.delete(key: AppKeys.authToken);
        
        // Optionally trigger logout or redirect to login
        // You might want to use a router or auth state provider here
        // ref.read(authStateProvider.notifier).logout();
        
      } catch (e) {
        debugPrint('Failed to clear auth token: $e');
      }
    }
    handler.next(err);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // Optionally handle token refresh here
    final newToken = response.headers.value('x-new-token');
    if (newToken != null) {
      try {
        await _storage.write(key: AppKeys.authToken, value: newToken);
      } catch (e) {
        debugPrint('Failed to save new auth token: $e');
      }
    }
    handler.next(response);
  }
}