import 'package:flutter/material.dart';

class AppColors {
  // Airport Transfer Dark Theme Palette
  static const Color background = Color(0xFF0B1220);
  static const Color surface = Color(0xFF111A2B);
  static const Color secondarySurface = Color(0xFF172235);
  static const Color border = Color(0xFF26354D);
  static const Color primary = Color(0xFF4F8CFF);
  static const Color success = Color(0xFF32C48D);
  static const Color warning = Color(0xFFF5B942);
  static const Color danger = Color(0xFFEF5B6B);
  static const Color primaryText = Color(0xFFF5F7FA);
  static const Color secondaryText = Color(0xFF9AA8BC);

  // Decorative Accent Gradients & Overlays
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F8CFF), Color(0xFF3B6ECC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    colors: [Color(0xFF172235), Color(0xFF111A2B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'guest picked up':
      case 'confirmed':
        return success;
      case 'on the way to pickup':
      case 'arrived at pickup':
      case 'trip started':
      case 'in progress':
        return primary;
      case 'assigned':
      case 'pending':
      case 'upcoming':
        return warning;
      case 'cancelled':
      case 'unassigned':
      case 'deactivated':
        return danger;
      default:
        return secondaryText;
    }
  }
}
