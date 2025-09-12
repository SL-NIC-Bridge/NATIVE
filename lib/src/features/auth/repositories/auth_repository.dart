import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/base_response.dart';
import '../../../core/constants/api_endpoints.dart';
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
  final String refreshToken;
  final User user;

  AuthResponse({required this.token, required this.refreshToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });

      // The backend sends the AuthResponse data directly.
      if (response.statusCode == 200 || response.statusCode == 201) {
         // Check if the response is wrapped in a 'data' object or not
        final responseData = response.data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
          // Handle cases where it might be wrapped, e.g., { success: true, data: { ... } }
          return AuthResponse.fromJson(responseData['data']);
        } else if (responseData is Map<String, dynamic>) {
           // Handle direct response: { user: {...}, accessToken: "..." }
          return AuthResponse.fromJson(responseData);
        } else {
          throw Exception('Invalid response format from server');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponse> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String divisionId,
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.register, data: {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'password': password,
        'divisionId': divisionId,
      });

      // Handle direct response structure from your API
      if (response.data['success'] == true && response.data['data'] != null) {
        return AuthResponse.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.patch(ApiEndpoints.changePassword, data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        // Check if response has data and follows BaseResponse format
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          
          // If it follows BaseResponse format, check success field
          if (responseData.containsKey('success')) {
            final success = responseData['success'] as bool?;
            if (success == false) {
              final message = responseData['message'] as String? ?? 'Password change failed';
              throw Exception(message);
            }
          }
          // If no success field or success is true, consider it successful
        }
        // If response.data is not a Map or is null, consider it successful (some APIs return empty response)
        return;
      } else {
        // Handle non-2xx status codes
        throw Exception('Password change failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? divisionId,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (divisionId != null) data['divisionId'] = divisionId;

      final response = await _dio.patch(ApiEndpoints.updateProfile, data: data);

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        // Check if response has data and follows BaseResponse format
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          
          // If it follows BaseResponse format, check success field
          if (responseData.containsKey('success')) {
            final success = responseData['success'] as bool?;
            if (success == false) {
              final message = responseData['message'] as String? ?? 'Profile update failed';
              throw Exception(message);
            }
            return User.fromJson(responseData['data'] ?? {});
          }
          // If no success field or success is true, consider it successful
        }
        // If response.data is not a Map or is null, consider it successful (some APIs return empty response)
        return User.fromJson({}); // Return an empty user or handle accordingly
      } else {
        // Handle non-2xx status codes
        throw Exception('Profile update failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        // Handle your backend's error format: {"success": false, "error": {"message": "...", "code": "..."}}
        if (data.containsKey('error') && data['error'] is Map<String, dynamic>) {
          return data['error']['message'] ?? 'An error occurred';
        }
        // Fallback to standard message field
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