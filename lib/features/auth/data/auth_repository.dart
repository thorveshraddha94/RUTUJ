import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/admin_model.dart';

class AuthState {
  final AdminModel? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    AdminModel? user,
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(
          const AuthState(
            user: null,
            isAuthenticated: false,
            isLoading: false,
          ),
        );

  Future<bool> login(String usernameOrEmail, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    await Future.delayed(const Duration(milliseconds: 600));

    final identifier = usernameOrEmail.trim().toLowerCase();

    if ((identifier == 'admin' || identifier == 'admin@airporttransfer.com') &&
        password == 'admin123') {
      const admin = AdminModel(
        id: 'ADM-001',
        name: 'Operations Manager',
        email: 'admin@airporttransfer.com',
        username: 'admin',
        role: UserRole.admin,
      );
      state = const AuthState(
        user: admin,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    }

    state = const AuthState(
      user: null,
      isAuthenticated: false,
      isLoading: false,
      errorMessage: 'Invalid admin username/email or password.',
    );
    return false;
  }

  void logout() {
    state = const AuthState(
      user: null,
      isAuthenticated: false,
      isLoading: false,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
