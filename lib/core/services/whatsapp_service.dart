import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static String _cleanPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) cleaned = '91$cleaned';
    return cleaned;
  }

  /// Launch WhatsApp with safe UTF-8 query encoding
  static Future<void> _launchWhatsApp(String phone, String message) async {
    final cleanNumber = _cleanPhone(phone);
    final Uri url = Uri.https('wa.me', '/$cleanNumber', {
      'text': message,
    });

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
*TRIP CONFIRMATION*
----------------------------------------
Dear *$guestName*, your booking with *$companyName* is confirmed!

*Scheduled Time:* $pickupTime
*Pickup Location:* $pickupLocation
*Dropoff Location:* $dropoffLocation

*DRIVER & VEHICLE DETAILS*
- *Driver Name:* $driverName
- *Driver Contact:* $driverPhone
- *Vehicle Model:* $vehicleModel
- *License Plate:* $plateNumber

Have a pleasant journey!
----------------------------------------''';

    await _launchWhatsApp(guestPhone, message);
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
*NEW TRIP ASSIGNMENT*
----------------------------------------
Hello *$driverName*, you have a new trip scheduled from *$companyName*:

*Pickup Time:* $pickupTime
*Pickup Location:* $pickupLocation
*Dropoff Location:* $dropoffLocation
*Flight No:* ${flightNumber != null && flightNumber.isNotEmpty ? flightNumber : 'N/A'}

*GUEST INFORMATION*
- *Guest Name:* $guestName
- *Guest Contact:* $guestPhone
- *Passengers / Pax:* ${passengers ?? 1}
- *Notes:* ${notes != null && notes.isNotEmpty ? notes : 'None'}

Please ensure punctuality.
----------------------------------------''';

    await _launchWhatsApp(driverPhone, message);
  }

  /// 3. 1-Click WhatsApp Template sent to BOTH Guest and Driver
  static Future<void> sendToBoth({
    required String guestPhone,
    required String guestName,
    required String companyName,
    required String pickupTime,
    required String pickupLocation,
    required String dropoffLocation,
    required String driverPhone,
    required String driverName,
    required String vehicleModel,
    required String plateNumber,
    String? flightNumber,
    int? passengers,
    String? notes,
  }) async {
    await sendToGuest(
      guestPhone: guestPhone,
      guestName: guestName,
      companyName: companyName,
      pickupTime: pickupTime,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      driverName: driverName,
      driverPhone: driverPhone,
      vehicleModel: vehicleModel,
      plateNumber: plateNumber,
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    await sendToDriver(
      driverPhone: driverPhone,
      driverName: driverName,
      companyName: companyName,
      guestName: guestName,
      guestPhone: guestPhone,
      pickupTime: pickupTime,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      flightNumber: flightNumber,
      passengers: passengers,
      notes: notes,
    );
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
