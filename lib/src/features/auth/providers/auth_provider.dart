import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sl_nic_bridge/src/features/auth/models/user_model.dart';
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
        // final user = await authRepository.getCurrentUser();
        state = AsyncValue.data(AuthState(isAuthenticated: true, user: User(id: 'dfvd', fullName: 'dfvdf', email: 'dfvd@ghf.d', gramaNiladariDivisionNo: '405', createdAt: DateTime(2000), updatedAt: DateTime(2000))));
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
      final response = await authRepository.login(email, password);
      await _storage.write(key: AppKeys.authToken, value: response.token);
      
      state = AsyncValue.data(AuthState(
        isAuthenticated: true,
        user: response.user,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String gramaNiladariDivisionNo,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      final response = await authRepository.register(
        fullName: fullName,
        email: email,
        password: password,
        gramaNiladariDivisionNo: gramaNiladariDivisionNo,
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

  void clearError() {
    if (state.value?.error != null) {
      state = AsyncValue.data(state.value!.copyWith(error: null));
    }
  }
}