import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'status_badge.dart';

class DriverStatusCard extends StatelessWidget {
  final String driverName;
  final String vehicleReg;
  final String status;
  final String? currentBookingId;

  const DriverStatusCard({
    super.key,
    required this.driverName,
    required this.vehicleReg,
    required this.status,
    this.currentBookingId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              driverName.isNotEmpty ? driverName[0] : 'D',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vehicleReg,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: status, isCompact: true),
              if (currentBookingId != null && currentBookingId!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _formatBookingCode(currentBookingId!),
                  style: const TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  String _formatBookingCode(String id) {
    if (id.startsWith('BK-') || id.startsWith('AT-')) return id;
    if (id.length >= 8) return 'BK-${id.substring(0, 6).toUpperCase()}';
    return 'BK-$id';
  }
}
