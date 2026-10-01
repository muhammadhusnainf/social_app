
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'models.dart';

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  final bool isRestoring;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isRestoring = false,
  });

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool? isRestoring,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }

  bool get isSignedIn => user != null;
}

String _errorMessage(Object e) {
  if (e is ApiException) return e.message;
  if (e is DioException) {
    return 'Could not reach the server. Check your connection and try again.';
  }
  return 'Something went wrong. Please try again.';
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    api.onUnauthorized = () => state = const AuthState();

    Future.microtask(_restoreSession);
    return const AuthState(isRestoring: true);
  }

  Future<void> _restoreSession() async {
    try {
      final saved = await api.loadUser();
      if (saved == null || !await api.hasSavedLogin()) {
        state = const AuthState();
        return;
      }

      try {
        final stillValid = await api.isSignedIn();
        if (stillValid) {
          state = AuthState(user: saved);
        } else {
          await api.clearSession();
          state = const AuthState();
        }
      } on DioException {
        state = AuthState(user: saved);
      }
    } catch (_) {
      state = const AuthState();
    }
  }

  void clearError() => state = state.copyWith();

  Future<void> signup({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await api.signup(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await api.login(email: email, password: password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
    } finally {
      state = const AuthState();
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);