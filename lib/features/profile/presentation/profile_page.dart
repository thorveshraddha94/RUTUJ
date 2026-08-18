import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/data/auth_repository.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.name.substring(0, 1) ?? 'A',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Admin User',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: const Text(
                          'SYSTEM ADMINISTRATOR',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Divider(color: AppColors.border),
              const SizedBox(height: 24),

              // Details List
              const Text('Account Information', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),

              _profileRow('Admin ID', user?.id ?? 'ADM-001'),
              const SizedBox(height: 12),
              _profileRow('Username', '@${user?.username ?? "admin"}'),
              const SizedBox(height: 12),
              _profileRow('Email Address', user?.email ?? ''),
              const SizedBox(height: 12),
              _profileRow('Access Control Role', 'ADMINISTRATOR (Full Control)'),
              const SizedBox(height: 28),
              const Divider(color: AppColors.border),
              const SizedBox(height: 24),

              // Actions Section
              const Text('Security & Session', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change Password dialog initiated.'), backgroundColor: AppColors.primary),
                  );
                },
                icon: const Icon(Icons.lock_reset, size: 18),
                label: const Text('Change Admin Password'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              ),
              const SizedBox(height: 14),

              ElevatedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign Out of Admin Portal', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
