import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_state.dart';
import '../repositories/auth_repository.dart';
import '../../../core/constants/app_keys.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final Ref _ref;
  static const _storage = FlutterSecureStorage();

  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storage.read(key: AppKeys.authToken);
      if (token != null) {
        // Get current user from real API
        try {
          final authRepository = await _ref.read(authRepositoryProvider.future);
          final user = await authRepository.getCurrentUser();
          state = AsyncValue.data(AuthState(isAuthenticated: true, user: user));
        } catch (e) {
          // Token might be invalid, clear it
          await _storage.delete(key: AppKeys.authToken);
          state = const AsyncValue.data(AuthState());
        }
      } else {
        state = const AsyncValue.data(AuthState());
      }
    } catch (e) {
      state = const AsyncValue.data(AuthState());
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      print('Login - Auth repository type: ${authRepository.runtimeType}');
      final response = await authRepository.login(email, password);
      await _storage.write(key: AppKeys.authToken, value: response.token);
      
      state = AsyncValue.data(AuthState(
        isAuthenticated: true,
        user: response.user,
      ));
    } catch (e, st) {
      print('Auth provider caught error: $e');
      print('Error type: ${e.runtimeType}');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String divisionId,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      final response = await authRepository.register(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        password: password,
        divisionId: divisionId,
      );
      await _storage.write(key: AppKeys.authToken, value: response.token);
      
      state = AsyncValue.data(AuthState(
        isAuthenticated: true,
        user: response.user,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppKeys.authToken);
    state = const AsyncValue.data(AuthState());
  }
}