import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/booking_repository.dart';
import '../domain/booking_model.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../tenant/data/tenant_provider.dart';
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
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.airport_shuttle_outlined, size: 54, color: AppColors.secondaryText),
                        const SizedBox(height: 14),
                        const Text(
                          'No bookings found',
                          style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create a new airport transfer booking to populate your operations schedule.',
                          style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/admin/bookings/create'),
                          icon: const Icon(Icons.add),
                          label: const Text('+ Create First Booking'),
                        ),
                      ],
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
                                  if (b.driverName != null && b.driverMobile != null)
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.success),
                                      onPressed: () {
                                        final companyName = ref.read(tenantProvider).currentCompany?.name ?? 'Airport Operations';
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            title: Row(
                                              children: [
                                                const Icon(Icons.chat, color: AppColors.success, size: 24),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'WhatsApp Dispatch — ${b.id}',
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            content: const Text(
                                              'Select recipient to dispatch WhatsApp transfer details:',
                                              style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                                            ),
                                            actions: [
                                               OutlinedButton.icon(
                                                 onPressed: () {
                                                   Navigator.of(dialogContext).pop();
                                                   WhatsAppService.sendTripAssignmentToDriver(
                                                     driverPhone: b.driverMobile!,
                                                     driverName: b.driverName!,
                                                     companyName: companyName,
                                                     guestName: b.guestName,
                                                     guestPhone: b.guestMobile,
                                                     flightNumber: b.flightNumber,
                                                     pickupLocation: b.pickupLocation,
                                                     dropoffLocation: b.destination,
                                                     scheduledTime: '${b.pickupDate} at ${b.pickupTime}',
                                                     passengersCount: b.passengersCount,
                                                     luggageCount: b.luggageCount,
                                                     specialAssistance: b.specialAssistance,
                                                   );
                                                 },
                                                 icon: const Icon(Icons.badge, size: 16),
                                                 label: Text('Driver (${b.driverName})'),
                                               ),
                                               OutlinedButton.icon(
                                                 style: OutlinedButton.styleFrom(
                                                   foregroundColor: AppColors.success,
                                                   side: const BorderSide(color: AppColors.success),
                                                 ),
                                                 onPressed: () {
                                                   Navigator.of(dialogContext).pop();
                                                   WhatsAppService.sendDriverDetailsToClient(
                                                     clientPhone: b.guestMobile,
                                                     clientName: b.guestName,
                                                     companyName: companyName,
                                                     pickupLocation: b.pickupLocation,
                                                     dropoffLocation: b.destination,
                                                     pickupTime: '${b.pickupDate} at ${b.pickupTime}',
                                                     driverName: b.driverName!,
                                                     driverPhone: b.driverMobile!,
                                                     vehicleModel: b.vehicleType ?? 'Assigned Vehicle',
                                                     plateNumber: b.vehicleRegistration ?? 'N/A',
                                                   );
                                                 },
                                                 icon: const Icon(Icons.person, size: 16),
                                                 label: Text('Guest (${b.guestName})'),
                                               ),
                                               ElevatedButton.icon(
                                                 style: ElevatedButton.styleFrom(
                                                   backgroundColor: AppColors.success,
                                                   foregroundColor: Colors.white,
                                                 ),
                                                 onPressed: () {
                                                   Navigator.of(dialogContext).pop();
                                                   WhatsAppService.sendToBoth(
                                                     guestPhone: b.guestMobile,
                                                     guestName: b.guestName,
                                                     companyName: companyName,
                                                     pickupTime: '${b.pickupDate} at ${b.pickupTime}',
                                                     pickupLocation: b.pickupLocation,
                                                     dropoffLocation: b.destination,
                                                     driverPhone: b.driverMobile!,
                                                     driverName: b.driverName!,
                                                     vehicleModel: b.vehicleType ?? 'Assigned Vehicle',
                                                     plateNumber: b.vehicleRegistration ?? 'N/A',
                                                     flightNumber: b.flightNumber,
                                                     passengers: b.passengersCount,
                                                     notes: b.specialAssistance,
                                                   );
                                                 },
                                                 icon: const Icon(Icons.people_alt, size: 16),
                                                 label: const Text('👥 Send to Both'),
                                               ),
                                             ],
                                          ),
                                        );
                                      },
                                      tooltip: 'Send WhatsApp Details',
                                    ),
                                  if (b.status != BookingStatus.cancelled && b.status != BookingStatus.completed) ...[
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
