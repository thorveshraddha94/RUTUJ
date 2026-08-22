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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹${b.totalFare.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share, color: Color(0xFF10B981), size: 20),
                        onPressed: () => _openWhatsAppDispatchDialog(b),
                        tooltip: 'Share WhatsApp Details',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF38BDF8), size: 20),
                        onPressed: () => showDialog(context: context, builder: (_) => EditBookingDialog(booking: b)),
                        tooltip: 'Edit Booking',
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, color: Colors.white70, size: 20),
                        onPressed: () => context.go('/admin/bookings/${b.id}'),
                        tooltip: 'View Details',
                      ),
                    ],
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
                      rows: bookings.map((b) {
                        return DataRow(
                          cells: [
                            DataCell(
                              InkWell(
                                onTap: () => context.go('/admin/bookings/${b.id}'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
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
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${b.pickupDate}\n${b.pickupTime}', style: const TextStyle(color: AppColors.primaryText, fontSize: 12)),
                                  if (b.isMultiDay) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFF59E0B)),
                                      ),
                                      child: Text(
                                        '${b.durationInDays} DAYS PACKAGE',
                                        style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            DataCell(Text(b.flightNumber.isNotEmpty ? '${b.flightNumber} (${b.terminal})' : 'N/A', style: const TextStyle(color: AppColors.primaryText))),
                            DataCell(Text(b.driverName ?? 'Unassigned', style: TextStyle(color: b.driverName != null ? AppColors.primaryText : AppColors.danger, fontWeight: b.driverName != null ? FontWeight.normal : FontWeight.w600))),
                            DataCell(Text(b.vehicleType ?? 'Sedan', style: const TextStyle(color: AppColors.primaryText))),
                            DataCell(Text(b.totalFare > 0 ? '₹${b.totalFare.toStringAsFixed(2)}' : '₹0.00', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))),
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
                                    onPressed: () async {
                                      final result = await showDialog<bool>(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (ctx) => EditBookingDialog(booking: b),
                                      );
                                      if (result == true) {
                                        ref.read(bookingProvider.notifier).fetchBookings();
                                      }
                                    },
                                  ),
                                  if (b.driverName != null && b.driverMobile != null)
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.success),
                                      onPressed: () => _openWhatsAppDispatchDialog(b),
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
    );
  }

  static const _headerStyle = TextStyle(
    color: AppColors.secondaryText,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );
}
