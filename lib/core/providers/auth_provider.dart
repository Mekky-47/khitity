import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giyas_ai/core/models/user.dart';
import 'package:giyas_ai/core/services/auth_service.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final user = await AuthService.getUser();
      if (user != null) {
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final result = await AuthService.login(email: email, password: password);

      if (result.isSuccess && result.user != null) {
        state = AsyncValue.data(result.user);
        return true;
      } else {
        state = AsyncValue.error(
            result.message ?? 'Login failed', StackTrace.current);
        return false;
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final result = await AuthService.register(
        name: name,
        email: email,
        password: password,
      );

      if (result.isSuccess && result.user != null) {
        state = AsyncValue.data(result.user);
        return true;
      } else {
        state = AsyncValue.error(
            result.message ?? 'Registration failed', StackTrace.current);
        return false;
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await AuthService.logout();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshProfile() async {
    try {
      final result = await AuthService.getProfile();
      if (result.isSuccess && result.user != null) {
        state = AsyncValue.data(result.user);
      }
    } catch (e) {
      // Don't update state on profile refresh failure
      // Log error for debugging
    }
  }

  Future<bool> updateProfile(
      {String? name, UserPreferences? preferences}) async {
    try {
      final result = await AuthService.updateProfile(
        name: name,
        preferences: preferences,
      );

      if (result.isSuccess && result.user != null) {
        state = AsyncValue.data(result.user);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final result = await AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  bool get isAuthenticated => state.value != null;
  User? get currentUser => state.value;
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) => AuthNotifier(),
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value != null;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value;
});
