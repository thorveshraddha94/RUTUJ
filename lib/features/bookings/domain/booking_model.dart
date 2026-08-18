import 'timeline_event_model.dart';

enum BookingStatus {
  pending,
  assigned,
  confirmed,
  onTheWayToPickup,
  arrivedAtPickup,
  guestPickedUp,
  tripStarted,
  completed,
  cancelled,
}

extension BookingStatusX on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.assigned:
        return 'Assigned';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.onTheWayToPickup:
        return 'On the Way to Pickup';
      case BookingStatus.arrivedAtPickup:
        return 'Arrived at Pickup';
      case BookingStatus.guestPickedUp:
        return 'Guest Picked Up';
      case BookingStatus.tripStarted:
        return 'Trip Started';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class BookingModel {
  final String id;
  final String referenceCode;
  
  // Client Details
  final String clientName;
  final String clientContact;
  final String? clientReference;
  final String? internalNotes;

  // Guest Details
  final String guestName;
  final String guestMobile;
  final String guestEmail;
  final int passengersCount;
  final int luggageCount;
  final bool isVip;
  final String? specialAssistance;
  final String? guestNotes;

  // Flight Details
  final String flightNumber;
  final String flightType; // 'Arrival' or 'Departure'
  final String airport;
  final String terminal;
  final String flightDate;
  final String flightTime;

  // Pickup Details
  final String pickupDate;
  final String pickupTime;
  final String pickupLocation;
  final String? pickupTerminal;
  final String? pickupNotes;

  // Drop Details
  final String destination;
  final String destinationAddress;
  final String? dropNotes;

  // Vehicle & Driver Details
  final String? vehicleId;
  final String? vehicleType;
  final String? vehicleRegistration;
  final String? driverId;
  final String? driverName;
  final String? driverMobile;

  // Reminder & Status
  final BookingStatus status;
  final String? reminderDuration; // e.g. '2 hours'
  final bool notifyPush;
  final bool notifySms;
  final String? smsStatus; // e.g., 'SMS Sent' or 'SMS Pending'
  final DateTime createdAt;
  final String? cancellationReason;
  final List<TimelineEventModel> timeline;

  const BookingModel({
    required this.id,
    required this.referenceCode,
    required this.clientName,
    required this.clientContact,
    this.clientReference,
    this.internalNotes,
    required this.guestName,
    required this.guestMobile,
    required this.guestEmail,
    required this.passengersCount,
    required this.luggageCount,
    this.isVip = false,
    this.specialAssistance,
    this.guestNotes,
    required this.flightNumber,
    required this.flightType,
    required this.airport,
    required this.terminal,
    required this.flightDate,
    required this.flightTime,
    required this.pickupDate,
    required this.pickupTime,
    required this.pickupLocation,
    this.pickupTerminal,
    this.pickupNotes,
    required this.destination,
    required this.destinationAddress,
    this.dropNotes,
    this.vehicleId,
    this.vehicleType,
    this.vehicleRegistration,
    this.driverId,
    this.driverName,
    this.driverMobile,
    required this.status,
    this.reminderDuration,
    this.notifyPush = true,
    this.notifySms = true,
    this.smsStatus,
    required this.createdAt,
    this.cancellationReason,
    required this.timeline,
  });

  BookingModel copyWith({
    String? id,
    String? referenceCode,
    String? clientName,
    String? clientContact,
    String? clientReference,
    String? internalNotes,
    String? guestName,
    String? guestMobile,
    String? guestEmail,
    int? passengersCount,
    int? luggageCount,
    bool? isVip,
    String? specialAssistance,
    String? guestNotes,
    String? flightNumber,
    String? flightType,
    String? airport,
    String? terminal,
    String? flightDate,
    String? flightTime,
    String? pickupDate,
    String? pickupTime,
    String? pickupLocation,
    String? pickupTerminal,
    String? pickupNotes,
    String? destination,
    String? destinationAddress,
    String? dropNotes,
    String? vehicleId,
    String? vehicleType,
    String? vehicleRegistration,
    String? driverId,
    String? driverName,
    String? driverMobile,
    BookingStatus? status,
    String? reminderDuration,
    bool? notifyPush,
    bool? notifySms,
    String? smsStatus,
    DateTime? createdAt,
    String? cancellationReason,
    List<TimelineEventModel>? timeline,
  }) {
    return BookingModel(
      id: id ?? this.id,
      referenceCode: referenceCode ?? this.referenceCode,
      clientName: clientName ?? this.clientName,
      clientContact: clientContact ?? this.clientContact,
      clientReference: clientReference ?? this.clientReference,
      internalNotes: internalNotes ?? this.internalNotes,
      guestName: guestName ?? this.guestName,
      guestMobile: guestMobile ?? this.guestMobile,
      guestEmail: guestEmail ?? this.guestEmail,
      passengersCount: passengersCount ?? this.passengersCount,
      luggageCount: luggageCount ?? this.luggageCount,
      isVip: isVip ?? this.isVip,
      specialAssistance: specialAssistance ?? this.specialAssistance,
      guestNotes: guestNotes ?? this.guestNotes,
      flightNumber: flightNumber ?? this.flightNumber,
      flightType: flightType ?? this.flightType,
      airport: airport ?? this.airport,
      terminal: terminal ?? this.terminal,
      flightDate: flightDate ?? this.flightDate,
      flightTime: flightTime ?? this.flightTime,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTime: pickupTime ?? this.pickupTime,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupTerminal: pickupTerminal ?? this.pickupTerminal,
      pickupNotes: pickupNotes ?? this.pickupNotes,
      destination: destination ?? this.destination,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      dropNotes: dropNotes ?? this.dropNotes,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverMobile: driverMobile ?? this.driverMobile,
      status: status ?? this.status,
      reminderDuration: reminderDuration ?? this.reminderDuration,
      notifyPush: notifyPush ?? this.notifyPush,
      notifySms: notifySms ?? this.notifySms,
      smsStatus: smsStatus ?? this.smsStatus,
      createdAt: createdAt ?? this.createdAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      timeline: timeline ?? this.timeline,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      referenceCode: json['referenceCode'] as String,
      clientName: json['clientName'] as String,
      clientContact: json['clientContact'] as String,
      clientReference: json['clientReference'] as String?,
      internalNotes: json['internalNotes'] as String?,
      guestName: json['guestName'] as String,
      guestMobile: json['guestMobile'] as String,
      guestEmail: json['guestEmail'] as String,
      passengersCount: json['passengersCount'] as int? ?? 1,
      luggageCount: json['luggageCount'] as int? ?? 1,
      isVip: json['isVip'] as bool? ?? false,
      specialAssistance: json['specialAssistance'] as String?,
      guestNotes: json['guestNotes'] as String?,
      flightNumber: json['flightNumber'] as String,
      flightType: json['flightType'] as String? ?? 'Arrival',
      airport: json['airport'] as String,
      terminal: json['terminal'] as String,
      flightDate: json['flightDate'] as String,
      flightTime: json['flightTime'] as String,
      pickupDate: json['pickupDate'] as String,
      pickupTime: json['pickupTime'] as String,
      pickupLocation: json['pickupLocation'] as String,
      pickupTerminal: json['pickupTerminal'] as String?,
      pickupNotes: json['pickupNotes'] as String?,
      destination: json['destination'] as String,
      destinationAddress: json['destinationAddress'] as String,
      dropNotes: json['dropNotes'] as String?,
      vehicleId: json['vehicleId'] as String?,
      vehicleType: json['vehicleType'] as String?,
      vehicleRegistration: json['vehicleRegistration'] as String?,
      driverId: json['driverId'] as String?,
      driverName: json['driverName'] as String?,
      driverMobile: json['driverMobile'] as String?,
      status: _statusFromString(json['status'] as String),
      reminderDuration: json['reminderDuration'] as String?,
      notifyPush: json['notifyPush'] as bool? ?? true,
      notifySms: json['notifySms'] as bool? ?? true,
      smsStatus: json['smsStatus'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      cancellationReason: json['cancellationReason'] as String?,
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineEventModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'referenceCode': referenceCode,
        'clientName': clientName,
        'clientContact': clientContact,
        'clientReference': clientReference,
        'internalNotes': internalNotes,
        'guestName': guestName,
        'guestMobile': guestMobile,
        'guestEmail': guestEmail,
        'passengersCount': passengersCount,
        'luggageCount': luggageCount,
        'isVip': isVip,
        'specialAssistance': specialAssistance,
        'guestNotes': guestNotes,
        'flightNumber': flightNumber,
        'flightType': flightType,
        'airport': airport,
        'terminal': terminal,
        'flightDate': flightDate,
        'flightTime': flightTime,
        'pickupDate': pickupDate,
        'pickupTime': pickupTime,
        'pickupLocation': pickupLocation,
        'pickupTerminal': pickupTerminal,
        'pickupNotes': pickupNotes,
        'destination': destination,
        'destinationAddress': destinationAddress,
        'dropNotes': dropNotes,
        'vehicleId': vehicleId,
        'vehicleType': vehicleType,
        'vehicleRegistration': vehicleRegistration,
        'driverId': driverId,
        'driverName': driverName,
        'driverMobile': driverMobile,
        'status': status.name,
        'reminderDuration': reminderDuration,
        'notifyPush': notifyPush,
        'notifySms': notifySms,
        'smsStatus': smsStatus,
        'createdAt': createdAt.toIso8601String(),
        'cancellationReason': cancellationReason,
        'timeline': timeline.map((e) => e.toJson()).toList(),
      };

  factory BookingModel.fromSupabase(Map<String, dynamic> json) {
    return BookingModel(
      id: (json['id'] ?? '').toString(),
      referenceCode: (json['reference_code'] ?? json['referenceCode'] ?? 'REF-${json['id']}').toString(),
      clientName: (json['client_name'] ?? json['clientName'] ?? '').toString(),
      clientContact: (json['client_contact'] ?? json['clientContact'] ?? '').toString(),
      clientReference: json['client_reference'] as String? ?? json['clientReference'] as String?,
      internalNotes: json['internal_notes'] as String? ?? json['internalNotes'] as String?,
      guestName: (json['guest_name'] ?? json['guestName'] ?? '').toString(),
      guestMobile: (json['guest_mobile'] ?? json['guestMobile'] ?? '').toString(),
      guestEmail: (json['guest_email'] ?? json['guestEmail'] ?? '').toString(),
      passengersCount: int.tryParse(json['passengers_count']?.toString() ?? '') ??
          int.tryParse(json['passengersCount']?.toString() ?? '') ??
          1,
      luggageCount: int.tryParse(json['luggage_count']?.toString() ?? '') ??
          int.tryParse(json['luggageCount']?.toString() ?? '') ??
          1,
      isVip: json['is_vip'] as bool? ?? json['isVip'] as bool? ?? false,
      specialAssistance: json['special_assistance'] as String? ?? json['specialAssistance'] as String?,
      guestNotes: json['guest_notes'] as String? ?? json['guestNotes'] as String?,
      flightNumber: (json['flight_number'] ?? json['flightNumber'] ?? '').toString(),
      flightType: (json['flight_type'] ?? json['flightType'] ?? 'Arrival').toString(),
      airport: (json['airport'] ?? '').toString(),
      terminal: (json['terminal'] ?? '').toString(),
      flightDate: (json['flight_date'] ?? json['flightDate'] ?? '').toString(),
      flightTime: (json['flight_time'] ?? json['flightTime'] ?? '').toString(),
      pickupDate: (json['pickup_date'] ?? json['pickupDate'] ?? '').toString(),
      pickupTime: (json['pickup_time'] ?? json['pickupTime'] ?? '').toString(),
      pickupLocation: (json['pickup_location'] ?? json['pickupLocation'] ?? '').toString(),
      pickupTerminal: json['pickup_terminal'] as String? ?? json['pickupTerminal'] as String?,
      pickupNotes: json['pickup_notes'] as String? ?? json['pickupNotes'] as String?,
      destination: (json['destination'] ?? '').toString(),
      destinationAddress: (json['destination_address'] ?? json['destinationAddress'] ?? '').toString(),
      dropNotes: json['drop_notes'] as String? ?? json['dropNotes'] as String?,
      vehicleId: json['vehicle_id']?.toString() ?? json['vehicleId']?.toString(),
      vehicleType: json['vehicle_type']?.toString() ?? json['vehicleType']?.toString(),
      vehicleRegistration: json['vehicle_registration']?.toString() ?? json['vehicleRegistration']?.toString(),
      driverId: json['driver_id']?.toString() ?? json['driverId']?.toString(),
      driverName: json['driver_name']?.toString() ?? json['driverName']?.toString(),
      driverMobile: json['driver_mobile']?.toString() ?? json['driverMobile']?.toString(),
      status: _statusFromString((json['status'] ?? 'pending').toString()),
      reminderDuration: json['reminder_duration'] as String? ?? json['reminderDuration'] as String?,
      notifyPush: json['notify_push'] as bool? ?? json['notifyPush'] as bool? ?? true,
      notifySms: json['notify_sms'] as bool? ?? json['notifySms'] as bool? ?? true,
      smsStatus: json['sms_status'] as String? ?? json['smsStatus'] as String?,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : (json['createdAt'] != null
              ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
              : DateTime.now()),
      cancellationReason: json['cancellation_reason'] as String? ?? json['cancellationReason'] as String?,
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineEventModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toSupabase() => {
        'client_name': clientName,
        'client_contact': clientContact,
        if (clientReference != null) 'client_reference': clientReference,
        if (internalNotes != null) 'internal_notes': internalNotes,
        'guest_name': guestName,
        'guest_mobile': guestMobile,
        'guest_email': guestEmail,
        'passengers_count': passengersCount,
        'luggage_count': luggageCount,
        'is_vip': isVip,
        if (specialAssistance != null) 'special_assistance': specialAssistance,
        if (guestNotes != null) 'guest_notes': guestNotes,
        'flight_number': flightNumber,
        'flight_type': flightType,
        'airport': airport,
        'terminal': terminal,
        'flight_date': flightDate,
        'flight_time': flightTime,
        'pickup_date': pickupDate,
        'pickup_time': pickupTime,
        'pickup_location': pickupLocation,
        if (pickupTerminal != null) 'pickup_terminal': pickupTerminal,
        if (pickupNotes != null) 'pickup_notes': pickupNotes,
        'destination': destination,
        'destination_address': destinationAddress,
        if (dropNotes != null) 'drop_notes': dropNotes,
        if (vehicleId != null) 'vehicle_id': vehicleId,
        if (vehicleType != null) 'vehicle_type': vehicleType,
        if (vehicleRegistration != null) 'vehicle_registration': vehicleRegistration,
        if (driverId != null) 'driver_id': driverId,
        if (driverName != null) 'driver_name': driverName,
        if (driverMobile != null) 'driver_mobile': driverMobile,
        'status': status.name,
        if (reminderDuration != null) 'reminder_duration': reminderDuration,
        'notify_push': notifyPush,
        'notify_sms': notifySms,
        if (smsStatus != null) 'sms_status': smsStatus,
        if (cancellationReason != null) 'cancellation_reason': cancellationReason,
      };

  static BookingStatus _statusFromString(String str) {
    switch (str.toLowerCase()) {
      case 'assigned':
        return BookingStatus.assigned;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'onthewaytopickup':
      case 'on the way to pickup':
        return BookingStatus.onTheWayToPickup;
      case 'arrivedatpickup':
      case 'arrived at pickup':
        return BookingStatus.arrivedAtPickup;
      case 'guestpickedup':
      case 'guest picked up':
        return BookingStatus.guestPickedUp;
      case 'tripstarted':
      case 'trip started':
        return BookingStatus.tripStarted;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }
}

