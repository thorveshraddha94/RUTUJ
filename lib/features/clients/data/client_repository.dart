import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientRepository {
  final SupabaseClient _supabase;
  ClientRepository(this._supabase);

  Future<List<Map<String, dynamic>>> fetchClients() async {
    try {
      final user = _supabase.auth.currentUser;
      String? companyId;
      if (user != null) {
        final profile = await _supabase
            .from('profiles')
            .select('company_id')
            .eq('id', user.id)
            .maybeSingle();
        companyId = profile?['company_id']?.toString();
      }

      var query = _supabase.from('profiles').select('*').eq('role', 'client');
      if (companyId != null && companyId.isNotEmpty) {
        query = query.eq('company_id', companyId);
      }
      final res = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      if (kDebugMode) print('❌ [ClientRepo] Error loading clients: $e');
      return [];
    }
  }

  Future<void> createClient({
    required String name,
    required String email,
    required String password,
    required String company,
    required String phone,
    bool sendWelcomeEmail = true,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanName = name.trim();
    final cleanCompany = company.trim();
    final cleanPhone = phone.trim();

    final currentUser = _supabase.auth.currentUser;
    String? companyId;
    if (currentUser != null) {
      final profile = await _supabase
          .from('profiles')
          .select('company_id')
          .eq('id', currentUser.id)
          .maybeSingle();
      companyId = profile?['company_id']?.toString();
    }

    if (kDebugMode) {
      print('🚀 [ClientRepo] Calling RPC create_client_user for: $cleanEmail');
    }

    // Call PostgreSQL RPC function directly
    final response = await _supabase.rpc('create_client_user', params: {
      'client_email': cleanEmail,
      'client_password': cleanPassword,
      'client_name': cleanName,
      'client_company': cleanCompany,
      'client_phone': cleanPhone,
      'tenant_company_id': companyId,
    });

    if (kDebugMode) {
      print('✅ [ClientRepo] Client created successfully with UID: $response');
    }

    if (sendWelcomeEmail) {
      try {
        await _supabase.auth.resetPasswordForEmail(
          cleanEmail,
          redirectTo: 'https://travelportl.vercel.app/#/login',
        );
        if (kDebugMode) {
          print('📧 [ClientRepo] Welcome / setup email dispatched to $cleanEmail');
        }
      } catch (emailErr) {
        if (kDebugMode) {
          print('⚠️ [ClientRepo] Email delivery note: $emailErr');
        }
      }
    }
  }
}

class ClientState {
  final List<Map<String, dynamic>> clients;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  const ClientState({
    required this.clients,
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  List<Map<String, dynamic>> get filteredClients {
    if (searchQuery.trim().isEmpty) return clients;
    final q = searchQuery.toLowerCase().trim();
    return clients.where((c) {
      final name = (c['name'] ?? c['client_name'] ?? c['full_name'] ?? '').toString().toLowerCase();
      final email = (c['email'] ?? c['client_email'] ?? '').toString().toLowerCase();
      final company = (c['company'] ?? c['company_name'] ?? c['client_company'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? c['mobile'] ?? c['client_phone'] ?? c['phone_number'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || company.contains(q) || phone.contains(q);
    }).toList();
  }

  ClientState copyWith({
    List<Map<String, dynamic>>? clients,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return ClientState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ClientNotifier extends StateNotifier<ClientState> {
  final ClientRepository _repository;

  ClientNotifier(this._repository) : super(const ClientState(clients: [], isLoading: true)) {
    loadClients();
  }

  Future<void> loadClients() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.fetchClients();
      state = state.copyWith(clients: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> createClient({
    required String name,
    required String email,
    required String password,
    required String company,
    required String phone,
    bool sendWelcomeEmail = true,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createClient(
        name: name,
        email: email,
        password: password,
        company: company,
        phone: phone,
        sendWelcomeEmail: sendWelcomeEmail,
      );
      await loadClients();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(Supabase.instance.client);
});

final clientProvider = StateNotifierProvider<ClientNotifier, ClientState>((ref) {
  final repo = ref.watch(clientRepositoryProvider);
  return ClientNotifier(repo);
});
