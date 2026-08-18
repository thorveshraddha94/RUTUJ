import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/company_model.dart';
import '../domain/admin_profile_model.dart';

class TenantState {
  final CompanyModel? currentCompany;
  final AdminProfileModel? currentProfile;
  final bool isLoading;
  final String? errorMessage;

  const TenantState({
    this.currentCompany,
    this.currentProfile,
    this.isLoading = false,
    this.errorMessage,
  });

  TenantState copyWith({
    CompanyModel? currentCompany,
    AdminProfileModel? currentProfile,
    bool? isLoading,
    String? errorMessage,
    bool clearCompany = false,
    bool clearProfile = false,
  }) {
    return TenantState(
      currentCompany: clearCompany ? null : (currentCompany ?? this.currentCompany),
      currentProfile: clearProfile ? null : (currentProfile ?? this.currentProfile),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TenantNotifier extends StateNotifier<TenantState> {
  TenantNotifier() : super(const TenantState()) {
    loadTenant();
  }

  Future<void> loadTenant() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // Fallback default state if unauthenticated or using mock local admin
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final client = Supabase.instance.client;

      // 1. Fetch user profile
      final profileRes = await client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (profileRes != null) {
        final profile = AdminProfileModel.fromSupabase(profileRes);

        // 2. Fetch associated company
        final companyRes = await client
            .from('companies')
            .select('*')
            .eq('id', profile.companyId)
            .maybeSingle();

        final company = companyRes != null
            ? CompanyModel.fromSupabase(companyRes)
            : CompanyModel(
                id: profile.companyId,
                name: (user.userMetadata?['company_name'] as String?) ?? 'Airport Operations',
              );

        state = state.copyWith(
          currentProfile: profile,
          currentCompany: company,
          isLoading: false,
        );
        return;
      }

      // Metadata fallback if profile row not yet inserted
      final companyName = (user.userMetadata?['company_name'] as String?) ?? 'Airport Operations';
      final username = (user.userMetadata?['username'] as String?) ?? user.email?.split('@').first ?? 'admin';

      state = state.copyWith(
        currentCompany: CompanyModel(id: 'COMP-001', name: companyName),
        currentProfile: AdminProfileModel(
          id: user.id,
          companyId: 'COMP-001',
          username: username,
          email: user.email,
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load tenant metadata: ${e.toString()}',
      );
    }
  }

  void setTenant(CompanyModel company, AdminProfileModel profile) {
    state = state.copyWith(
      currentCompany: company,
      currentProfile: profile,
      isLoading: false,
      errorMessage: null,
    );
  }

  void clearTenant() {
    state = const TenantState();
  }
}

final tenantProvider = StateNotifierProvider<TenantNotifier, TenantState>((ref) {
  return TenantNotifier();
});
