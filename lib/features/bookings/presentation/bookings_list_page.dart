import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/booking_repository.dart';
import '../domain/booking_model.dart';
import '../../dashboard/presentation/widgets/reassign_driver_dialog.dart';
import 'cancel_booking_dialog.dart';

class BookingsListPage extends ConsumerWidget {
  const BookingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingProvider);
    final notifier = ref.read(bookingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rutuj Tours & Travels Bookings',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage all airport pickup and drop assignments',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/admin/bookings/create'),
                icon: const Icon(Icons.add),
                label: const Text('+ Create Booking', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search & Filter Toolbar Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by Booking ID, Guest, Client, Driver or Flight...',
                      prefixIcon: Icon(Icons.search, color: AppColors.secondaryText),
                    ),
                    onChanged: (query) => notifier.setSearchQuery(query),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<BookingStatus?>(
                  value: bookingState.statusFilter,
                  dropdownColor: AppColors.secondarySurface,
                  hint: const Text('Filter Status', style: TextStyle(color: AppColors.secondaryText)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Statuses')),
                    ...BookingStatus.values.map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      ),
                    ),
                  ],
                  onChanged: (status) => notifier.setStatusFilter(status),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bookings Table
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: bookingState.filteredBookings.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No bookings match the selected criteria.',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.secondarySurface),
                      columns: const [
                        DataColumn(label: Text('Booking ID', style: _headerStyle)),
                        DataColumn(label: Text('Guest Name', style: _headerStyle)),
                        DataColumn(label: Text('Flight & Terminal', style: _headerStyle)),
                        DataColumn(label: Text('Pickup Time', style: _headerStyle)),
                        DataColumn(label: Text('Pickup Location', style: _headerStyle)),
                        DataColumn(label: Text('Destination', style: _headerStyle)),
                        DataColumn(label: Text('Driver', style: _headerStyle)),
                        DataColumn(label: Text('Status', style: _headerStyle)),
                        DataColumn(label: Text('Actions', style: _headerStyle)),
                      ],
                      rows: bookingState.filteredBookings.map((b) {
                        return DataRow(
                          cells: [
                            DataCell(
                              InkWell(
                                onTap: () => context.go('/admin/bookings/${b.id}'),
                                child: Text(
                                  b.id,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.guestName, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600)),
                                  Text(b.clientName, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                                ],
                              ),
                            ),
                            DataCell(Text('${b.flightNumber} (${b.terminal})', style: const TextStyle(color: AppColors.primaryText))),
                            DataCell(Text('${b.pickupDate}\n${b.pickupTime}', style: const TextStyle(color: AppColors.primaryText, fontSize: 12))),
                            DataCell(
                              Container(
                                constraints: const BoxConstraints(maxWidth: 150),
                                child: Text(b.pickupLocation, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                            DataCell(
                              Container(
                                constraints: const BoxConstraints(maxWidth: 150),
                                child: Text(b.destination, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                            DataCell(Text(b.driverName ?? 'Unassigned', style: TextStyle(color: b.driverName != null ? AppColors.primaryText : AppColors.danger))),
                            DataCell(StatusBadge(status: b.status.displayName)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                                    onPressed: () => context.go('/admin/bookings/${b.id}'),
                                    tooltip: 'View Booking',
                                  ),
                                  if (b.status != BookingStatus.cancelled && b.status != BookingStatus.completed) ...[
                                    IconButton(
                                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 18, color: AppColors.warning),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => ReassignDriverDialog(bookingId: b.id),
                                        );
                                      },
                                      tooltip: 'Reassign Driver',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.danger),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => CancelBookingDialog(bookingId: b.id),
                                        );
                                      },
                                      tooltip: 'Cancel Booking',
                                    ),
                                  ],
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
    );
  }

  static const _headerStyle = TextStyle(
    color: AppColors.secondaryText,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );
}
