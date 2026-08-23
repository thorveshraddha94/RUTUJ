import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/admin_model.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/dashboard/presentation/admin_shell.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/bookings/presentation/bookings_list_page.dart';
import '../../features/bookings/presentation/create_booking_page.dart';
import '../../features/bookings/presentation/booking_details_page.dart';
import '../../features/drivers/presentation/drivers_page.dart';
import '../../features/drivers/presentation/add_driver_page.dart';
import '../../features/clients/presentation/clients_list_page.dart';
import '../../features/clients/presentation/client_dashboard_page.dart';
import '../../features/clients/presentation/client_request_booking_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/history/presentation/history_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/driver_portal/presentation/driver_trip_page.dart';
import '../../features/tenant/data/tenant_provider.dart';
import '../../features/superadmin/presentation/superadmin_dashboard_page.dart';
import '../../features/superadmin/presentation/pending_approval_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final tenantState = ref.watch(tenantProvider);

  return GoRouter(
    initialLocation: '/admin/dashboard',
    redirect: (context, state) {
      final path = state.uri.path;
      final fullPath = state.uri.toString();
      final browserUrl = Uri.base.toString();

      // CRITICAL: If the URL has "/trip", NEVER redirect to login
      if (path.contains('/trip') || fullPath.contains('/trip') || browserUrl.contains('/trip')) {
        return null; // Bypass all auth checks
      }

      if (authState.isLoading) {
        return null;
      }

      final currentUser = Supabase.instance.client.auth.currentUser;
      final hasSession = currentUser != null;
      final isLoggedIn =
          (authState.isAuthenticated && authState.user != null) || hasSession;
      final isLoginRoute =
          path == '/login' || path == '/admin/login' || path == '/register';
      final isPendingRoute = path == '/pending-approval';

      // 2. Not logged in -> Redirect to login page
      if (!isLoggedIn) {
        return isLoginRoute ? null : '/login';
      }

      // Check if logged-in user is Client role
      final isClientRole = authState.role == UserRole.client || (authState.user?.isClient ?? false);
      if (isClientRole) {
        if (isLoginRoute || !path.startsWith('/client')) {
          return '/client/dashboard';
        }
        return null;
      }

      // If non-client tries to access client portal
      if (path.startsWith('/client')) {
        return '/admin/dashboard';
      }

      // 3. Check for Superadmin role
      final email = (currentUser?.email ?? authState.user?.email ?? '')
          .trim()
          .toLowerCase();
      final isSuperAdmin =
          email == 'parthgajjar.bk@gmail.com' ||
          authState.role == UserRole.superadmin ||
          (authState.user?.isSuperAdmin ?? false) ||
          (tenantState.currentProfile?.isSuperAdmin ?? false);

      if (isSuperAdmin) {
        if (isLoginRoute || !path.startsWith('/superadmin')) {
          return '/superadmin/dashboard';
        }
        return null;
      }

      // 4. Regular Tenant Admin Status Check
      final profile = tenantState.currentProfile;
      bool isPending = false;
      bool isSuspended = false;

      if (profile != null) {
        isPending = profile.isPending;
        isSuspended = profile.isSuspended;
      } else {
        isPending = authState.status == UserStatus.pending;
        isSuspended = authState.status == UserStatus.suspended;
      }

      if (isPending || isSuspended) {
        return isPendingRoute ? null : '/pending-approval';
      }

      // Approved Tenant Admin
      if (isLoginRoute ||
          isPendingRoute ||
          path == '/' ||
          path == '/superadmin/dashboard') {
        return '/admin/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/superadmin/dashboard',
        builder: (context, state) => const SuperadminDashboardPage(),
      ),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalPage(),
      ),
      GoRoute(
        path: '/client/dashboard',
        builder: (context, state) => const ClientDashboardPage(),
      ),
      GoRoute(
        path: '/client/request-booking',
        builder: (context, state) => const ClientRequestBookingPage(),
      ),
      GoRoute(
        path: '/trip/:token',
        name: 'driver-trip',
        builder: (context, state) {
          final token =
              state.pathParameters['token'] ??
              state.uri.queryParameters['token'] ??
              '';
          return DriverTripPage(token: token);
        },
      ),
      GoRoute(
        path: '/trip',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return DriverTripPage(token: token);
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/admin/bookings',
            builder: (context, state) => const BookingsListPage(),
          ),
          GoRoute(
            path: '/admin/bookings/create',
            builder: (context, state) => const CreateBookingPage(),
          ),
          GoRoute(
            path: '/admin/bookings/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return BookingDetailsPage(bookingId: id);
            },
          ),
          GoRoute(
            path: '/admin/drivers',
            builder: (context, state) => const DriversPage(),
          ),
          GoRoute(
            path: '/admin/drivers/create',
            builder: (context, state) => const AddDriverPage(),
          ),
          GoRoute(
            path: '/admin/drivers/:id',
            builder: (context, state) => const DriversPage(),
          ),
          GoRoute(
            path: '/admin/clients',
            builder: (context, state) => const ClientsListPage(),
          ),
          GoRoute(
            path: '/admin/notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/admin/history',
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: '/admin/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
});
