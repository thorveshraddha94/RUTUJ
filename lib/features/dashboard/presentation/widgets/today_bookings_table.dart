import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../bookings/domain/booking_model.dart';

class TodayBookingsTable extends StatelessWidget {
  final List<BookingModel> bookings;
  final Function(String bookingId) onViewDetails;
  final Function(String bookingId) onReassignDriver;

  const TodayBookingsTable({
    super.key,
    required this.bookings,
    required this.onViewDetails,
    required this.onReassignDriver,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.event_busy, color: AppColors.secondaryText, size: 40),
            SizedBox(height: 12),
            Text(
              'No bookings scheduled for today.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.secondarySurface),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('Booking ID', style: _headerStyle)),
          DataColumn(label: Text('Guest', style: _headerStyle)),
          DataColumn(label: Text('Pickup Time', style: _headerStyle)),
          DataColumn(label: Text('Pickup Location', style: _headerStyle)),
          DataColumn(label: Text('Destination', style: _headerStyle)),
          DataColumn(label: Text('Driver', style: _headerStyle)),
          DataColumn(label: Text('Vehicle', style: _headerStyle)),
          DataColumn(label: Text('Status', style: _headerStyle)),
          DataColumn(label: Text('Action', style: _headerStyle)),
        ],
        rows: bookings.map((booking) {
          return DataRow(
            cells: [
              DataCell(
                InkWell(
                  onTap: () => onViewDetails(booking.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      booking.displayCode,
                      style: const TextStyle(
                        color: Color(0xFF60A5FA),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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
                    Text(
                      booking.guestName,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      booking.guestMobile,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  booking.pickupTime,
                  style: const TextStyle(color: AppColors.primaryText),
                ),
              ),
              DataCell(
                Container(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    booking.pickupLocation,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Container(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    booking.destination,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Text(
                  booking.driverName ?? 'Unassigned',
                  style: TextStyle(
                    color: booking.driverName != null
                        ? AppColors.primaryText
                        : AppColors.danger,
                    fontWeight: booking.driverName != null
                        ? FontWeight.w500
                        : FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                Text(
                  booking.vehicleRegistration ?? '-',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
              DataCell(StatusBadge(status: booking.status.displayName)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      tooltip: 'View Details',
                      onPressed: () => onViewDetails(booking.id),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.person_add_alt_outlined,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      tooltip: 'Reassign Driver',
                      onPressed: () => onReassignDriver(booking.id),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static const _headerStyle = TextStyle(
    color: AppColors.secondaryText,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );
}
