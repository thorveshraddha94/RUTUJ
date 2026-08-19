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
import 'edit_booking_dialog.dart';

class BookingsListPage extends ConsumerStatefulWidget {
  const BookingsListPage({super.key});

  @override
  ConsumerState<BookingsListPage> createState() => _BookingsListPageState();
}

class _BookingsListPageState extends ConsumerState<BookingsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                : Builder(
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
                                constraints: const BoxConstraints(minWidth: 1300),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(AppColors.secondarySurface),
                                  columns: const [
                                    DataColumn(label: Text('Booking ID', style: _headerStyle)),
                                    DataColumn(label: Text('Passenger', style: _headerStyle)),
                                    DataColumn(label: Text('Route (Pickup → Dropoff)', style: _headerStyle)),
                                    DataColumn(label: Text('Pickup Time', style: _headerStyle)),
                                    DataColumn(label: Text('Flight / Terminal', style: _headerStyle)),
                                    DataColumn(label: Text('Assigned Driver', style: _headerStyle)),
                                    DataColumn(label: Text('Vehicle', style: _headerStyle)),
                                    DataColumn(label: Text('Fare / Amount', style: _headerStyle)),
                                    DataColumn(label: Text('Status', style: _headerStyle)),
                                    DataColumn(label: Text('Actions', style: _headerStyle)),
                                  ],
                                  rows: bookingState.filteredBookings.map((b) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          InkWell(
                                            onTap: () => context.go('/admin/bookings/${b.id}'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                              ),
                                              child: Text(
                                                b.displayCode,
                                                style: const TextStyle(
                                                  color: Color(0xFF60A5FA),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
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
                                              if (b.guestMobile.isNotEmpty)
                                                Text(b.guestMobile, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            constraints: const BoxConstraints(maxWidth: 220),
                                            child: Text(
                                              '${b.pickupLocation} → ${b.destination}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12, color: AppColors.primaryText),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text('${b.pickupDate}\n${b.pickupTime}', style: const TextStyle(color: AppColors.primaryText, fontSize: 12))),
                                        DataCell(Text(b.flightNumber.isNotEmpty ? '${b.flightNumber} (${b.terminal})' : 'N/A', style: const TextStyle(color: AppColors.primaryText))),
                                        DataCell(Text(b.driverName ?? 'Unassigned', style: TextStyle(color: b.driverName != null ? AppColors.primaryText : AppColors.danger, fontWeight: b.driverName != null ? FontWeight.normal : FontWeight.w600))),
                                        DataCell(Text(b.vehicleType ?? 'Sedan', style: const TextStyle(color: AppColors.primaryText))),
                                        DataCell(Text(b.totalFare > 0 ? '\$${b.totalFare.toStringAsFixed(2)}' : '\$0.00', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))),
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
                                               IconButton(
                                                 icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF38BDF8)),
                                                 tooltip: 'Edit Booking',
                                                 onPressed: () {
                                                   showDialog(
                                                     context: context,
                                                     builder: (_) => EditBookingDialog(booking: b),
                                                   );
                                                 },
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
                                                                'WhatsApp Dispatch — ${b.displayCode}',
                                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        content: const Text(
                                                          'Select recipient to dispatch WhatsApp transfer details:',
                                                          style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                                                        ),
                                                        actionsAlignment: MainAxisAlignment.center,
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
                                                                bookingId: b.id,
                                                                displayCode: b.displayCode,
                                                                specialAssistance: b.specialAssistance,
                                                              );
                                                            },
                                                            icon: const Icon(Icons.badge_outlined, size: 16),
                                                            label: Text('Driver (${b.driverName ?? "Assigned"})'),
                                                          ),
                                                          ElevatedButton.icon(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: AppColors.success,
                                                              foregroundColor: Colors.white,
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
                                                            icon: const Icon(Icons.person_outline, size: 16),
                                                            label: Text('Guest (${b.guestName})'),
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
                          ),
                        ),
                      );
                    },
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
