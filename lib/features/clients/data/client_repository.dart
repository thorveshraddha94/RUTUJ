import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';

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
      if (kDebugMode) print('❌ [ClientRepo] fetchClients error: $e');
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

    // 1. Get active admin details safely without null checks
    final adminUser = _supabase.auth.currentUser;
    if (adminUser == null) {
      throw 'Active admin session not found. Please log in again.';
    }

    String? companyId;
    final adminProfile = await _supabase
        .from('profiles')
        .select('company_id')
        .eq('id', adminUser.id)
        .maybeSingle();
    companyId = adminProfile?['company_id']?.toString();

    if (kDebugMode) {
      print('🚀 [ClientRepo] Registering client: $cleanEmail under company:$companyId');
    }

    // 2. Create secondary client using global Supabase instance parameters
    final tempClient = SupabaseClient(
      SupabaseConfig.supabaseUrl,
      SupabaseConfig.supabaseAnonKey,
    );

    // 3. Register user natively with GoTrue
    final authResponse = await tempClient.auth.signUp(
      email: cleanEmail,
      password: cleanPassword,
      data: {
        'username': cleanName,
        'company_name': cleanCompany,
        'role': 'client',
        'contact_phone': cleanPhone,
      },
    );

    final createdUser = authResponse.user;
    if (createdUser == null) {
      throw 'Failed to register client account. Please verify email format or check if the account already exists.';
    }

    final newUserId = createdUser.id;
    if (kDebugMode) {
      print('✅ [ClientRepo] GoTrue user created cleanly. ID: $newUserId');
    }

    // 4. Save/Upsert profile record using main Admin client
    await _supabase.from('profiles').upsert({
      'id': newUserId,
      'email': cleanEmail,
      'username': cleanName,
      'role': 'client',
      'status': 'approved',
      'company_id': companyId,
      'company_name': cleanCompany,
      'contact_phone': cleanPhone,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    if (kDebugMode) {
      print('✅ [ClientRepo] Profile record created successfully for $cleanEmail');
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
