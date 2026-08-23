import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../data/client_repository.dart';

class ClientsListPage extends ConsumerStatefulWidget {
  const ClientsListPage({super.key});

  @override
  ConsumerState<ClientsListPage> createState() => _ClientsListPageState();
}

class _ClientsListPageState extends ConsumerState<ClientsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientProvider.notifier).loadClients();
    });
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _AddClientModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final clientState = ref.watch(clientProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isMobile
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF0284C7),
              onPressed: _showAddClientDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clients Management',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (!isMobile)
                      const Text(
                        'Manage client accounts and credential provisioning',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                      ),
                  ],
                ),
                if (!isMobile)
                  ElevatedButton.icon(
                    onPressed: _showAddClientDialog,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text(
                      'Add New Client',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar & Stats
            _buildSearchAndFilterBar(isMobile),
            const SizedBox(height: 14),

            // Body List or Table
            Expanded(
              child: clientState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                    )
                  : clientState.filteredClients.isEmpty
                      ? _buildEmptyState()
                      : (isMobile
                          ? _buildMobileClientCards(clientState.filteredClients)
                          : _buildDesktopClientTable(clientState.filteredClients)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(bool isMobile) {
    final notifier = ref.read(clientProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search clients by name, company, email or phone...',
          prefixIcon: Icon(Icons.search, color: AppColors.secondaryText),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (query) => notifier.setSearchQuery(query),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.business_center_outlined, size: 54, color: AppColors.secondaryText),
          const SizedBox(height: 14),
          const Text(
            'No clients registered yet',
            style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add client accounts to grant dedicated booking portal access.',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _showAddClientDialog,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('+ Add First Client'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileClientCards(List<Map<String, dynamic>> clients) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return ListView.separated(
      itemCount: clients.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = clients[index];
        final name = (c['name'] ?? c['client_name'] ?? c['full_name'] ?? 'Unnamed Client').toString();
        final company = (c['company'] ?? c['company_name'] ?? c['client_company'] ?? 'N/A').toString();
        final email = (c['email'] ?? c['client_email'] ?? '').toString();
        final phone = (c['phone'] ?? c['mobile'] ?? c['client_phone'] ?? 'N/A').toString();
        final createdAtRaw = c['created_at']?.toString();
        final createdStr = createdAtRaw != null
            ? (DateTime.tryParse(createdAtRaw) != null
                ? dateFormat.format(DateTime.parse(createdAtRaw))
                : '')
            : '';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1F2E45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.4)),
                    ),
                    child: const Text(
                      'CLIENT',
                      style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.business, size: 14, color: AppColors.secondaryText),
                  const SizedBox(width: 6),
                  Text(company, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 14, color: AppColors.secondaryText),
                  const SizedBox(width: 6),
                  Text(email, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.secondaryText),
                  const SizedBox(width: 6),
                  Text(phone, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                ],
              ),
              if (createdStr.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Registered: $createdStr', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopClientTable(List<Map<String, dynamic>> clients) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Builder(
        builder: (context) {
          final horizontalScrollController = ScrollController();
          final verticalScrollController = ScrollController();
          return Scrollbar(
            controller: verticalScrollController,
            thumbVisibility: true,
            child: Scrollbar(
              controller: horizontalScrollController,
              thumbVisibility: true,
              notificationPredicate: (notif) => notif.depth == 1,
              child: SingleChildScrollView(
                controller: verticalScrollController,
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  controller: horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 900),
                    child: DataTable(
                      horizontalMargin: 20,
                      columnSpacing: 28,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
                      columns: const [
                        DataColumn(label: Text('Client Name', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Company / Organization', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Email Address', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Contact Phone', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Role', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Registered Date', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                      ],
                      rows: clients.map((c) {
                        final name = (c['name'] ?? c['client_name'] ?? c['full_name'] ?? 'Unnamed Client').toString();
                        final company = (c['company'] ?? c['company_name'] ?? c['client_company'] ?? 'N/A').toString();
                        final email = (c['email'] ?? c['client_email'] ?? '').toString();
                        final phone = (c['phone'] ?? c['mobile'] ?? c['client_phone'] ?? 'N/A').toString();
                        final createdAtRaw = c['created_at']?.toString();
                        final createdStr = createdAtRaw != null
                            ? (DateTime.tryParse(createdAtRaw) != null
                                ? dateFormat.format(DateTime.parse(createdAtRaw))
                                : '—')
                            : '—';

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFF0284C7).withOpacity(0.2),
                                    child: Text(
                                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C',
                                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(company, style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w500, fontSize: 13)),
                            ),
                            DataCell(
                              Text(email, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                            ),
                            DataCell(
                              Text(phone, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.4)),
                                ),
                                child: const Text(
                                  'CLIENT',
                                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(createdStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        ),
      );
  }
}

class _AddClientModal extends ConsumerStatefulWidget {
  const _AddClientModal();

  @override
  ConsumerState<_AddClientModal> createState() => _AddClientModalState();
}

class _AddClientModalState extends ConsumerState<_AddClientModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;
  bool _sendWelcomeEmail = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await ref.read(clientProvider.notifier).createClient(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          company: _companyController.text,
          phone: _phoneController.text,
          sendWelcomeEmail: _sendWelcomeEmail,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _sendWelcomeEmail
                  ? 'Client account created! Welcome setup email sent.'
                  : 'Client account created successfully!',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        final err = ref.read(clientProvider).errorMessage ?? 'Failed to create client';
        setState(() => _errorMessage = err);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF131E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF38BDF8), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Add New Client Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1F2E45)),
              const SizedBox(height: 12),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Client Name
              _buildTextField(
                label: 'Client Name',
                controller: _nameController,
                icon: Icons.person_outline,
                hint: 'e.g. John Smith',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter client name' : null,
              ),
              const SizedBox(height: 12),

              // Company / Organization
              _buildTextField(
                label: 'Company / Organization',
                controller: _companyController,
                icon: Icons.business_outlined,
                hint: 'e.g. Acme Corporation',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter company name' : null,
              ),
              const SizedBox(height: 12),

              // Email
              _buildTextField(
                label: 'Email Address',
                controller: _emailController,
                icon: Icons.email_outlined,
                hint: 'client@company.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter email address';
                  if (!v.contains('@') || !v.contains('.')) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Password & Contact Phone row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Password',
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      hint: 'Min 6 characters',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter password';
                        if (v.trim().length < 6) return 'At least 6 chars';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Contact Phone',
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      hint: '+1 555-0199',
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter phone number' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Send Welcome Email Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1F2E45)),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Send Confirmation / Welcome Email',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Sends portal setup link to client\'s email address',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                  value: _sendWelcomeEmail,
                  activeThumbColor: const Color(0xFF38BDF8),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _sendWelcomeEmail = val),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF1F2E45)),
              const SizedBox(height: 12),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 18, color: Colors.white),
                    label: Text(
                      _isSubmitting ? 'Creating...' : 'Register Client',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1F2E45)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1F2E45)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF38BDF8)),
            ),
          ),
        ),
      ],
    );
  }
}
