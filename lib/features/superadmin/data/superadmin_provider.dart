import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../tenant/domain/admin_profile_model.dart';

class SuperadminRepository {
  final SupabaseClient _supabase;

  SuperadminRepository([SupabaseClient? client])
      : _supabase = client ?? Supabase.instance.client;

  Future<List<AdminProfileModel>> fetchAllAdmins() async {
    try {
      print('🔍 [SuperadminRepo] Querying public.profiles...');
      final response = await _supabase
          .from('profiles')
          .select('*')
          .neq('role', 'superadmin')
          .neq('email', 'parthgajjar.bk@gmail.com')
          .order('created_at', ascending: false);

      print('📦 [SuperadminRepo] Live profiles count: ${(response as List).length}');
      final list = response as List<dynamic>;

      return list
          .map((item) => AdminProfileModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e, st) {
      print('❌ [SuperadminRepo] Fetch error: $e');
      print(st);
      return [];
    }
  }

  Future<void> updateStatus(String userId, String status) async {
    await _supabase.from('profiles').update({'status': status}).eq('id', userId);
  }

  Future<void> deleteAdmin(String userId) async {
    await _supabase.rpc('delete_admin_user', params: {'target_user_id': userId});
  }
}

final superadminRepositoryProvider = Provider<SuperadminRepository>((ref) {
  return SuperadminRepository();
});

class SuperadminState {
  final List<AdminProfileModel> admins;
  final bool isLoading;
  final String? errorMessage;
  final String filterStatus;
  final String searchQuery;

  const SuperadminState({
    this.admins = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filterStatus = 'all',
    this.searchQuery = '',
  });

  SuperadminState copyWith({
    List<AdminProfileModel>? admins,
    bool? isLoading,
    String? errorMessage,
    String? filterStatus,
    String? searchQuery,
  }) {
    return SuperadminState(
      admins: admins ?? this.admins,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filterStatus: filterStatus ?? this.filterStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  int get totalWorkspaces => admins.where((a) => !a.isSuperAdmin).length;
  int get pendingApprovals => admins.where((a) => !a.isSuperAdmin && a.isPending).length;
  int get activeApproved => admins.where((a) => !a.isSuperAdmin && a.isApproved).length;
  int get suspended => admins.where((a) => !a.isSuperAdmin && a.isSuspended).length;

  List<AdminProfileModel> get filteredAdmins {
    return admins.where((admin) {
      // Exclude superadmin accounts from tenant table directory
      if (admin.isSuperAdmin || admin.email.toLowerCase() == 'parthgajjar.bk@gmail.com' || admin.role.toLowerCase() == 'superadmin') {
        return false;
      }
      // Filter by status
      if (filterStatus != 'all') {
        if (filterStatus == 'pending' && !admin.isPending) return false;
        if (filterStatus == 'approved' && !admin.isApproved) return false;
        if (filterStatus == 'suspended' && !admin.isSuspended) return false;
      }
      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final emailMatch = admin.email.toLowerCase().contains(query);
        final nameMatch = admin.username.toLowerCase().contains(query);
        final companyMatch = admin.companyName.toLowerCase().contains(query);
        final phoneMatch = admin.phone.toLowerCase().contains(query);
        return emailMatch || nameMatch || companyMatch || phoneMatch;
      }
      return true;
    }).toList();
  }
}

class SuperadminNotifier extends StateNotifier<SuperadminState> {
  final SuperadminRepository _repository;

  SuperadminNotifier(this._repository) : super(const SuperadminState()) {
    loadAdmins();
  }

  Future<void> loadAdmins() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final fetchedProfiles = await _repository.fetchAllAdmins();
      state = state.copyWith(admins: fetchedProfiles, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        admins: [],
        isLoading: false,
        errorMessage: 'Failed to load admin profiles: $e',
      );
    }
  }

  void setFilterStatus(String status) {
    state = state.copyWith(filterStatus: status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> approveAdmin(String adminId) async {
    return _updateAdminStatus(adminId, 'approved');
  }

  Future<bool> suspendAdmin(String adminId) async {
    return _updateAdminStatus(adminId, 'suspended');
  }

  Future<bool> _updateAdminStatus(String adminId, String newStatus) async {
    try {
      await _repository.updateStatus(adminId, newStatus);
    } catch (_) {}

    // Update local state
    final updatedList = state.admins.map((a) {
      if (a.id == adminId) {
        return a.copyWith(status: newStatus);
      }
      return a;
    }).toList();

    state = state.copyWith(admins: updatedList);
    return true;
  }

  Future<bool> deleteAdmin(String adminId) async {
    try {
      await _repository.deleteAdmin(adminId);
    } catch (_) {}

    // Update local state
    final updatedList = state.admins.where((a) => a.id != adminId).toList();
    state = state.copyWith(admins: updatedList);
    return true;
  }
}

final superadminProvider = StateNotifierProvider<SuperadminNotifier, SuperadminState>((ref) {
  final repo = ref.watch(superadminRepositoryProvider);
  return SuperadminNotifier(repo);
});

final superadminListProvider = superadminProvider;
final superadminNotifierProvider = superadminProvider;
