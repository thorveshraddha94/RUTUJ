import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/admin_model.dart';
import '../../tenant/data/tenant_provider.dart';

class AuthState {
  final AdminModel? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;
  final UserRole role;
  final UserStatus status;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
    this.role = UserRole.admin,
    this.status = UserStatus.approved,
  });

  AuthState copyWith({
    AdminModel? user,
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
    UserRole? role,
    UserStatus? status,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? (user?.role ?? this.role),
      status: status ?? (user?.status ?? this.status),
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

  Future<void> _checkCurrentSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await checkUserRole(user);
    }
  }

  Future<void> checkUserRole(User user) async {
    try {
      // 1. Query profile by auth user id or email (case-insensitive)
      final res = await Supabase.instance.client
          .from('profiles')
          .select('role, status, company_id')
          .or('id.eq.${user.id},email.ilike.${user.email ?? ''}')
          .maybeSingle();

      final rawRole = (res?['role'] ?? 'admin').toString().toLowerCase().trim();
      final rawStatus = (res?['status'] ?? 'approved').toString().toLowerCase().trim();

      // 2. Determine Role
      final isSuperadmin = rawRole == 'superadmin' ||
          user.email?.toLowerCase().trim() == 'parthgajjar.bk@gmail.com';
      final isClient = rawRole == 'client';

      final role = isSuperadmin
          ? UserRole.superadmin
          : (isClient ? UserRole.client : UserRole.admin);

      // 3. Determine Status (Support both 'approved' and 'active')
      UserStatus status;
      if (isSuperadmin || rawStatus == 'approved' || rawStatus == 'active') {
        status = UserStatus.approved;
      } else if (rawStatus == 'suspended' || rawStatus == 'blocked') {
        status = UserStatus.suspended;
      } else {
        status = UserStatus.pending;
      }

      final username = (user.userMetadata?['username'] as String?) ?? user.email?.split('@').first ?? 'admin';
      final companyName = (user.userMetadata?['company_name'] as String?) ?? username;

      state = AuthState(
        user: AdminModel(
          id: user.id,
          name: companyName,
          email: user.email ?? '',
          username: username,
          role: role,
          status: status,
        ),
        role: role,
        status: status,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      print('⚠️ [AuthNotifier] Profile role check error: $e');
      final username = (user.userMetadata?['username'] as String?) ?? user.email?.split('@').first ?? 'admin';
      state = AuthState(
        user: AdminModel(
          id: user.id,
          name: username,
          email: user.email ?? '',
          username: username,
          role: UserRole.admin,
          status: UserStatus.approved,
        ),
        role: UserRole.admin,
        status: UserStatus.approved,
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
        await checkUserRole(user);
        await _ref.read(tenantProvider.notifier).loadTenant();
        return true;
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        state = AuthState(
          user: null,
          isAuthenticated: false,
          isLoading: false,
          errorMessage: 'Email unconfirmed. Please check your inbox or try logging in again.',
        );
        return false;
      }
    } catch (_) {}

    if ((identifier.toLowerCase() == 'admin' || identifier.toLowerCase() == 'admin@airporttransfer.com') &&
        password == 'admin123') {
      const admin = AdminModel(
        id: 'ADM-001',
        name: 'Airport Operations Manager',
        email: 'admin@airporttransfer.com',
        username: 'admin',
        role: UserRole.admin,
        status: UserStatus.approved,
      );
      state = const AuthState(
        user: admin,
        role: UserRole.admin,
        status: UserStatus.approved,
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
