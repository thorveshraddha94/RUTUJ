import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../auth/data/auth_repository.dart';
import '../../notifications/data/notification_repository.dart';
import '../../tenant/data/tenant_provider.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final notificationState = ref.watch(notificationProvider);
    final tenantState = ref.watch(tenantProvider);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    final companyName = tenantState.currentCompany?.name ?? 'Airport Operations Portal';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveLayout(
        desktop: _buildDesktopLayout(context, ref, authState, notificationState, currentLocation, companyName),
        mobile: _buildMobileLayout(context, ref, authState, notificationState, currentLocation, companyName),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
    NotificationState notificationState,
    String currentLocation,
    String companyName,
  ) {
    return Row(
      children: [
        // Sidebar Navigation
        Container(
          width: 250,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(right: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_airport_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Admin Operations Portal',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: 10),

              // Navigation Links
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _sidebarItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard,
                      label: 'Dashboard',
                      route: '/admin/dashboard',
                      currentRoute: currentLocation,
                    ),
                    _sidebarItem(
                      context,
                      icon: Icons.book_online_outlined,
                      activeIcon: Icons.book_online,
                      label: 'Bookings',
                      route: '/admin/bookings',
                      currentRoute: currentLocation,
                    ),
                    _sidebarItem(
                      context,
                      icon: Icons.people_outline,
                      activeIcon: Icons.people,
                      label: 'Drivers & Fleet',
                      route: '/admin/drivers',
                      currentRoute: currentLocation,
                    ),
                    _sidebarItem(
                      context,
                      icon: Icons.business_center_outlined,
                      activeIcon: Icons.business_center,
                      label: 'Clients',
                      route: '/admin/clients',
                      currentRoute: currentLocation,
                    ),
                    _sidebarItem(
                      context,
                      icon: Icons.notifications_outlined,
                      activeIcon: Icons.notifications,
                      label: 'Notifications',
                      route: '/admin/notifications',
                      currentRoute: currentLocation,
                      badgeCount: notificationState.unreadCount,
                    ),
                    _sidebarItem(
                      context,
                      icon: Icons.history_outlined,
                      activeIcon: Icons.history,
                      label: 'History',
                      route: '/admin/history',
                      currentRoute: currentLocation,
                    ),
                    _sidebarItem(
                      context,
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart,
                      label: 'Reports',
                      route: '/admin/reports',
                      currentRoute: currentLocation,
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.border),

              // Admin User Profile Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => context.go('/admin/profile'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: currentLocation == '/admin/profile'
                              ? AppColors.secondarySurface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                authState.user?.name.substring(0, 1) ?? 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authState.user?.name ?? 'Admin User',
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    authState.user?.email ?? '',
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      },
                      icon: const Icon(Icons.logout, size: 16, color: AppColors.danger),
                      label: const Text(
                        'Logout',
                        style: TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger, width: 0.8),
                        minimumSize: const Size.fromHeight(36),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main Page Content Area
        Expanded(
          child: child,
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
    NotificationState notificationState,
    String currentLocation,
    String companyName,
  ) {
    int selectedIndex = 0;
    if (currentLocation.startsWith('/admin/dashboard')) selectedIndex = 0;
    if (currentLocation.startsWith('/admin/bookings')) selectedIndex = 1;
    if (currentLocation.startsWith('/admin/drivers')) selectedIndex = 2;
    if (currentLocation.startsWith('/admin/notifications')) selectedIndex = 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.local_airport, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              _getPageTitle(currentLocation),
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.primaryText),
                if (notificationState.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '${notificationState.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.go('/admin/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger, size: 20),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.primaryText),
            onPressed: () => _showMobileMenuDrawer(context, ref, currentLocation),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex > 3 ? 3 : selectedIndex,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.secondaryText,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/admin/dashboard');
                break;
              case 1:
                context.go('/admin/bookings');
                break;
              case 2:
                context.go('/admin/drivers');
                break;
              case 3:
                context.go('/admin/notifications');
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_online_outlined),
              activeIcon: Icon(Icons.book_online),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Drivers & Fleet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Notifs',
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileMenuDrawer(BuildContext context, WidgetRef ref, String currentRoute) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.business_center, color: AppColors.primary),
                title: const Text('Clients', style: TextStyle(color: AppColors.primaryText)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin/clients');
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: AppColors.primary),
                title: const Text('History', style: TextStyle(color: AppColors.primaryText)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin/history');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart, color: AppColors.primary),
                title: const Text('Reports', style: TextStyle(color: AppColors.primaryText)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin/reports');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: AppColors.primary),
                title: const Text('Profile', style: TextStyle(color: AppColors.primaryText)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin/profile');
                },
              ),

              const Divider(color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text('Logout', style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sidebarItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    required String currentRoute,
    int badgeCount = 0,
  }) {
    final isActive = currentRoute == route || currentRoute.startsWith('$route/');

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.primary : AppColors.secondaryText,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? AppColors.primaryText : AppColors.secondaryText,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPageTitle(String route) {
    if (route.contains('/dashboard')) return 'Dashboard';
    if (route.contains('/bookings/create')) return 'Create Booking';
    if (route.contains('/bookings')) return 'Bookings';
    if (route.contains('/drivers')) return 'Drivers & Fleet';
    if (route.contains('/clients')) return 'Clients';
    if (route.contains('/notifications')) return 'Notifications';
    if (route.contains('/history')) return 'History';
    if (route.contains('/reports')) return 'Reports';
    if (route.contains('/profile')) return 'Profile';
    return 'Airport Admin';
  }

}
