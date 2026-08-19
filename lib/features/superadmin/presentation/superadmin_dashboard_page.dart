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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(superadminNotifierProvider.notifier).loadAdmins();
    });
  }

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
          'Are you sure you want to permanently delete user "${admin.username}" (${admin.email}) from workspace "${admin.companyName}"?\n\nThis will trigger the delete_admin_user RPC function.',
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
                  // SLIM COMPACT KPI STAT CARDS ROW (height 72px)
                  _buildStatsRow(
                    state.admins,
                    filterStatus: state.filterStatus,
                    onSelectFilter: (status) => notifier.setFilterStatus(status),
                  ),
                  const SizedBox(height: 24),

                  // FULL-WIDTH RESPONSIVE TENANT ADMIN DIRECTORY TABLE CARD
                  _buildTenantTableCard(state.filteredAdmins),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SLIM COMPACT KPI STAT CARD (height ~72px)
  Widget _buildCompactStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131E2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF1F2E45),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    List<AdminProfileModel> admins, {
    required String filterStatus,
    required Function(String) onSelectFilter,
  }) {
    final tenantAdmins = admins.where((a) => !a.isSuperAdmin).toList();
    final totalWorkspaces = tenantAdmins.length;
    final pending = tenantAdmins.where((a) => a.status == 'pending').length;
    final active = tenantAdmins.where((a) => a.status == 'approved').length;
    final suspended = tenantAdmins.where((a) => a.status == 'suspended').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          final cardWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: cardWidth,
                child: _buildCompactStatCard(
                  title: 'Total Workspaces',
                  count: '$totalWorkspaces',
                  icon: Icons.business,
                  color: const Color(0xFF38BDF8),
                  isSelected: filterStatus == 'all',
                  onTap: () => onSelectFilter('all'),
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _buildCompactStatCard(
                  title: 'Pending Approvals',
                  count: '$pending',
                  icon: Icons.pending_actions,
                  color: const Color(0xFFFBBF24),
                  isSelected: filterStatus == 'pending',
                  onTap: () => onSelectFilter('pending'),
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _buildCompactStatCard(
                  title: 'Active / Approved',
                  count: '$active',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF34D399),
                  isSelected: filterStatus == 'approved',
                  onTap: () => onSelectFilter('approved'),
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _buildCompactStatCard(
                  title: 'Suspended',
                  count: '$suspended',
                  icon: Icons.pause_circle_outline,
                  color: const Color(0xFFF87171),
                  isSelected: filterStatus == 'suspended',
                  onTap: () => onSelectFilter('suspended'),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildCompactStatCard(
                title: 'Total Workspaces',
                count: '$totalWorkspaces',
                icon: Icons.business,
                color: const Color(0xFF38BDF8),
                isSelected: filterStatus == 'all',
                onTap: () => onSelectFilter('all'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactStatCard(
                title: 'Pending Approvals',
                count: '$pending',
                icon: Icons.pending_actions,
                color: const Color(0xFFFBBF24),
                isSelected: filterStatus == 'pending',
                onTap: () => onSelectFilter('pending'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactStatCard(
                title: 'Active / Approved',
                count: '$active',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF34D399),
                isSelected: filterStatus == 'approved',
                onTap: () => onSelectFilter('approved'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactStatCard(
                title: 'Suspended',
                count: '$suspended',
                icon: Icons.pause_circle_outline,
                color: const Color(0xFFF87171),
                isSelected: filterStatus == 'suspended',
                onTap: () => onSelectFilter('suspended'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTenantTableCard(List<AdminProfileModel> admins) {
    final notifier = ref.read(superadminProvider.notifier);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2E45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header + Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tenant Admin Directory',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 280,
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => notifier.setSearchQuery(val),
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search username, company, email...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1F2E45)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1F2E45)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1F2E45)),

          // Table Content
          admins.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: Text('No tenant admins found.', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth < 900 ? 900 : constraints.maxWidth),
                        child: DataTable(
                          horizontalMargin: 20,
                          columnSpacing: 28,
                          headingRowColor: WidgetStateProperty.all(const Color(0xFF0B132B)),
                          columns: const [
                            DataColumn(label: Text('Username / Email', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Company Name', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Contact Phone', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Status', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Joined Date', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Actions', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
                          ],
                          rows: admins.map((admin) => _buildAdminDataRow(admin)).toList(),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  DataRow _buildAdminDataRow(AdminProfileModel admin) {
    final dateStr = DateFormat('MMM dd, yyyy').format(admin.createdAt);
    final notifier = ref.read(superadminProvider.notifier);

    return DataRow(
      cells: [
        // Username / Email
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondarySurface,
                child: Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    admin.username,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (admin.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      admin.email,
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
            admin.companyName,
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
            admin.phone,
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
          Row(
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
  }
}
