import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Launches WhatsApp web/mobile directly with structured driver and vehicle assignment details
  static Future<bool> sendDriverDetailsToClient({
    required String clientPhone,
    required String clientName,
    required String companyName,
    required String pickupLocation,
    required String dropoffLocation,
    required String pickupTime,
    required String driverName,
    required String driverPhone,
    required String vehicleModel,
    required String plateNumber,
  }) async {
    // 1. Clean phone number (strip whitespace, dashes, '+' symbols)
    String cleanPhone = clientPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length == 10) {
      // Default to country code 91 if 10 digits provided
      cleanPhone = '91$cleanPhone';
    }

    // 2. Build structured trip template
    final message = '''
🚖 *AIRPORT TRANSFER CONFIRMATION*
━━━━━━━━━━━━━━━━━━━━━
Dear *$clientName*, your transfer with *$companyName* is confirmed!

📍 *Pickup:* $pickupLocation
🏁 *Dropoff:* $dropoffLocation
⏰ *Scheduled Time:* $pickupTime

👨‍✈️ *DRIVER DETAILS*
• *Driver Name:* $driverName
• *Driver Contact:* $driverPhone

🚘 *VEHICLE DETAILS*
• *Model:* $vehicleModel
• *Plate Number:* $plateNumber

Have a pleasant and safe journey! ✨
━━━━━━━━━━━━━━━━━━━━━
''';

    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        return true;
      } else {
        await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
        return true;
      }
    } catch (_) {
      return false;
    }
  }
}
