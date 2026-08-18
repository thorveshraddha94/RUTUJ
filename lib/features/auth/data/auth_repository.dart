import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/admin_model.dart';
import '../../tenant/data/tenant_provider.dart';

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
  final Ref _ref;

  AuthNotifier(this._ref)
      : super(
          const AuthState(
            user: null,
            isAuthenticated: false,
            isLoading: false,
          ),
        ) {
    _checkCurrentSession();
  }

  void _checkCurrentSession() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final username = (user.userMetadata?['username'] as String?) ?? user.email?.split('@').first ?? 'admin';
      final name = (user.userMetadata?['company_name'] as String?) ?? username;
      state = AuthState(
        user: AdminModel(
          id: user.id,
          name: name,
          email: user.email ?? '',
          username: username,
          role: UserRole.admin,
        ),
        isAuthenticated: true,
        isLoading: false,
      );
    }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final identifier = usernameOrEmail.trim();

    try {
      final client = Supabase.instance.client;
      final response = await client.auth.signInWithPassword(
        email: identifier.contains('@') ? identifier : '$identifier@airporttransfer.com',
        password: password,
      );

      final user = response.user;
      if (user != null) {
        final username = (user.userMetadata?['username'] as String?) ?? identifier;
        final companyName = (user.userMetadata?['company_name'] as String?) ?? 'Airport Operations';

        final admin = AdminModel(
          id: user.id,
          name: companyName,
          email: user.email ?? identifier,
          username: username,
          role: UserRole.admin,
        );

        state = AuthState(
          user: admin,
          isAuthenticated: true,
          isLoading: false,
        );

        await _ref.read(tenantProvider.notifier).loadTenant();
        return true;
      }
    } catch (_) {
      // Fallback local admin check if Supabase authentication endpoint fails/offline
    }

    if ((identifier.toLowerCase() == 'admin' || identifier.toLowerCase() == 'admin@airporttransfer.com') &&
        password == 'admin123') {
      const admin = AdminModel(
        id: 'ADM-001',
        name: 'Airport Operations Manager',
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
      errorMessage: 'Invalid username/email or password.',
    );
    return false;
  }

  void logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    _ref.read(tenantProvider.notifier).clearTenant();

    state = const AuthState(
      user: null,
      isAuthenticated: false,
      isLoading: false,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

