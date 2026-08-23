import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';

class ClientRepository {
  final SupabaseClient _supabase;
  ClientRepository(this._supabase);

  Future<List<Map<String, dynamic>>> fetchClients() async {
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

    try {
      // 1. Get current Admin tenant company_id from primary client
      final adminUser = _supabase.auth.currentUser;
      String? companyId;
      if (adminUser != null) {
        final adminProfile = await _supabase
            .from('profiles')
            .select('company_id')
            .eq('id', adminUser.id)
            .maybeSingle();
        companyId = adminProfile?['company_id']?.toString();
      }

      print('🚀 [ClientRepo] Registering new client natively: $cleanEmail');

      // 2. Create an isolated SupabaseClient to preserve the active Admin session
      final tempClient = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.supabaseAnonKey,
      );

      // 3. Register user natively through GoTrue Auth Engine
      final authResponse = await tempClient.auth.signUp(
        email: cleanEmail,
        password: cleanPassword,
        data: {
          'username': name.trim(),
          'company_name': company.trim(),
          'role': 'client',
          'contact_phone': phone.trim(),
        },
      );

      final newUserId = authResponse.user?.id;
      if (newUserId == null) {
        throw 'Failed to generate user ID from authentication engine.';
      }

      print('✅ [ClientRepo] GoTrue user created with ID: $newUserId');

      // 4. Save profile record via main Admin client
      await _supabase.from('profiles').upsert({
        'id': newUserId,
        'email': cleanEmail,
        'username': name.trim(),
        'role': 'client',
        'status': 'approved',
        'company_id': companyId,
        'company_name': company.trim(),
        'contact_phone': phone.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ [ClientRepo] Profile linked successfully for client $cleanEmail');

      if (sendWelcomeEmail) {
        try {
          await _supabase.auth.resetPasswordForEmail(
            cleanEmail,
            redirectTo: 'https://travelportl.vercel.app/#/login',
          );
          print('📧 [ClientRepo] Welcome / setup email dispatched to $cleanEmail');
        } catch (emailErr) {
          print('⚠️ [ClientRepo] Email delivery note: $emailErr');
        }
      }
    } catch (e, st) {
      print('❌ [ClientRepo] Error creating client: $e');
      print(st);
      rethrow;
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
