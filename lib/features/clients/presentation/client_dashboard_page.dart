import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/data/auth_repository.dart';
import '../../bookings/data/booking_repository.dart';
import '../../bookings/domain/booking_model.dart';

class ClientDashboardPage extends ConsumerStatefulWidget {
  const ClientDashboardPage({super.key});

  @override
  ConsumerState<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends ConsumerState<ClientDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bookingState = ref.watch(bookingProvider);
    final isMobile = ResponsiveLayout.isMobile(context);
    final currentUser = Supabase.instance.client.auth.currentUser;

    // Filter bookings relevant to this client (by client_id or user email/name)
    final clientBookings = bookingState.bookings.where((b) {
      if (currentUser == null) return true;
      final json = b.toSupabase();
      final cid = json['client_id']?.toString() ?? json['clientId']?.toString();
      if (cid == currentUser.id) return true;
      final bookedBy = b.bookedByName?.toLowerCase().trim() ?? '';
      final userEmail = currentUser.email?.toLowerCase().trim() ?? '';
      final userName = authState.user?.name.toLowerCase().trim() ?? '';
      return bookedBy.contains(userName) || bookedBy.contains(userEmail) || cid == currentUser.id;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_airport, color: Color(0xFF38BDF8), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.user?.name ?? 'Client Portal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Corporate Client Transfer Portal',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              icon: const Icon(Icons.logout, size: 16, color: AppColors.danger),
              label: const Text('Logout', style: TextStyle(color: AppColors.danger, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger, width: 0.8),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Welcome & Action Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${authState.user?.name ?? "Valued Client"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Request new airport transfers and track driver dispatch status in real-time.',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/client/request-booking'),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text(
                      'Request Booking',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 20,
                        vertical: isMobile ? 12 : 16,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Transfer Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8)),
                  onPressed: () => ref.read(bookingProvider.notifier).fetchBookings(),
                  tooltip: 'Refresh Requests',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Requests List or Empty State
            Expanded(
              child: bookingState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                  : clientBookings.isEmpty
                      ? _buildEmptyState(context)
                      : (isMobile
                          ? _buildMobileCards(clientBookings)
                          : _buildDesktopTable(clientBookings)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
          const Icon(Icons.local_taxi_outlined, size: 54, color: AppColors.secondaryText),
          const SizedBox(height: 14),
          const Text(
            'No booking requests submitted yet',
            style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Submit your first transfer request to notify operations team instantly.',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => context.go('/client/request-booking'),
            icon: const Icon(Icons.add),
            label: const Text('+ Submit Transfer Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCards(List<BookingModel> bookings) {
    return ListView.separated(
      itemCount: bookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = bookings[index];
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
                  Text(
                    b.displayCode,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  StatusBadge(status: b.status.displayName),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Passenger: ${b.passengerName} (${b.passengerPhone})',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                '📍 ${b.pickupLocation} ➔ 🏁 ${b.dropoffLocation}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                '⏰ Date/Time: ${b.pickupDate} at ${b.pickupTime}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                '👥 Pax: ${b.passengersCount} | 🧳 Luggage: ${b.luggageCount}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              if (b.driverName != null) ...[
                const Divider(color: Color(0xFF1F2E45), height: 16),
                Text(
                  '👨‍✈️ Driver: ${b.driverName} (${b.driverPhone ?? ""})',
                  style: const TextStyle(color: Color(0xFF32C48D), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                if (b.vehicleType != null)
                  Text(
                    '🚗 Vehicle: ${b.vehicleType} (${b.vehicleRegistration ?? ""})',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(List<BookingModel> bookings) {
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
                    constraints: const BoxConstraints(minWidth: 950),
                    child: DataTable(
                      horizontalMargin: 20,
                      columnSpacing: 24,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
                      columns: const [
                        DataColumn(label: Text('Ref Code / Passenger', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Route Details', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Pickup Date & Time', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Pax & Bags', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Assigned Driver / Vehicle', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                      ],
                      rows: bookings.map((b) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(b.displayCode, style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(b.passengerName, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  if (b.passengerPhone.isNotEmpty)
                                    Text(b.passengerPhone, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                                ],
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('📍 ${b.pickupLocation}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  Text('🏁 ${b.dropoffLocation}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                ],
                              ),
                            ),
                            DataCell(
                              Text('${b.pickupDate} at ${b.pickupTime}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                            DataCell(
                              Text('${b.passengersCount} Pax / ${b.luggageCount} Bags', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ),
                            DataCell(
                              b.driverName != null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('👨‍✈️ ${b.driverName}', style: const TextStyle(color: Color(0xFF32C48D), fontWeight: FontWeight.w600, fontSize: 12)),
                                        if (b.vehicleType != null)
                                          Text('${b.vehicleType} (${b.vehicleRegistration ?? ""})', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                                      ],
                                    )
                                  : const Text('Pending Operations', style: TextStyle(color: Color(0xFFF5B942), fontSize: 12, fontStyle: FontStyle.italic)),
                            ),
                            DataCell(
                              StatusBadge(status: b.status.displayName),
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
