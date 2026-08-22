import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/bookings/domain/booking_model.dart';

class WhatsAppService {
  /// Multi-Day String Formatter
  static String formatTripDuration(BookingModel booking) {
    final dateFormat = DateFormat('dd MMM yyyy');
    if (booking.tripType == 'multi_day' && booking.durationInDays > 1) {
      final start = booking.startDateTime != null ? dateFormat.format(booking.startDateTime!) : '';
      final end = booking.endDateTime != null ? dateFormat.format(booking.endDateTime!) : '';
      return '${booking.durationInDays} Days Package ($start to $end)';
    }
    return 'Single Day Transfer';
  }
  static String _cleanPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) cleaned = '91$cleaned';
    return cleaned;
  }

  /// Launch WhatsApp with safe UTF-8 query encoding
  static Future<void> sendWhatsApp(String phone, String text) async {
    final cleanNumber = _cleanPhone(phone);
    final encodedText = Uri.encodeComponent(text);
    final Uri url = Uri.parse('https://wa.me/$cleanNumber?text=$encodedText');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Direct BookingModel Driver Message Builder
  static String buildDriverMessageFromBooking(BookingModel booking) {
    final buffer = StringBuffer();
    buffer.writeln('🚗 *Trip Assignment — ${booking.displayCode}*');
    buffer.writeln('👥 *Total Passengers:* ${booking.passengersCount}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    if (booking.passengers != null && booking.passengers!.length > 1) {
      for (int i = 0; i < booking.passengers!.length; i++) {
        final p = booking.passengers![i];
        final name = p['name'] ?? p['passenger_name'] ?? 'Passenger ${i + 1}';
        final phone = p['phone'] ?? p['passenger_phone'] ?? '';
        final pick = p['pickup_location'] ?? p['origin'] ?? booking.pickupLocation;
        final drop = p['dropoff_location'] ?? p['destination'] ?? booking.destination;
        final phoneStr = phone.toString().isNotEmpty ? ' ($phone)' : '';
        buffer.writeln('👤 *Passenger ${i + 1}:* $name$phoneStr');
        buffer.writeln('   📍 *Pickup:* $pick');
        buffer.writeln('   🏁 *Dropoff:* $drop');
        buffer.writeln('');
      }
    } else {
      buffer.writeln('👤 *Passenger:* ${booking.passengerName} (${booking.passengerPhone})');
      buffer.writeln('📍 *Pickup:* ${booking.pickupLocation}');
      buffer.writeln('🏁 *Dropoff:* ${booking.destination}');
    }

    final token = booking.tripToken.isNotEmpty ? booking.tripToken : booking.id;
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📲 *Driver Action Link:*');
    buffer.writeln('https://travelportl.vercel.app/#/trip/$token');
    return buffer.toString();
  }

  /// 3. Booked By / Coordinator WhatsApp Confirmation Message
  static String buildBookedByConfirmationMessage(BookingModel booking) {
    final buffer = StringBuffer();
    buffer.writeln('📋 *Booking Confirmation — ${booking.displayCode}*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    if (booking.bookedByName != null && booking.bookedByName!.isNotEmpty) {
      buffer.writeln('👤 *Booked By:* ${booking.bookedByName}');
    }
    if (booking.wbsNo != null && booking.wbsNo!.isNotEmpty) {
      buffer.writeln('🏷️ *WBS No:* ${booking.wbsNo}');
    }
    if (booking.pickupTimeFormatted.isNotEmpty) {
      buffer.writeln('⏰ *Pickup Date & Time:* ${booking.pickupTimeFormatted}');
    }
    if (booking.tripType == 'multi_day' && (booking.durationDays) > 1) {
      buffer.writeln('📅 *Duration:* ${booking.durationDays} Days Package');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👨‍✈️ *Assigned Driver:* ${booking.driverName ?? "Assigned"}');
    buffer.writeln('📞 *Driver Phone:* ${booking.driverPhone ?? "N/A"}');
    if (booking.vehicleName != null && booking.vehicleName!.isNotEmpty) {
      final numStr = (booking.vehicleNumber != null && booking.vehicleNumber!.isNotEmpty) ? ' (${booking.vehicleNumber})' : '';
      buffer.writeln('🚗 *Vehicle:* ${booking.vehicleName}$numStr');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👥 *Passenger Details:*');

    if (booking.passengers != null && booking.passengers!.isNotEmpty) {
      for (int i = 0; i < booking.passengers!.length; i++) {
        final p = booking.passengers![i];
        final name = p['name'] ?? p['passenger_name'] ?? 'Passenger ${i + 1}';
        final phone = p['phone'] ?? p['passenger_phone'] ?? '';
        final pick = p['pickup_location'] ?? p['origin'] ?? booking.pickupLocation;
        final drop = p['dropoff_location'] ?? p['destination'] ?? booking.destination;
        final phoneStr = phone.toString().isNotEmpty ? ' ($phone)' : '';
        buffer.writeln('${i + 1}. *$name*$phoneStr');
        buffer.writeln('   📍 *Pickup:* $pick');
        buffer.writeln('   🏁 *Dropoff:* $drop');
      }
    } else {
      buffer.writeln('• *${booking.passengerName}* (${booking.passengerPhone})');
      buffer.writeln('  📍 *Pickup:* ${booking.pickupLocation}');
      buffer.writeln('  🏁 *Dropoff:* ${booking.destination}');
    }

    if (booking.totalFare > 0) {
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('💰 *Total Fare:* ₹${booking.totalFare.toStringAsFixed(2)}');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Thank you for booking with us! Let us know if you need any changes.');
    return buffer.toString();
  }

  /// 1. Driver WhatsApp Message (Includes Trip Portal Link)
  static String buildDriverMessage({
    required String bookingCode,
    required String passengerName,
    required String passengerPhone,
    required String pickupLocation,
    required String dropoffLocation,
    required String pickupTime,
    String? tripToken,
    String? bookingId,
    String? durationInfo,
    List<Map<String, dynamic>>? passengers,
  }) {
    final token = tripToken ?? bookingId ?? '';
    final tripLink = 'https://travelportl.vercel.app/#/trip/$token';

    final buffer = StringBuffer();
    buffer.writeln('🚗 *New Trip Assignment — $bookingCode*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    if (passengers != null && passengers.length > 1) {
      buffer.writeln('👥 *Passengers & Route Stops (${passengers.length}):*');
      for (int i = 0; i < passengers.length; i++) {
        final p = passengers[i];
        final name = p['name'] ?? p['passenger_name'] ?? 'Passenger ${i + 1}';
        final phone = p['phone'] ?? p['passenger_phone'] ?? '';
        final pick = p['pickup_location'] ?? p['origin'] ?? pickupLocation;
        final drop = p['dropoff_location'] ?? p['destination'] ?? dropoffLocation;
        final phoneStr = phone.toString().isNotEmpty ? ' ($phone)' : '';
        buffer.writeln('${i + 1}️⃣ *$name*$phoneStr');
        buffer.writeln('   📍 Pick: $pick');
        buffer.writeln('   🏁 Drop: $drop');
      }
    } else {
      buffer.writeln('👤 *Passenger:* $passengerName');
      buffer.writeln('📞 *Contact:* $passengerPhone');
      buffer.writeln('📍 *Pickup:* $pickupLocation');
      buffer.writeln('🏁 *Dropoff:* $dropoffLocation');
    }
    if (pickupTime.isNotEmpty) {
      buffer.writeln('⏰ *Pickup Time:* $pickupTime');
    }
    if (durationInfo != null && durationInfo.isNotEmpty) {
      buffer.writeln('📅 *Duration:* $durationInfo');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📲 *Update Trip Status (Tap Link Below):*');
    buffer.writeln(tripLink);
    return buffer.toString();
  }

  /// 2. Guest WhatsApp Message (Driver & Vehicle Confirmation)
  static String buildGuestMessage({
    required String bookingCode,
    required String pickupLocation,
    required String dropoffLocation,
    required String pickupTime,
    required String driverName,
    required String driverPhone,
    String? vehicleName,
    String? vehicleNumber,
    String? durationInfo,
    List<Map<String, dynamic>>? passengers,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🚖 *Your Booking Confirmation — $bookingCode*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    if (passengers != null && passengers.length > 1) {
      buffer.writeln('👥 *Passengers & Route Stops (${passengers.length}):*');
      for (int i = 0; i < passengers.length; i++) {
        final p = passengers[i];
        final name = p['name'] ?? p['passenger_name'] ?? 'Passenger ${i + 1}';
        final pick = p['pickup_location'] ?? p['origin'] ?? pickupLocation;
        final drop = p['dropoff_location'] ?? p['destination'] ?? dropoffLocation;
        buffer.writeln('${i + 1}️⃣ *$name*');
        buffer.writeln('   📍 Pick: $pick ➔ 🏁 Drop: $drop');
      }
    } else {
      buffer.writeln('📍 *Pickup:* $pickupLocation');
      buffer.writeln('🏁 *Dropoff:* $dropoffLocation');
    }
    if (pickupTime.isNotEmpty) {
      buffer.writeln('⏰ *Pickup Time:* $pickupTime');
    }
    if (durationInfo != null && durationInfo.isNotEmpty) {
      buffer.writeln('📅 *Duration:* $durationInfo');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👨‍✈️ *Assigned Driver:* $driverName');
    buffer.writeln('📞 *Driver Phone:* $driverPhone');
    if (vehicleName != null && vehicleName.isNotEmpty) {
      final numStr = (vehicleNumber != null && vehicleNumber.isNotEmpty) ? ' ($vehicleNumber)' : '';
      buffer.writeln('🚗 *Vehicle:* $vehicleName$numStr');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Have a safe trip with us!');
    return buffer.toString();
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
    String? displayCode,
  }) async {
    final code = displayCode ?? 'BK-CONFIRM';
    final text = buildGuestMessage(
      bookingCode: code,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      pickupTime: pickupTime,
      driverName: driverName,
      driverPhone: driverPhone,
      vehicleName: vehicleModel,
      vehicleNumber: plateNumber,
    );
    await sendWhatsApp(guestPhone, text);
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
    String? bookingId,
    String? tripToken,
    String? displayCode,
    String? flightNumber,
    int? passengers,
    String? notes,
  }) async {
    final code = displayCode ?? (bookingId != null && bookingId.length >= 6 ? 'BK-${bookingId.substring(0, 6).toUpperCase()}' : 'BK-TRIP');
    final text = buildDriverMessage(
      bookingCode: code,
      passengerName: guestName,
      passengerPhone: guestPhone,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      pickupTime: pickupTime,
      tripToken: tripToken,
      bookingId: bookingId,
    );
    await sendWhatsApp(driverPhone, text);
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
    String? bookingId,
    String? tripToken,
    String? displayCode,
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
      displayCode: displayCode,
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
      bookingId: bookingId,
      tripToken: tripToken,
      displayCode: displayCode,
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
    String? bookingId,
    String? tripToken,
    String? displayCode,
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
        bookingId: bookingId,
        tripToken: tripToken,
        displayCode: displayCode,
        flightNumber: flightNumber,
        passengers: passengersCount,
        notes: specialAssistance,
      );
}
