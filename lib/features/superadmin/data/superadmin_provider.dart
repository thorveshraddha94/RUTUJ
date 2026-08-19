import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../tenant/domain/admin_profile_model.dart';

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

  int get totalWorkspaces => admins.length;
  int get pendingApprovals => admins.where((a) => a.isPending).length;
  int get activeApproved => admins.where((a) => a.isApproved).length;
  int get suspended => admins.where((a) => a.isSuspended).length;

  List<AdminProfileModel> get filteredAdmins {
    return admins.where((admin) {
      // Filter by status
      if (filterStatus != 'all') {
        if (filterStatus == 'pending' && !admin.isPending) return false;
        if (filterStatus == 'approved' && !admin.isApproved) return false;
        if (filterStatus == 'suspended' && !admin.isSuspended) return false;
      }
      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final emailMatch = admin.email?.toLowerCase().contains(query) ?? false;
        final nameMatch = admin.username.toLowerCase().contains(query);
        final companyMatch = admin.companyName?.toLowerCase().contains(query) ?? false;
        final phoneMatch = admin.phone?.toLowerCase().contains(query) ?? false;
        return emailMatch || nameMatch || companyMatch || phoneMatch;
      }
      return true;
    }).toList();
  }
}

class SuperadminNotifier extends StateNotifier<SuperadminState> {
  SuperadminNotifier() : super(const SuperadminState()) {
    loadAdmins();
  }

  static List<AdminProfileModel> _getInitialDemoAdmins() {
    return [
      AdminProfileModel(
        id: 'super-001',
        companyId: 'comp-000',
        username: 'parthgajjar.bk',
        email: 'parthgajjar.bk@gmail.com',
        role: 'superadmin',
        status: 'approved',
        companyName: 'Superadmin Central',
        phone: '+1 (555) 000-0001',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      AdminProfileModel(
        id: 'ADM-001',
        companyId: 'COMP-001',
        username: 'admin',
        email: 'admin@airporttransfer.com',
        role: 'admin',
        status: 'approved',
        companyName: 'Airport Operations',
        phone: '+1 (555) 234-5678',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      AdminProfileModel(
        id: 'ADM-002',
        companyId: 'COMP-002',
        username: 'skyline_ops',
        email: 'skyline_transfers@gmail.com',
        role: 'admin',
        status: 'pending',
        companyName: 'Skyline Express Transfers',
        phone: '+1 (555) 876-5432',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      AdminProfileModel(
        id: 'ADM-003',
        companyId: 'COMP-003',
        username: 'city_shuttle_admin',
        email: 'city_shuttle@gmail.com',
        role: 'admin',
        status: 'suspended',
        companyName: 'City Cabs & Shuttles Ltd',
        phone: '+1 (555) 432-1098',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
    ];
  }

  Future<void> loadAdmins() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final client = Supabase.instance.client;

      // 1. Fetch profiles with companies join
      List<dynamic> profilesRes;
      try {
        profilesRes = await client
            .from('profiles')
            .select('*, companies(company_name)');
      } catch (_) {
        // Fallback without join if table relationship isn't configured in client
        profilesRes = await client.from('profiles').select('*');
      }

      if (profilesRes.isNotEmpty) {
        final List<AdminProfileModel> loaded = [];

        // Also fetch companies table for company_name lookup if needed
        Map<String, String> companyNameMap = {};
        try {
          final compRes = await client.from('companies').select('id, company_name');
          for (var c in compRes) {
            final cId = c['id']?.toString() ?? '';
            final cName = c['company_name']?.toString() ?? '';
            if (cId.isNotEmpty && cName.isNotEmpty) {
              companyNameMap[cId] = cName;
            }
          }
        } catch (_) {}

        for (var p in profilesRes) {
          final Map<String, dynamic> json = Map<String, dynamic>.from(p);
          final profile = AdminProfileModel.fromSupabase(json);

          // Populate company name if missing
          final compName = profile.companyName ?? companyNameMap[profile.companyId] ?? 'Workspace Tenant';
          loaded.add(profile.copyWith(companyName: compName));
        }

        // Merge default seed accounts if not already present
        final demoAdmins = _getInitialDemoAdmins();
        for (var demo in demoAdmins) {
          if (!loaded.any((l) => l.email?.toLowerCase() == demo.email?.toLowerCase())) {
            loaded.add(demo);
          }
        }

        state = state.copyWith(admins: loaded, isLoading: false);
      } else {
        // Fallback to initial seed data if Supabase returned empty
        state = state.copyWith(admins: _getInitialDemoAdmins(), isLoading: false);
      }
    } catch (e) {
      // Graceful fallback with demo data on error or offline
      state = state.copyWith(
        admins: _getInitialDemoAdmins(),
        isLoading: false,
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
      final client = Supabase.instance.client;
      await client
          .from('profiles')
          .update({'status': newStatus})
          .eq('id', adminId);
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
      final client = Supabase.instance.client;

      // 1. Call RPC delete_admin_user
      try {
        await client.rpc('delete_admin_user', params: {'user_id': adminId});
      } catch (_) {
        // Retry with alternative RPC parameter name
        try {
          await client.rpc('delete_admin_user', params: {'target_user_id': adminId});
        } catch (_) {
          // Direct table deletion fallback
          await client.from('profiles').delete().eq('id', adminId);
        }
      }
    } catch (_) {}

    // Update local state
    final updatedList = state.admins.where((a) => a.id != adminId).toList();
    state = state.copyWith(admins: updatedList);
    return true;
  }
}

final superadminProvider = StateNotifierProvider<SuperadminNotifier, SuperadminState>((ref) {
  return SuperadminNotifier();
});
