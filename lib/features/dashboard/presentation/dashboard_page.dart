import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/quick_action_card.dart';
import '../../../core/widgets/driver_status_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../bookings/data/booking_repository.dart';
import '../../bookings/domain/booking_model.dart';
import '../../drivers/data/driver_repository.dart';
import '../../notifications/data/notification_repository.dart';
import 'widgets/today_bookings_table.dart';
import '../presentation/widgets/reassign_driver_dialog.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final bookingState = ref.watch(bookingProvider);
    final driverState = ref.watch(driverProvider);
    final notifState = ref.watch(notificationProvider);

    final todayDateStr = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    // Calculate metrics
    final totalToday = bookingState.bookings.length;
    final inProgress = bookingState.bookings
        .where((b) =>
            b.status == BookingStatus.onTheWayToPickup ||
            b.status == BookingStatus.arrivedAtPickup ||
            b.status == BookingStatus.guestPickedUp ||
            b.status == BookingStatus.tripStarted)
        .length;
    final upcoming = bookingState.bookings
        .where((b) => b.status == BookingStatus.assigned || b.status == BookingStatus.confirmed)
        .length;
    final completed = bookingState.completedBookings.length;
    final unassigned = bookingState.bookings.where((b) => b.driverId == null).length;
    final cancelled = bookingState.cancelledBookings.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Welcome Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${authState.user?.name ?? "Admin"} 👋',
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.secondaryText),
                      const SizedBox(width: 6),
                      Text(
                        todayDateStr,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/admin/notifications'),
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined, color: AppColors.primaryText, size: 24),
                        if (notifState.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                              child: Text(
                                '${notifState.unreadCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.go('/admin/profile'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        authState.user?.name.substring(0, 1) ?? 'A',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Statistics Grid (Compact KPIs)
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                StatCard(
                  title: "Today's Bookings",
                  value: '$totalToday',
                  icon: Icons.calendar_today_outlined,
                  accentColor: const Color(0xFF38BDF8),
                ),
                StatCard(
                  title: "Upcoming",
                  value: '$upcoming',
                  icon: Icons.access_time,
                  accentColor: const Color(0xFFFBBF24),
                ),
                StatCard(
                  title: "In Progress",
                  value: '$inProgress',
                  icon: Icons.alt_route,
                  accentColor: const Color(0xFF818CF8),
                ),
                StatCard(
                  title: "Completed",
                  value: '$completed',
                  icon: Icons.check_circle_outline,
                  accentColor: const Color(0xFF34D399),
                ),
                StatCard(
                  title: "Unassigned",
                  value: '$unassigned',
                  icon: Icons.warning_amber_rounded,
                  accentColor: const Color(0xFFF87171),
                ),
                StatCard(
                  title: "Cancelled",
                  value: '$cancelled',
                  icon: Icons.cancel_outlined,
                  accentColor: const Color(0xFF94A3B8),
                ),
              ];

              if (constraints.maxWidth > 1100) {
                // Desktop: All 6 cards in a single sleek row
                return Row(
                  children: cards
                      .map((card) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: card,
                            ),
                          ))
                      .toList(),
                );
              } else {
                // Tablet / Mobile: 2 or 3 columns with high aspect ratio
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: constraints.maxWidth > 650 ? 3 : 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 3.2,
                  children: cards,
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Quick Action Cards Section
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              QuickActionCard(
                label: '+ Create Booking',
                icon: Icons.add_circle_outline,
                isPrimary: true,
                onTap: () => context.go('/admin/bookings/create'),
              ),
              QuickActionCard(
                label: 'Assign Driver',
                icon: Icons.person_add_outlined,
                onTap: () => context.go('/admin/bookings'),
              ),
              QuickActionCard(
                label: 'Add Driver & Vehicle',
                icon: Icons.person_add_alt_1_outlined,
                onTap: () => context.go('/admin/drivers/create'),
              ),

            ],
          ),
          const SizedBox(height: 32),

          // Main Layout Content: Today's Bookings Table + Live Driver Overview Side Panel
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1024) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Bookings Table (Flex 3)
                    Expanded(
                      flex: 3,
                      child: _buildBookingsSection(context, ref, bookingState),
                    ),
                    const SizedBox(width: 24),
                    // Live Driver Overview Panel (Flex 1)
                    Expanded(
                      flex: 1,
                      child: _buildLiveDriverOverview(context, driverState),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildBookingsSection(context, ref, bookingState),
                    const SizedBox(height: 24),
                    _buildLiveDriverOverview(context, driverState),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsSection(
    BuildContext context,
    WidgetRef ref,
    BookingState bookingState,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.today_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Today's Active Transfer Schedule",
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.go('/admin/bookings'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All Bookings'),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border),
          TodayBookingsTable(
            bookings: bookingState.todayBookings,
            onViewDetails: (id) => context.go('/admin/bookings/$id'),
            onReassignDriver: (id) {
              showDialog(
                context: context,
                builder: (context) => ReassignDriverDialog(bookingId: id),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDriverOverview(
    BuildContext context,
    DriverState driverState,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver Overview',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${driverState.activeDrivers.length} active drivers online',
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (driverState.drivers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No drivers registered yet.',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: driverState.drivers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final driver = driverState.drivers[index];
                return DriverStatusCard(
                  driverName: driver.name,
                  vehicleReg: driver.assignedVehicleReg ?? 'No vehicle assigned',
                  status: driver.status.name.toUpperCase(),
                  currentBookingId: driver.currentTripBookingId,
                );
              },
            ),
        ],
      ),
    );
  }
}
