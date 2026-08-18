import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/dashboard/presentation/admin_shell.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/bookings/presentation/bookings_list_page.dart';
import '../../features/bookings/presentation/create_booking_page.dart';
import '../../features/bookings/presentation/booking_details_page.dart';
import '../../features/drivers/presentation/drivers_page.dart';
import '../../features/drivers/presentation/add_driver_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/history/presentation/history_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/driver_portal/presentation/driver_trip_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/admin/dashboard',
    redirect: (context, state) {
      final path = state.uri.path;
      final fullUri = state.uri.toString();
      final matched = state.matchedLocation;
      final fragment = state.uri.fragment;
      final browserUrl = Uri.base.toString();

      // IF ACCESSING ANY DRIVER TRIP ROUTE -> NEVER REDIRECT
      if (path.contains('/trip') ||
          matched.contains('/trip') ||
          fullUri.contains('/trip') ||
          fragment.contains('/trip') ||
          browserUrl.contains('/trip')) {
        return null; // Do NOT redirect to login
      }

      final hasSession = Supabase.instance.client.auth.currentSession != null;
      final isLoggedIn = (authState.isAuthenticated && (authState.user?.isAdmin ?? false)) || hasSession;
      final isLoggingIn = path == '/login' || path == '/admin/login' || path == '/register';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/admin/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/trip/:token',
        name: 'driver-trip',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? state.uri.queryParameters['token'] ?? '';
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
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

