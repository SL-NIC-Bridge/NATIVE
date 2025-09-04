import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bcrypt/bcrypt.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/base_response.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

// Auth service provider
final authServiceProvider = FutureProvider<AuthService>((ref) async {
  final dio = await ref.watch(apiClientProvider.future);
  return AuthService(dio);
});

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  // Login with email and password
  Future<AuthResponse> login(String email, String password) async {
    try {
      // Hash password with bcrypt (12 salt rounds) on frontend
      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 12));
      
      final response = await _dio.post(ApiEndpoints.login, data: {
        'email': email,
        'passwordHash': passwordHash,
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

  // Register new user
  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    required String gramaNiladariDivisionNo,
  }) async {
    try {
      // Hash password with bcrypt (12 salt rounds) on frontend
      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 12));
      
      final response = await _dio.post(ApiEndpoints.register, data: {
        'fullName': fullName,
        'email': email,
        'passwordHash': passwordHash,
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

  // Get current authenticated user
  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.profile);

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

  // Update user profile
  Future<User> updateProfile({
    required String fullName,
    required String gramaNiladariDivisionNo,
  }) async {
    try {
      final response = await _dio.put(ApiEndpoints.updateProfile, data: {
        'fullName': fullName,
        'gramaNiladariDivisionNo': gramaNiladariDivisionNo,
      });

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

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Hash both passwords with bcrypt (12 salt rounds) on frontend
      final currentPasswordHash = BCrypt.hashpw(currentPassword, BCrypt.gensalt(logRounds: 12));
      final newPasswordHash = BCrypt.hashpw(newPassword, BCrypt.gensalt(logRounds: 12));
      
      final response = await _dio.post(ApiEndpoints.changePassword, data: {
        'currentPasswordHash': currentPasswordHash,
        'newPasswordHash': newPasswordHash,
      });

      final baseResponse = BaseResponse<void>.fromJson(
        response.data,
        (json) => null,
      );

      if (!baseResponse.success) {
        throw Exception(baseResponse.message);
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post(ApiEndpoints.forgotPassword, data: {
        'email': email,
      });

      final baseResponse = BaseResponse<void>.fromJson(
        response.data,
        (json) => null,
      );

      if (!baseResponse.success) {
        throw Exception(baseResponse.message);
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Reset password
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      // Hash password with bcrypt (12 salt rounds) on frontend
      final newPasswordHash = BCrypt.hashpw(newPassword, BCrypt.gensalt(logRounds: 12));
      
      final response = await _dio.post(ApiEndpoints.resetPassword, data: {
        'token': token,
        'newPasswordHash': newPasswordHash,
      });

      final baseResponse = BaseResponse<void>.fromJson(
        response.data,
        (json) => null,
      );

      if (!baseResponse.success) {
        throw Exception(baseResponse.message);
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Logout (if server-side logout is needed)
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      // Don't throw error for logout, just log it
      print('Logout error: ${_handleError(e)}');
    }
  }

  // Refresh token
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(ApiEndpoints.refreshToken, data: {
        'refreshToken': refreshToken,
      });

      final baseResponse = BaseResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (baseResponse.success && baseResponse.data != null) {
        return baseResponse.data!['token'] as String;
      } else {
        throw Exception(baseResponse.message);
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Handle Dio errors and convert to user-friendly messages
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
