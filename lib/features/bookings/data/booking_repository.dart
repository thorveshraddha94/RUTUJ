import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/booking_model.dart';
import '../domain/timeline_event_model.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/notification_model.dart';
import '../../../core/network/sms_service.dart';

class BookingState {
  final List<BookingModel> bookings;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final BookingStatus? statusFilter;
  final String? selectedDriverFilter;
  final String? selectedAirportFilter;

  const BookingState({
    required this.bookings,
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.statusFilter,
    this.selectedDriverFilter,
    this.selectedAirportFilter,
  });

  List<BookingModel> get filteredBookings {
    return bookings.where((b) {
      final matchesSearch = b.id.toLowerCase().contains(searchQuery.toLowerCase()) ||
          b.referenceCode.toLowerCase().contains(searchQuery.toLowerCase()) ||
          b.guestName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          b.clientName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (b.driverName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

      final matchesStatus = statusFilter == null || b.status == statusFilter;
      final matchesDriver = selectedDriverFilter == null || b.driverId == selectedDriverFilter;
      final matchesAirport = selectedAirportFilter == null || b.airport == selectedAirportFilter;

      return matchesSearch && matchesStatus && matchesDriver && matchesAirport;
    }).toList();
  }

  List<BookingModel> get todayBookings => bookings.where((b) {
        return b.status != BookingStatus.cancelled && b.status != BookingStatus.completed;
      }).toList();

  List<BookingModel> get completedBookings =>
      bookings.where((b) => b.status == BookingStatus.completed).toList();

  List<BookingModel> get cancelledBookings =>
      bookings.where((b) => b.status == BookingStatus.cancelled).toList();

  BookingState copyWith({
    List<BookingModel>? bookings,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    BookingStatus? statusFilter,
    String? selectedDriverFilter,
    String? selectedAirportFilter,
    bool clearStatusFilter = false,
    bool clearDriverFilter = false,
    bool clearAirportFilter = false,
  }) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      selectedDriverFilter: clearDriverFilter ? null : (selectedDriverFilter ?? this.selectedDriverFilter),
      selectedAirportFilter: clearAirportFilter ? null : (selectedAirportFilter ?? this.selectedAirportFilter),
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final Ref _ref;
  final SmsService _smsService;

  BookingNotifier(this._ref, this._smsService)
      : super(
          BookingState(
            bookings: [
              BookingModel(
                id: 'AT-1048',
                referenceCode: 'REF-884920',
                clientName: 'Reliance Industries Ltd.',
                clientContact: '+91 22 2286 5000',
                clientReference: 'PO-2026-88',
                internalNotes: 'VIP Executive Pick up - Priority gate clearance required.',
                guestName: 'Rahul Shah',
                guestMobile: '+91 98980 12345',
                guestEmail: 'rahul.shah@reliance.com',
                passengersCount: 2,
                luggageCount: 2,
                isVip: true,
                specialAssistance: 'Wheelchair assistance requested',
                guestNotes: 'Will be holding a black leather briefcase',
                flightNumber: 'AI-542',
                flightType: 'Arrival',
                airport: 'Ahmedabad International (AMD)',
                terminal: 'Terminal 2',
                flightDate: '14 Aug 2026',
                flightTime: '09:45 AM',
                pickupDate: '14 Aug 2026',
                pickupTime: '10:00 AM',
                pickupLocation: 'Ahmedabad Airport T2 Arrival Exit',
                pickupTerminal: 'Terminal 2',
                pickupNotes: 'Driver should wait at Gate 3 with nameplate',
                destination: 'Courtyard by Marriott',
                destinationAddress: 'Ramdev Nagar Cross Road, Satellite, Ahmedabad',
                dropNotes: 'Deliver luggage to front concierge desk',
                vehicleId: 'VEH-001',
                vehicleType: 'Sedan',
                vehicleRegistration: 'GJ-01-AB-1234',
                driverId: 'DRV-101',
                driverName: 'Amit Patel',
                driverMobile: '+91 98765 43210',
                status: BookingStatus.onTheWayToPickup,
                reminderDuration: '2 hours',
                notifyPush: true,
                notifySms: true,
                smsStatus: 'SMS Pending (Provider not configured)',
                createdAt: DateTime.now().subtract(const Duration(hours: 3)),
                timeline: [
                  TimelineEventModel(
                    id: 'TL-101',
                    title: 'Booking Created',
                    description: 'Booking created by Admin (ADM-001)',
                    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
                    iconType: 'create',
                  ),
                  TimelineEventModel(
                    id: 'TL-102',
                    title: 'Driver & Vehicle Assigned',
                    description: 'Assigned to Amit Patel (GJ-01-AB-1234)',
                    timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
                    iconType: 'assign',
                  ),
                  TimelineEventModel(
                    id: 'TL-103',
                    title: 'Driver Notified',
                    description: 'Push notification & SMS sent to driver',
                    timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
                    iconType: 'notify',
                  ),
                  TimelineEventModel(
                    id: 'TL-104',
                    title: 'Driver Accepted',
                    description: 'Amit Patel confirmed booking assignment',
                    timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
                    iconType: 'accept',
                  ),
                  TimelineEventModel(
                    id: 'TL-105',
                    title: 'On the Way to Pickup',
                    description: 'Driver started navigation to Ahmedabad Airport T2',
                    timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
                    iconType: 'navigation',
                  ),
                ],
              ),
              BookingModel(
                id: 'AT-1049',
                referenceCode: 'REF-992314',
                clientName: 'Adani Group',
                clientContact: '+91 79 2656 5555',
                guestName: 'Priya Sharma',
                guestMobile: '+91 97234 11223',
                guestEmail: 'priya.sharma@adani.com',
                passengersCount: 1,
                luggageCount: 1,
                isVip: false,
                flightNumber: '6E-201',
                flightType: 'Departure',
                airport: 'Ahmedabad International (AMD)',
                terminal: 'Terminal 1',
                flightDate: '14 Aug 2026',
                flightTime: '04:30 PM',
                pickupDate: '14 Aug 2026',
                pickupTime: '02:00 PM',
                pickupLocation: 'Hyatt Regency, Ashram Road',
                destination: 'Ahmedabad Airport T1 Departure',
                destinationAddress: 'Hansol, Ahmedabad',
                vehicleId: 'VEH-002',
                vehicleType: 'SUV',
                vehicleRegistration: 'GJ-01-CD-5678',
                driverId: 'DRV-102',
                driverName: 'Vikram Singh',
                driverMobile: '+91 98234 56789',
                status: BookingStatus.assigned,
                reminderDuration: '2 hours',
                createdAt: DateTime.now().subtract(const Duration(hours: 1)),
                timeline: [
                  TimelineEventModel(
                    id: 'TL-201',
                    title: 'Booking Created',
                    description: 'Booking created by Admin',
                    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
                    iconType: 'create',
                  ),
                  TimelineEventModel(
                    id: 'TL-202',
                    title: 'Driver Assigned',
                    description: 'Assigned to Vikram Singh',
                    timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
                    iconType: 'assign',
                  ),
                ],
              ),
            ],
          ),
        ) {
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      final response = await Supabase.instance.client
          .from('bookings')
          .select('*');

      if (response.isNotEmpty) {
        final fetched = response
            .map((e) => BookingModel.fromSupabase(e))
            .toList();
        state = state.copyWith(bookings: fetched, isLoading: false);
      }
    } catch (_) {
      // Fallback to local default bookings if table missing or offline
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(BookingStatus? status) {
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null);
  }

  Future<String> createBooking({
    required String clientName,
    required String clientContact,
    String? clientReference,
    String? internalNotes,
    required String guestName,
    required String guestMobile,
    required String guestEmail,
    required int passengersCount,
    required int luggageCount,
    required bool isVip,
    String? specialAssistance,
    String? guestNotes,
    required String flightNumber,
    required String flightType,
    required String airport,
    required String terminal,
    required String flightDate,
    required String flightTime,
    required String pickupDate,
    required String pickupTime,
    required String pickupLocation,
    String? pickupTerminal,
    String? pickupNotes,
    required String destination,
    required String destinationAddress,
    String? dropNotes,
    required String vehicleId,
    required String vehicleType,
    required String vehicleReg,
    required String driverId,
    required String driverName,
    required String driverMobile,
    required String reminderDuration,
    required bool notifyPush,
    required bool notifySms,
  }) async {
    state = state.copyWith(isLoading: true);

    // SMS Trigger Check
    final smsResult = await _smsService.sendAssignmentSms(
      recipientMobile: driverMobile,
      bookingCode: 'AT-PENDING',
      guestName: guestName,
      pickupLocation: pickupLocation,
      pickupTime: pickupTime,
    );

    final now = DateTime.now();

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      String? companyId;
      if (user != null) {
        final profileRes = await client.from('profiles').select('company_id').eq('id', user.id).maybeSingle();
        companyId = profileRes?['company_id']?.toString();
      }

      final insertData = {
        'client_name': clientName,
        'client_contact': clientContact,
        if (clientReference != null && clientReference.trim().isNotEmpty) 'client_reference': clientReference.trim(),
        if (internalNotes != null && internalNotes.trim().isNotEmpty) 'internal_notes': internalNotes.trim(),
        'guest_name': guestName,
        'guest_mobile': guestMobile,
        'guest_email': guestEmail,
        'passengers_count': passengersCount,
        'luggage_count': luggageCount,
        'is_vip': isVip,
        if (specialAssistance != null && specialAssistance.trim().isNotEmpty) 'special_assistance': specialAssistance.trim(),
        if (guestNotes != null && guestNotes.trim().isNotEmpty) 'guest_notes': guestNotes.trim(),
        'flight_number': flightNumber,
        'flight_type': flightType,
        'airport': airport,
        'terminal': terminal,
        'flight_date': flightDate,
        'flight_time': flightTime,
        'pickup_date': pickupDate,
        'pickup_time': pickupTime,
        'pickup_location': pickupLocation,
        if (pickupTerminal != null && pickupTerminal.trim().isNotEmpty) 'pickup_terminal': pickupTerminal.trim(),
        if (pickupNotes != null && pickupNotes.trim().isNotEmpty) 'pickup_notes': pickupNotes.trim(),
        'destination': destination,
        'destination_address': destinationAddress,
        if (dropNotes != null && dropNotes.trim().isNotEmpty) 'drop_notes': dropNotes.trim(),
        'vehicle_id': vehicleId,
        'vehicle_type': vehicleType,
        'vehicle_registration': vehicleReg,
        'driver_id': driverId,
        'driver_name': driverName,
        'driver_mobile': driverMobile,
        'status': 'assigned',
        'reminder_duration': reminderDuration,
        'notify_push': notifyPush,
        'notify_sms': notifySms,
        'sms_status': smsResult.statusMessage,
        if (companyId != null) 'company_id': companyId,
      };

      final response = await client.from('bookings').insert(insertData).select().single();
      final insertedBookingId = (response['id'] ?? '').toString();

      _ref.read(notificationProvider.notifier).addNotification(
            title: 'New Airport Transfer Assigned',
            message: 'Booking $insertedBookingId assigned to $driverName. Guest: $guestName. Pickup: $pickupLocation at $pickupTime.',
            type: NotificationType.driverAssigned,
            bookingId: insertedBookingId,
          );

      _ref.read(notificationProvider.notifier).scheduleReminder(
            bookingId: insertedBookingId,
            driverId: driverId,
            durationLabel: reminderDuration,
            pickupTime: now.add(const Duration(hours: 2)),
            notifyPush: notifyPush,
            notifySms: notifySms,
          );

      await fetchBookings();
      return insertedBookingId.isEmpty ? 'AT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}' : insertedBookingId;
    } catch (_) {
      // Local fallback execution if database endpoint unreachable
      final fallbackId = 'AT-${1048 + state.bookings.length + 1}';
      final refCode = 'REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final timeline = [
        TimelineEventModel(
          id: 'TL_${now.millisecondsSinceEpoch}_1',
          title: 'Booking Created',
          description: 'Booking created by Admin',
          timestamp: now,
          iconType: 'create',
        ),
        TimelineEventModel(
          id: 'TL_${now.millisecondsSinceEpoch}_2',
          title: 'Driver & Vehicle Assigned',
          description: 'Assigned to $driverName ($vehicleReg)',
          timestamp: now.add(const Duration(seconds: 1)),
          iconType: 'assign',
        ),
        TimelineEventModel(
          id: 'TL_${now.millisecondsSinceEpoch}_3',
          title: 'Driver Notified',
          description: 'Notification status: ${smsResult.statusMessage}',
          timestamp: now.add(const Duration(seconds: 2)),
          iconType: 'notify',
        ),
      ];

      final newBooking = BookingModel(
        id: fallbackId,
        referenceCode: refCode,
        clientName: clientName,
        clientContact: clientContact,
        clientReference: clientReference,
        internalNotes: internalNotes,
        guestName: guestName,
        guestMobile: guestMobile,
        guestEmail: guestEmail,
        passengersCount: passengersCount,
        luggageCount: luggageCount,
        isVip: isVip,
        specialAssistance: specialAssistance,
        guestNotes: guestNotes,
        flightNumber: flightNumber,
        flightType: flightType,
        airport: airport,
        terminal: terminal,
        flightDate: flightDate,
        flightTime: flightTime,
        pickupDate: pickupDate,
        pickupTime: pickupTime,
        pickupLocation: pickupLocation,
        pickupTerminal: pickupTerminal,
        pickupNotes: pickupNotes,
        destination: destination,
        destinationAddress: destinationAddress,
        dropNotes: dropNotes,
        vehicleId: vehicleId,
        vehicleType: vehicleType,
        vehicleRegistration: vehicleReg,
        driverId: driverId,
        driverName: driverName,
        driverMobile: driverMobile,
        status: BookingStatus.assigned,
        reminderDuration: reminderDuration,
        notifyPush: notifyPush,
        notifySms: notifySms,
        smsStatus: smsResult.statusMessage,
        createdAt: now,
        timeline: timeline,
      );

      _ref.read(notificationProvider.notifier).addNotification(
            title: 'New Airport Transfer Assigned',
            message: 'Booking $fallbackId assigned to $driverName. Guest: $guestName. Pickup: $pickupLocation at $pickupTime.',
            type: NotificationType.driverAssigned,
            bookingId: fallbackId,
          );

      _ref.read(notificationProvider.notifier).scheduleReminder(
            bookingId: fallbackId,
            driverId: driverId,
            durationLabel: reminderDuration,
            pickupTime: now.add(const Duration(hours: 2)),
            notifyPush: notifyPush,
            notifySms: notifySms,
          );

      state = state.copyWith(
        bookings: [newBooking, ...state.bookings],
        isLoading: false,
      );

      return fallbackId;
    }
  }


  Future<void> reassignDriver({
    required String bookingId,
    required String newDriverId,
    required String newDriverName,
    required String newDriverMobile,
    required String newVehicleId,
    required String newVehicleReg,
    required String newVehicleType,
  }) async {
    final now = DateTime.now();

    final updated = state.bookings.map((b) {
      if (b.id == bookingId) {
        final oldDriverName = b.driverName ?? 'Previous driver';

        final newTimeline = [
          ...b.timeline,
          TimelineEventModel(
            id: 'TL_${now.millisecondsSinceEpoch}',
            title: 'Driver Reassigned',
            description: 'Reassigned from $oldDriverName to $newDriverName ($newVehicleReg)',
            timestamp: now,
            iconType: 'reassign',
          ),
        ];

        return b.copyWith(
          driverId: newDriverId,
          driverName: newDriverName,
          driverMobile: newDriverMobile,
          vehicleId: newVehicleId,
          vehicleRegistration: newVehicleReg,
          vehicleType: newVehicleType,
          status: BookingStatus.assigned,
          timeline: newTimeline,
        );
      }
      return b;
    }).toList();

    // Cancel old reminder & notify
    _ref.read(notificationProvider.notifier).cancelReminder(bookingId);
    _ref.read(notificationProvider.notifier).addNotification(
          title: 'Driver Reassigned',
          message: 'Booking $bookingId reassigned to $newDriverName.',
          type: NotificationType.driverAssigned,
          bookingId: bookingId,
        );

    state = state.copyWith(bookings: updated);
  }

  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    final now = DateTime.now();

    final updated = state.bookings.map((b) {
      if (b.id == bookingId) {
        final newTimeline = [
          ...b.timeline,
          TimelineEventModel(
            id: 'TL_${now.millisecondsSinceEpoch}',
            title: 'Booking Cancelled',
            description: 'Cancelled by Admin. Reason: $reason',
            timestamp: now,
            iconType: 'cancel',
          ),
        ];

        return b.copyWith(
          status: BookingStatus.cancelled,
          cancellationReason: reason,
          timeline: newTimeline,
        );
      }
      return b;
    }).toList();

    // Cancel reminder
    _ref.read(notificationProvider.notifier).cancelReminder(bookingId);
    _ref.read(notificationProvider.notifier).addNotification(
          title: 'Booking Cancelled',
          message: 'Booking $bookingId was cancelled. Reason: $reason',
          type: NotificationType.bookingCancelled,
          bookingId: bookingId,
        );

    state = state.copyWith(bookings: updated);
  }

  void updateBookingStatus(String bookingId, BookingStatus newStatus) {
    final now = DateTime.now();

    final updated = state.bookings.map((b) {
      if (b.id == bookingId) {
        final newTimeline = [
          ...b.timeline,
          TimelineEventModel(
            id: 'TL_${now.millisecondsSinceEpoch}',
            title: newStatus.displayName,
            description: 'Status updated to ${newStatus.displayName}',
            timestamp: now,
            iconType: 'status',
          ),
        ];

        return b.copyWith(status: newStatus, timeline: newTimeline);
      }
      return b;
    }).toList();



    state = state.copyWith(bookings: updated);
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  final smsService = SmsService(isConfigured: false);
  return BookingNotifier(ref, smsService);
});

final bookingDetailsProvider = Provider.family<BookingModel?, String>((ref, bookingId) {
  final state = ref.watch(bookingProvider);
  try {
    return state.bookings.firstWhere((b) => b.id == bookingId);
  } catch (_) {
    return null;
  }
});
