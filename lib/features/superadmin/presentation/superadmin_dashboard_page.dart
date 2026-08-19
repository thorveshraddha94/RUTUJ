import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/data/auth_repository.dart';
import '../../tenant/domain/admin_profile_model.dart';
import '../data/superadmin_provider.dart';

class SuperadminDashboardPage extends ConsumerStatefulWidget {
  const SuperadminDashboardPage({super.key});

  @override
  ConsumerState<SuperadminDashboardPage> createState() => _SuperadminDashboardPageState();
}

class _SuperadminDashboardPageState extends ConsumerState<SuperadminDashboardPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, AdminProfileModel admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
            SizedBox(width: 10),
            Text(
              'Delete Admin User',
              style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete user "${admin.username}" (${admin.email ?? 'No Email'}) from workspace "${admin.companyName}"?\n\nThis will trigger the delete_admin_user RPC function.',
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              final success = await ref.read(superadminProvider.notifier).deleteAdmin(admin.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Admin user deleted successfully.' : 'Failed to delete admin user.'),
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Admin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superadminProvider);
    final notifier = ref.read(superadminProvider.notifier);

    // Get active user email
    final currentUser = Supabase.instance.client.auth.currentUser;
    final displayEmail = currentUser?.email ?? 'parthgajjar.bk@gmail.com';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // TOP BAR: Logged in as parthgajjar.bk@gmail.com (Superadmin) with Logout button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // Logo / Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Superadmin Master Portal',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text(
                            'Logged in as ',
                            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                          ),
                          Text(
                            '$displayEmail (Superadmin)',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Refresh button
                  IconButton(
                    tooltip: 'Refresh Data',
                    icon: state.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.refresh_rounded, color: AppColors.secondaryText),
                    onPressed: () => notifier.loadAdmins(),
                  ),
                  const SizedBox(width: 12),
                  // Logout button
                  ElevatedButton.icon(
                    onPressed: () async {
                      ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                      foregroundColor: AppColors.danger,
                      elevation: 0,
                      side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),

          // MAIN DASHBOARD CONTENT AREA
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STAT SUMMARY CARDS: Total Workspaces, Pending Approvals, Active/Approved, Suspended
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 700;
                      final cardWidth = isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildStatCard(
                            width: cardWidth,
                            title: 'Total Workspaces',
                            count: state.totalWorkspaces,
                            icon: Icons.business_rounded,
                            iconColor: AppColors.primary,
                            isSelected: state.filterStatus == 'all',
                            onTap: () => notifier.setFilterStatus('all'),
                          ),
                          _buildStatCard(
                            width: cardWidth,
                            title: 'Pending Approvals',
                            count: state.pendingApprovals,
                            icon: Icons.pending_actions_rounded,
                            iconColor: AppColors.warning,
                            isSelected: state.filterStatus == 'pending',
                            onTap: () => notifier.setFilterStatus('pending'),
                          ),
                          _buildStatCard(
                            width: cardWidth,
                            title: 'Active / Approved',
                            count: state.activeApproved,
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: AppColors.success,
                            isSelected: state.filterStatus == 'approved',
                            onTap: () => notifier.setFilterStatus('approved'),
                          ),
                          _buildStatCard(
                            width: cardWidth,
                            title: 'Suspended',
                            count: state.suspended,
                            icon: Icons.pause_circle_outline_rounded,
                            iconColor: AppColors.danger,
                            isSelected: state.filterStatus == 'suspended',
                            onTap: () => notifier.setFilterStatus('suspended'),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // FILTER & SEARCH TOOLBAR
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Tenant Admin Directory',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            // Search input
                            SizedBox(
                              width: 280,
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => notifier.setSearchQuery(val),
                                decoration: InputDecoration(
                                  hintText: 'Search username, company, email...',
                                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.secondaryText),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 16),
                                          onPressed: () {
                                            _searchController.clear();
                                            notifier.setSearchQuery('');
                                          },
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ADMINS DATA TABLE
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: state.filteredAdmins.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.search_off_rounded, size: 48, color: AppColors.secondaryText),
                                SizedBox(height: 12),
                                Text(
                                  'No admin accounts match your criteria',
                                  style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 52,
                              dataRowMaxHeight: 64,
                              horizontalMargin: 20,
                              columnSpacing: 24,
                              headingRowColor: WidgetStateProperty.all(AppColors.secondarySurface),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Username / Email',
                                    style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Company Name',
                                    style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Contact Phone',
                                    style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Status',
                                    style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Joined Date',
                                    style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Actions',
                                    style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                              rows: state.filteredAdmins.map((admin) {
                                final isSuperAdminAccount = admin.isSuperAdmin;
                                final dateStr = admin.createdAt != null
                                    ? DateFormat('MMM dd, yyyy').format(admin.createdAt!)
                                    : 'Recent';

                                return DataRow(
                                  cells: [
                                    // Username / Email
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: isSuperAdminAccount
                                                ? AppColors.primary.withValues(alpha: 0.2)
                                                : AppColors.secondarySurface,
                                            child: Icon(
                                              isSuperAdminAccount ? Icons.star_rounded : Icons.person_rounded,
                                              size: 18,
                                              color: isSuperAdminAccount ? AppColors.primary : AppColors.secondaryText,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    admin.username,
                                                    style: const TextStyle(
                                                      color: AppColors.primaryText,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  if (isSuperAdminAccount) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text(
                                                        'SUPERADMIN',
                                                        style: TextStyle(
                                                          color: AppColors.primary,
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (admin.email != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  admin.email!,
                                                  style: const TextStyle(
                                                    color: AppColors.secondaryText,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Company Name
                                    DataCell(
                                      Text(
                                        admin.companyName ?? 'N/A',
                                        style: const TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    // Contact Phone
                                    DataCell(
                                      Text(
                                        admin.phone ?? 'N/A',
                                        style: const TextStyle(
                                          color: AppColors.secondaryText,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    // Status Badge
                                    DataCell(
                                      StatusBadge(status: admin.status.toUpperCase()),
                                    ),
                                    // Joined Date
                                    DataCell(
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          color: AppColors.secondaryText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    // Actions: Approve (✓), Suspend (⏸), Delete (🗑️)
                                    DataCell(
                                      isSuperAdminAccount
                                          ? const Text(
                                              'System Superadmin',
                                              style: TextStyle(
                                                color: AppColors.secondaryText,
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Approve Button (✓)
                                                IconButton(
                                                  tooltip: 'Approve (✓)',
                                                  icon: Icon(
                                                    Icons.check_circle_rounded,
                                                    color: admin.isApproved
                                                        ? AppColors.secondaryText.withValues(alpha: 0.3)
                                                        : AppColors.success,
                                                    size: 22,
                                                  ),
                                                  onPressed: admin.isApproved
                                                      ? null
                                                      : () async {
                                                          final messenger = ScaffoldMessenger.of(context);
                                                          final ok = await notifier.approveAdmin(admin.id);
                                                          if (mounted && ok) {
                                                            messenger.showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                    'Admin "${admin.username}" status set to APPROVED.'),
                                                                backgroundColor: AppColors.success,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                ),
                                                // Suspend Button (⏸)
                                                IconButton(
                                                  tooltip: 'Suspend (⏸)',
                                                  icon: Icon(
                                                    Icons.pause_circle_rounded,
                                                    color: admin.isSuspended
                                                        ? AppColors.secondaryText.withValues(alpha: 0.3)
                                                        : AppColors.warning,
                                                    size: 22,
                                                  ),
                                                  onPressed: admin.isSuspended
                                                      ? null
                                                      : () async {
                                                          final messenger = ScaffoldMessenger.of(context);
                                                          final ok = await notifier.suspendAdmin(admin.id);
                                                          if (mounted && ok) {
                                                            messenger.showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                    'Admin "${admin.username}" status set to SUSPENDED.'),
                                                                backgroundColor: AppColors.warning,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                ),
                                                // Delete Button (🗑️)
                                                IconButton(
                                                  tooltip: 'Delete (🗑️)',
                                                  icon: const Icon(
                                                    Icons.delete_outline_rounded,
                                                    color: AppColors.danger,
                                                    size: 22,
                                                  ),
                                                  onPressed: () => _confirmDelete(context, admin),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required double width,
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? iconColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? iconColor.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$count',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
