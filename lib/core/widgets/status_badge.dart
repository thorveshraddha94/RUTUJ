import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 6 : 8,
            height: isCompact ? 6 : 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'confirmed':
      case 'active':
        return const Color(0xFF32C48D); // Success
      case 'on the way to pickup':
      case 'arrived at pickup':
      case 'guest picked up':
      case 'trip started':
      case 'in progress':
      case 'on trip':
      case 'on_trip':
        return const Color(0xFF4F8CFF); // Primary
      case 'assigned':
      case 'pending':
      case 'upcoming':
        return const Color(0xFFF5B942); // Warning
      case 'cancelled':
      case 'unassigned':
      case 'deactivated':
      case 'inactive':
        return const Color(0xFFEF5B6B); // Danger
      default:
        return const Color(0xFF9AA8BC);
    }
  }
}
