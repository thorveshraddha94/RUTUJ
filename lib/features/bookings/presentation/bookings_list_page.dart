import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/status_badge.dart';
import '../../tenant/data/tenant_provider.dart';
import '../data/booking_repository.dart';
import '../domain/booking_model.dart';
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

  void _openWhatsAppDispatchDialog(BookingModel b) {
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
                driverPhone: b.driverMobile ?? '',
                driverName: b.driverName ?? 'Driver',
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
                driverName: b.driverName ?? 'Driver',
                driverPhone: b.driverMobile ?? 'N/A',
                vehicleModel: b.vehicleType ?? 'Assigned Vehicle',
                plateNumber: b.vehicleRegistration ?? 'N/A',
              );
            },
            icon: const Icon(Icons.person_outline, size: 16),
            label: Text('Guest (${b.guestName})'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final phone = (b.bookedByPhone != null && b.bookedByPhone!.isNotEmpty)
                  ? b.bookedByPhone!
                  : b.guestMobile;
              WhatsAppService.sendWhatsApp(
                phone,
                WhatsAppService.buildBookedByConfirmationMessage(b),
              );
            },
            icon: const Icon(Icons.assignment_ind_outlined, size: 16),
            label: Text('Booked By (${(b.bookedByName != null && b.bookedByName!.isNotEmpty) ? b.bookedByName : "Coordinator"})'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final bookingState = ref.watch(bookingProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isMobile
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF0284C7),
              onPressed: () => context.go('/admin/bookings/create'),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bookings',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (!isMobile)
                      const Text(
                        'Manage all airport pickup and drop assignments',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                      ),
                  ],
                ),
                if (!isMobile)
                  ElevatedButton.icon(
                    onPressed: () => context.go('/admin/bookings/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Search & Filter Bar
            _buildSearchAndFilterBar(isMobile),
            const SizedBox(height: 14),

            // Adaptive Body
            Expanded(
              child: bookingState.filteredBookings.isEmpty
                  ? _buildEmptyState()
                  : (isMobile
                      ? _buildMobileBookingCards(bookingState.filteredBookings)
                      : _buildDesktopBookingTable(bookingState.filteredBookings)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(bool isMobile) {
    final bookingState = ref.watch(bookingProvider);
    final notifier = ref.read(bookingProvider.notifier);

    final searchField = TextField(
      decoration: const InputDecoration(
        hintText: 'Search by Booking ID, Guest, Driver or Flight...',
        prefixIcon: Icon(Icons.search, color: AppColors.secondaryText),
      ),
      onChanged: (query) => notifier.setSearchQuery(query),
    );

    final dropdownFilter = DropdownButton<BookingStatus?>(
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
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: isMobile
          ? Column(
              children: [
                searchField,
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status Filter:', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                    dropdownFilter,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 16),
                dropdownFilter,
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => context.go('/admin/bookings/create'),
            icon: const Icon(Icons.add),
            label: const Text('+ Create First Booking'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBookingCards(List<BookingModel> bookings) {
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
                  InkWell(
                    onTap: () => context.go('/admin/bookings/${b.id}'),
                    child: Text(
                      b.displayCode,
                      style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  StatusBadge(status: b.status.displayName),
                ],
              ),
              const SizedBox(height: 10),
              Text(b.passengerName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              if (b.passengerPhone.isNotEmpty)
                Text(b.passengerPhone, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 6),
              Text('📍 ${b.pickupLocation} ➔ 🏁 ${b.dropoffLocation}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 6),
              Text('⏰ ${b.pickupDate} at ${b.pickupTime}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              Text('👨‍✈️ Driver: ${b.driverName ?? "Unassigned"} (${b.driverPhone ?? ""})', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Divider(color: Color(0xFF1F2E45), height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Color(0xFF10B981), size: 20),
                    tooltip: 'Share via WhatsApp',
                    onPressed: () => _openWhatsAppDispatchDialog(b),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF38BDF8), size: 20),
                    tooltip: 'Edit Booking',
                    onPressed: () => showDialog(context: context, builder: (_) => EditBookingDialog(booking: b)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopBookingTable(List<BookingModel> bookings) {
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
                    constraints: const BoxConstraints(minWidth: 1000),
                    child: DataTable(
                      horizontalMargin: 20,
                      columnSpacing: 24,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
                      columns: const [
                        DataColumn(label: Text('Booking Code / Guest', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Trip Route', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Date & Schedule', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Assigned Driver', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Vehicle', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                      ],
                      rows: bookings.map((b) => _buildBookingDataRow(context, ref, b)).toList(),
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

  DataRow _buildBookingDataRow(BuildContext context, WidgetRef ref, BookingModel booking) {
    final bookedBy = (booking.bookedByName ?? '').trim();

    return DataRow(
      cells: [
        // 1. Booking Code / Guest
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => context.go('/admin/bookings/${booking.id}'),
                child: Text(
                  booking.displayCode,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Text(booking.passengerName, style: const TextStyle(color: Colors.white, fontSize: 12)),
              if (bookedBy.isNotEmpty)
                Text('By: $bookedBy', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            ],
          ),
        ),

        // 2. Trip Route
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '📍 ${booking.pickupLocation}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '🏁 ${booking.dropoffLocation}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),

        // 3. Date & Schedule
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${booking.pickupDate} at ${booking.pickupTime}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              if (booking.isMultiDay)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${booking.durationInDays} Days Package',
                    style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),

        // 4. Assigned Driver
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                booking.driverName ?? 'Unassigned',
                style: TextStyle(
                  color: booking.driverName != null ? Colors.white : AppColors.danger,
                  fontSize: 12,
                  fontWeight: booking.driverName != null ? FontWeight.w500 : FontWeight.bold,
                ),
              ),
              if (booking.driverPhone != null && booking.driverPhone!.isNotEmpty)
                Text(booking.driverPhone!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            ],
          ),
        ),

        // 5. Vehicle
        DataCell(
          Text(
            booking.vehicleName != null && booking.vehicleName!.isNotEmpty
                ? '${booking.vehicleName} (${booking.vehicleNumber ?? ""})'
                : (booking.vehicleType ?? 'Sedan'),
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ),

        // 6. Status
        DataCell(StatusBadge(status: booking.status.displayName)),

        // 7. Actions (Edit, WhatsApp, Delete/Cancel)
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (booking.status == BookingStatus.newRequest || booking.driverName == null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        barrierDismissible: true,
                        builder: (ctx) => EditBookingDialog(booking: booking),
                      );
                      if (result == true) {
                        ref.read(bookingProvider.notifier).fetchBookings();
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 14),
                    label: const Text('Assign Driver', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                onPressed: () => context.go('/admin/bookings/${booking.id}'),
                tooltip: 'View Booking',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF38BDF8)),
                tooltip: 'Edit Booking',
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    barrierDismissible: true,
                    builder: (ctx) => EditBookingDialog(booking: booking),
                  );
                  if (result == true) {
                    ref.read(bookingProvider.notifier).fetchBookings();
                  }
                },
              ),
              if (booking.driverName != null && booking.driverPhone != null)
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.success),
                  onPressed: () => _openWhatsAppDispatchDialog(booking),
                  tooltip: 'Send WhatsApp Details',
                ),
              if (booking.status != BookingStatus.cancelled && booking.status != BookingStatus.completed) ...[
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.danger),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CancelBookingDialog(bookingId: booking.id),
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
  }
}
