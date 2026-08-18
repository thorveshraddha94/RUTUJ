import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static String _cleanPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) cleaned = '91$cleaned';
    return cleaned;
  }

  /// 1. WhatsApp Template sent to the GUEST
  static Future<void> sendToGuest({
    required String guestPhone,
    required String guestName,
    required String companyName,
    required String pickupTime,
    required String pickupLocation,
    required String dropoffLocation,
    required String driverName,
    required String driverPhone,
    required String vehicleModel,
    required String plateNumber,
  }) async {
    final message = '''
🚖 *AIRPORT TRANSFER CONFIRMED*
━━━━━━━━━━━━━━━━━━━━━
Dear *$guestName*, your booking with *$companyName* is confirmed!

⏰ *Pickup Time:* $pickupTime
📍 *Pickup:* $pickupLocation
🏁 *Dropoff:* $dropoffLocation

👨‍✈️ *YOUR ASSIGNED DRIVER*
• *Driver:* $driverName
• *Contact:* $driverPhone

🚘 *VEHICLE DETAILS*
• *Vehicle:* $vehicleModel
• *Plate Number:* $plateNumber

Have a smooth and pleasant ride! ✨
━━━━━━━━━━━━━━━━━━━━━''';

    final uri = Uri.parse('https://wa.me/${_cleanPhone(guestPhone)}?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 2. WhatsApp Template sent to the DRIVER
  static Future<void> sendToDriver({
    required String driverPhone,
    required String driverName,
    required String companyName,
    required String guestName,
    required String guestPhone,
    required String pickupTime,
    required String pickupLocation,
    required String dropoffLocation,
    String? flightNumber,
    int? passengers,
    String? notes,
  }) async {
    final message = '''
🚨 *NEW TRIP ASSIGNMENT*
━━━━━━━━━━━━━━━━━━━━━
Hello *$driverName*, you have a new scheduled trip from *$companyName*:

⏰ *Pickup Time:* $pickupTime
📍 *Pickup:* $pickupLocation
🏁 *Dropoff:* $dropoffLocation
✈️ *Flight #:* ${flightNumber ?? 'N/A'}

👤 *GUEST INFORMATION*
• *Guest Name:* $guestName
• *Guest Phone:* $guestPhone
• *Passengers / Pax:* ${passengers ?? 1}
• *Notes:* ${notes ?? 'None'}

Please ensure punctuality and maintain fleet standards. 🚘
━━━━━━━━━━━━━━━━━━━━━''';

    final uri = Uri.parse('https://wa.me/${_cleanPhone(driverPhone)}?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Legacy Alias Helpers for compatibility
  static Future<void> sendDriverDetailsToClient({
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
  }) =>
      sendToGuest(
        guestPhone: clientPhone,
        guestName: clientName,
        companyName: companyName,
        pickupTime: pickupTime,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        driverName: driverName,
        driverPhone: driverPhone,
        vehicleModel: vehicleModel,
        plateNumber: plateNumber,
      );

  static Future<void> sendTripAssignmentToDriver({
    required String driverPhone,
    required String driverName,
    required String companyName,
    required String guestName,
    required String guestPhone,
    required String flightNumber,
    required String pickupLocation,
    required String dropoffLocation,
    required String scheduledTime,
    required int passengersCount,
    required int luggageCount,
    String? specialAssistance,
  }) =>
      sendToDriver(
        driverPhone: driverPhone,
        driverName: driverName,
        companyName: companyName,
        guestName: guestName,
        guestPhone: guestPhone,
        pickupTime: scheduledTime,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        flightNumber: flightNumber,
        passengers: passengersCount,
        notes: specialAssistance,
      );
}
