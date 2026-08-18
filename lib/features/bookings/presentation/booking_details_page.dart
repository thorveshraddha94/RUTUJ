import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/booking_repository.dart';
import '../domain/booking_model.dart';
import '../../dashboard/presentation/widgets/reassign_driver_dialog.dart';
import 'cancel_booking_dialog.dart';

class BookingDetailsPage extends ConsumerWidget {
  final String bookingId;

  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingDetailsProvider(bookingId));

    if (booking == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Booking Details'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 16),
              Text(
                'Booking $bookingId not found.',
                style: const TextStyle(color: AppColors.primaryText, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/admin/bookings'),
                child: const Text('Back to Bookings'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Booking Details: ${booking.id}', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => context.go('/admin/bookings'),
        ),
        actions: [
          StatusBadge(status: booking.status.displayName),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Button Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Reference: ${booking.referenceCode}',
                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                    ),
                    if (booking.isVip) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: const Text(
                          '★ VIP PRIORITY',
                          style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ]
                  ],
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    if (booking.status != BookingStatus.cancelled && booking.status != BookingStatus.completed) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => ReassignDriverDialog(bookingId: booking.id),
                          );
                        },
                        icon: const Icon(Icons.person_add_alt_1_outlined, size: 16, color: AppColors.warning),
                        label: const Text('Reassign Driver', style: TextStyle(color: AppColors.warning)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => CancelBookingDialog(bookingId: booking.id),
                          );
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.danger),
                        label: const Text('Cancel Booking', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Two Column Details & Timeline Layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1024) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildDetailsGrid(booking),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: _buildTimelineCard(booking),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildDetailsGrid(booking),
                      const SizedBox(height: 24),
                      _buildTimelineCard(booking),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid(BookingModel booking) {
    return Column(
      children: [
        // Guest & Client Info
        _buildInfoCard(
          title: 'Guest & Client Details',
          icon: Icons.person_outline,
          children: [
            _infoRow('Guest Name', booking.guestName, 'Guest Mobile', booking.guestMobile),
            const SizedBox(height: 12),
            _infoRow('Guest Email', booking.guestEmail, 'Passengers / Bags', '${booking.passengersCount} Person(s) / ${booking.luggageCount} Bag(s)'),
            const SizedBox(height: 12),
            _infoRow('Client Company', booking.clientName, 'Client Contact', booking.clientContact),
            if (booking.specialAssistance != null) ...[
              const SizedBox(height: 12),
              _infoRow('Special Assistance', booking.specialAssistance!, 'Guest Notes', booking.guestNotes ?? 'None'),
            ]
          ],
        ),
        const SizedBox(height: 20),

        // Flight & Schedule Info
        _buildInfoCard(
          title: 'Flight & Schedule Details',
          icon: Icons.flight_takeoff_outlined,
          children: [
            _infoRow('Flight Number', booking.flightNumber, 'Flight Type', booking.flightType),
            const SizedBox(height: 12),
            _infoRow('Airport', booking.airport, 'Terminal', booking.terminal),
            const SizedBox(height: 12),
            _infoRow('Flight Schedule', '${booking.flightDate} at ${booking.flightTime}', 'Pickup Schedule', '${booking.pickupDate} at ${booking.pickupTime}'),
          ],
        ),
        const SizedBox(height: 20),

        // Pickup & Destination Location Info
        _buildInfoCard(
          title: 'Pickup & Drop Locations',
          icon: Icons.alt_route_rounded,
          children: [
            _infoRow('Pickup Location', booking.pickupLocation, 'Pickup Gate', booking.pickupTerminal ?? 'Main Gate'),
            const SizedBox(height: 12),
            _infoRow('Destination', booking.destination, 'Full Address', booking.destinationAddress),
          ],
        ),
        const SizedBox(height: 20),

        // Vehicle, Driver & Reminder Config Info
        _buildInfoCard(
          title: 'Driver, Vehicle & Reminders',
          icon: Icons.directions_car_outlined,
          children: [
            _infoRow('Assigned Driver', booking.driverName ?? 'Unassigned', 'Driver Contact', booking.driverMobile ?? 'N/A'),
            const SizedBox(height: 12),
            _infoRow('Vehicle Reg', booking.vehicleRegistration ?? 'Unassigned', 'Vehicle Type', booking.vehicleType ?? 'Sedan'),
            const SizedBox(height: 12),
            _infoRow('Reminder Schedule', booking.reminderDuration ?? '2 hours before', 'SMS Status', booking.smsStatus ?? 'SMS Pending'),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineCard(BookingModel booking) {
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
          const Row(
            children: [
              Icon(Icons.timeline_outlined, color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Text(
                'Booking Timeline',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          if (booking.timeline.isEmpty)
            const Text('No timeline events recorded.', style: TextStyle(color: AppColors.secondaryText))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: booking.timeline.length,
              itemBuilder: (context, index) {
                final event = booking.timeline[index];
                final isLast = index == booking.timeline.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isLast ? AppColors.primary : AppColors.secondarySurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: isLast ? AppColors.primary : AppColors.border),
                          ),
                          child: Icon(
                            isLast ? Icons.check : Icons.circle,
                            size: isLast ? 14 : 8,
                            color: isLast ? Colors.white : AppColors.secondaryText,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 36,
                            color: AppColors.border,
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: TextStyle(
                                color: isLast ? AppColors.primaryText : AppColors.secondaryText,
                                fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.description,
                              style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(event.timestamp),
                              style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value1, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value2, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
