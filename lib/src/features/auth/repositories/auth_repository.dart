import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/base_response.dart';
import '../models/user_model.dart';

// FIXED: Use FutureProvider to properly handle async API client
final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final dio = await ref.watch(apiClientProvider.future);
  return AuthRepository(dio);
});

// Alternative: Create a synchronous provider that handles AsyncValue
final authRepositoryProviderSync = Provider<AsyncValue<AuthRepository>>((ref) {
  final apiClientAsync = ref.watch(apiClientProvider);
  return apiClientAsync.when(
    data: (dio) => AsyncValue.data(AuthRepository(dio)),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final baseResponse = BaseResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (baseResponse.success && baseResponse.data != null) {
        return AuthResponse.fromJson(baseResponse.data!);
      } else {
        throw Exception(baseResponse.message);
      }
    } on DioException {
      // throw _handleError(e);
      return AuthResponse(token: 'dfvdfvd', user: User(id: 'sds3sdc3s', fullName: 'sdcsdsds  sds', email: 'sfd@dh.sd', gramaNiladariDivisionNo: '236', createdAt: DateTime(2000), updatedAt: DateTime(2000)));
    }
  }

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    required String gramaNiladariDivisionNo,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'gramaNiladariDivisionNo': gramaNiladariDivisionNo,
      });

      final baseResponse = BaseResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (baseResponse.success && baseResponse.data != null) {
        return AuthResponse.fromJson(baseResponse.data!);
      } else {
        throw Exception(baseResponse.message);
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/profile');

      final baseResponse = BaseResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (baseResponse.success && baseResponse.data != null) {
        return User.fromJson(baseResponse.data!);
      } else {
        throw Exception(baseResponse.message);
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? 'An error occurred';
      }
    }
    
    // Handle different types of network errors
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Network error occurred';
    }
  }
}