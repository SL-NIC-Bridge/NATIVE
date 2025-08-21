import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/mock_api_service.dart';
import '../../auth/models/user_model.dart';

// Mock repository provider that overrides the real repository
final mockAuthRepositoryProvider = Provider<MockAuthRepository>((ref) {
  final mockService = ref.watch(mockServiceProvider);
  return MockAuthRepository(mockService);
});

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});
}

class MockAuthRepository {
  final MockApiService _mockService;
  
  MockAuthRepository(this._mockService);

  Future<AuthResponse> login(String email, String password) async {
    final user = await _mockService.getCurrentUser();
    // Simple mock validation
    if (email == user.email && password == 'password') {
      return AuthResponse(
        token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        user: user,
      );
    }
    throw Exception('Invalid credentials');
  }

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    required String gramaNiladariDivisionNo,
  }) async {
    final user = await _mockService.updateUserProfile(
      fullName: fullName,
      email: email,
      gramaNiladariDivisionNo: gramaNiladariDivisionNo,
    );
    
    return AuthResponse(
      token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      user: user,
    );
  }

  Future<User> getCurrentUser() async {
    return _mockService.getCurrentUser();
  }

  Future<void> updateProfile({
    required String fullName,
    required String gramaNiladariDivisionNo,
  }) async {
    await _mockService.updateUserProfile(
      fullName: fullName,
      gramaNiladariDivisionNo: gramaNiladariDivisionNo,
    );
  }
}
