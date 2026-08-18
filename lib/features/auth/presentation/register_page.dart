import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../tenant/data/tenant_provider.dart';
import '../../tenant/domain/company_model.dart';
import '../../tenant/domain/admin_profile_model.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _companyNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final companyName = _companyNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final client = Supabase.instance.client;

      // 1. SignUp user in Supabase Auth
      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'company_name': companyName,
          'username': username,
        },
      );

      final user = authResponse.user;
      final userId = user?.id ?? 'USR-${DateTime.now().millisecondsSinceEpoch}';

      String companyId = 'COMP-${DateTime.now().millisecondsSinceEpoch}';

      // 2. Defensive manual insert into public.companies (if trigger is missing)
      try {
        final companyRes = await client.from('companies').insert({
          'company_name': companyName,
        }).select().single();
        companyId = (companyRes['id'] ?? companyId).toString();
      } catch (_) {}

      // 3. Insert into public.profiles
      try {
        await client.from('profiles').insert({
          'id': userId,
          'company_id': companyId,
          'username': username,
          'email': email,
          'role': 'admin',
        });
      } catch (_) {}

      // 4. Update local Tenant state
      final company = CompanyModel(id: companyId, name: companyName);
      final profile = AdminProfileModel(
        id: userId,
        companyId: companyId,
        username: username,
        email: email,
        role: 'admin',
      );
      ref.read(tenantProvider.notifier).setTenant(company, profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Company "$companyName" registered successfully! Please log in.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed: ${e.toString().replaceAll('AuthException: ', '')}';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        color: AppColors.primary,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Register Your Company',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create your company workspace & admin credentials',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Error Message Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Company / Business Name Field
                  TextFormField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Company / Business Name *',
                      hintText: 'e.g. Royal Airport Transfers',
                      prefixIcon: Icon(Icons.business_outlined, color: AppColors.secondaryText),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your company / business name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Admin Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Admin Username *',
                      hintText: 'e.g. admin_ops',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.secondaryText),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an admin username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Address Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Admin Email Address *',
                      hintText: 'admin@company.com',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.secondaryText),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      hintText: 'At least 6 characters',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.secondaryText),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.secondaryText,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Register Company & Account',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Back to Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
