import 'dart:async';
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
    return bookings.where((booking) {
      final matchesSearch = booking.guestName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          booking.guestMobile.contains(searchQuery) ||
          booking.referenceCode.toLowerCase().contains(searchQuery.toLowerCase()) ||
          booking.flightNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (booking.driverName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

      final matchesStatus = statusFilter == null || booking.status == statusFilter;

      final matchesDriver = selectedDriverFilter == null ||
          selectedDriverFilter!.isEmpty ||
          booking.driverName == selectedDriverFilter;

      final matchesAirport = selectedAirportFilter == null ||
          selectedAirportFilter!.isEmpty ||
          booking.airport == selectedAirportFilter;

      return matchesSearch && matchesStatus && matchesDriver && matchesAirport;
    }).toList();
  }

  List<BookingModel> get todayBookings => bookings.where((b) {
        return b.status != BookingStatus.cancelled && b.status != BookingStatus.completed;
      }).toList();

  List<BookingModel> get pendingBookings =>
      bookings.where((b) => b.status == BookingStatus.pending).toList();

  List<BookingModel> get confirmedBookings =>
      bookings.where((b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.assigned).toList();

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
  StreamSubscription<AuthState>? _authSubscription;

  BookingNotifier(this._ref, this._smsService)
      : super(
          const BookingState(
            bookings: [],
          ),
        ) {
    fetchBookings();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed ||
          data.event == AuthChangeEvent.initialSession) {
        fetchBookings();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchBookings() async {
    state = state.copyWith(isLoading: true);
    try {
      final client = Supabase.instance.client;
      var user = client.auth.currentUser;

      if (user == null && client.auth.currentSession == null) {
        await Future.delayed(const Duration(milliseconds: 600));
        user = client.auth.currentUser;
      }

      if (user == null) {
        state = state.copyWith(bookings: [], isLoading: false);
        return;
      }

      final profileRes = await client.from('profiles').select('company_id').eq('id', user.id).maybeSingle();
      final companyId = profileRes?['company_id']?.toString();

      dynamic response;
      try {
        print('🔍 [BookingRepo] Fetching bookings with relational join...');
        var query = client.from('bookings').select('*, drivers(*), vehicles(*)');
        if (companyId != null && companyId.isNotEmpty) {
          response = await query.eq('company_id', companyId).order('created_at', ascending: false);
        } else {
          response = await query.order('created_at', ascending: false);
        }
      } catch (e, st) {
        print('❌ [BookingRepo] Relational fetch failed, falling back: $e');
        try {
          var query = client.from('bookings').select('*');
          if (companyId != null && companyId.isNotEmpty) {
            response = await query.eq('company_id', companyId).order('created_at', ascending: false);
          } else {
            response = await query.order('created_at', ascending: false);
          }
        } catch (_) {
          response = [];
        }
      }

      final fetched = (response as List)
          .map((e) => BookingModel.fromSupabase(Map<String, dynamic>.from(e as Map)))
          .toList();
      print('📦 [BookingRepo] Loaded ${fetched.length} bookings successfully.');
      state = state.copyWith(bookings: fetched, isLoading: false);
    } catch (e, st) {
      print('❌ [BookingRepo] Error in fetchBookings: $e');
      state = state.copyWith(bookings: [], isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(BookingStatus? status) {
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null);
  }

  Future<void> createBookingFromMap(Map<String, dynamic> data) async {
    final pickup = (data['pickup_location'] ?? data['origin'] ?? '').toString();
    final dropoff = (data['dropoff_location'] ?? data['destination'] ?? '').toString();
    final passengerName = (data['passenger_name'] ?? data['customer_name'] ?? data['guest_name'] ?? 'Passenger').toString();
    final passengerPhone = (data['passenger_phone'] ?? data['customer_phone'] ?? data['guest_mobile'] ?? '').toString();
    final pickupTime = (data['pickup_time'] ?? data['pickup_datetime'] ?? DateTime.now().toIso8601String()).toString();
    final driverId = data['driver_id']?.toString();
    final vehicleId = data['vehicle_id']?.toString();
    final flightNumber = data['flight_number']?.toString();
    final terminal = data['terminal']?.toString();

    await createBooking(
      guestName: passengerName,
      guestMobile: passengerPhone,
      guestEmail: (data['guest_email'] ?? '').toString(),
      passengersCount: int.tryParse(data['passengers_count']?.toString() ?? '') ?? 1,
      luggageCount: int.tryParse(data['luggage_count']?.toString() ?? '') ?? 1,
      isVip: data['is_vip'] == true,
      flightNumber: flightNumber ?? '',
      flightType: (data['flight_type'] ?? 'Arrival').toString(),
      airport: (data['airport'] ?? '').toString(),
      terminal: terminal ?? '',
      flightDate: (data['flight_date'] ?? '').toString(),
      flightTime: pickupTime,
      pickupDate: (data['pickup_date'] ?? '').toString(),
      pickupTime: pickupTime,
      pickupLocation: pickup,
      destination: dropoff,
      destinationAddress: dropoff,
      vehicleId: vehicleId ?? '',
      vehicleType: (data['vehicle_type'] ?? 'Sedan').toString(),
      vehicleReg: (data['vehicle_registration'] ?? '').toString(),
      driverId: driverId ?? '',
      driverName: (data['driver_name'] ?? '').toString(),
      driverMobile: (data['driver_mobile'] ?? '').toString(),
      reminderDuration: (data['reminder_duration'] ?? '2 hours').toString(),
      notifyPush: data['notify_push'] != false,
      notifySms: data['notify_sms'] != false,
    );
  }

  Future<String> createBooking({
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
    bool notifyClientDriverDetails = true,
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

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      String? companyId;
      if (user != null) {
        final profileRes = await client.from('profiles').select('company_id').eq('id', user.id).maybeSingle();
        companyId = profileRes?['company_id']?.toString();
      }

      final insertData = <String, dynamic>{
        'passenger_name': guestName,
        'customer_name': guestName,
        'passenger_phone': guestMobile,
        'customer_phone': guestMobile,
        if (clientReference != null && clientReference.trim().isNotEmpty) 'booking_reference': clientReference.trim(),
        if (internalNotes != null && internalNotes.trim().isNotEmpty) 'notes': internalNotes.trim(),
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
        'pickup_datetime': pickupDate,
        'pickup_location': pickupLocation,
        'origin': pickupLocation,
        if (pickupTerminal != null && pickupTerminal.trim().isNotEmpty) 'pickup_terminal': pickupTerminal.trim(),
        if (pickupNotes != null && pickupNotes.trim().isNotEmpty) 'pickup_notes': pickupNotes.trim(),
        'destination': destination,
        'destination_address': destinationAddress,
        'dropoff_location': destination,
        if (dropNotes != null && dropNotes.trim().isNotEmpty) 'drop_notes': dropNotes.trim(),
        if (vehicleId.isNotEmpty) 'vehicle_id': vehicleId,
        'vehicle_type': vehicleType,
        'vehicle_registration': vehicleReg,
        if (driverId.isNotEmpty) 'driver_id': driverId,
        'driver_name': driverName,
        'driver_mobile': driverMobile,
        'status': 'assigned',
        'booking_status': 'assigned',
        'reminder_duration': reminderDuration,
        'notify_push': notifyPush,
        'notify_sms': notifySms,
        'notify_client_driver_details': notifyClientDriverDetails,
        'sms_status': smsResult.statusMessage,
        if (companyId != null) 'company_id': companyId,
      };

      print('🚀 [BookingRepo] Inserting booking payload: $insertData');
      dynamic response;
      try {
        response = await client.from('bookings').insert(insertData).select().single();
      } catch (e) {
        print('⚠️ [BookingRepo] Full payload insert error: $e. Retrying with sanitized location payload...');
        final sanitizedData = Map<String, dynamic>.from(insertData);
        final errStr = e.toString();
        if (errStr.contains('destination')) {
          sanitizedData.remove('destination');
        }
        if (errStr.contains('origin')) {
          sanitizedData.remove('origin');
        }
        if (errStr.contains('customer_name')) {
          sanitizedData.remove('customer_name');
        }
        if (errStr.contains('customer_phone')) {
          sanitizedData.remove('customer_phone');
        }
        if (errStr.contains('booking_status')) {
          sanitizedData.remove('booking_status');
        }
        try {
          response = await client.from('bookings').insert(sanitizedData).select().single();
        } catch (_) {
          print('⚠️ [BookingRepo] Retrying with core essential payload...');
          final coreData = {
            'passenger_name': guestName,
            'passenger_phone': guestMobile,
            'pickup_location': pickupLocation,
            'dropoff_location': destination,
            'status': 'assigned',
            if (flightNumber.isNotEmpty) 'flight_number': flightNumber,
            if (terminal.isNotEmpty) 'terminal': terminal,
            if (vehicleId.isNotEmpty) 'vehicle_id': vehicleId,
            if (driverId.isNotEmpty) 'driver_id': driverId,
            if (companyId != null) 'company_id': companyId,
          };
          response = await client.from('bookings').insert(coreData).select().single();
        }
      }

      final newBookingId = (response['id'] ?? '').toString();
      print('✅ [BookingRepo] Booking created successfully: $newBookingId');

      if (notifyClientDriverDetails && guestMobile.isNotEmpty) {
        final clientMessageText = '''
Hello $guestName, your transfer has been scheduled!
🚗 Vehicle: $vehicleType ($vehicleReg)
👤 Driver: $driverName ($driverMobile)
📍 Pickup: $pickupLocation at $pickupTime
Thank you for choosing your airport transfer provider!''';

        try {
          await client.from('message_logs').insert({
            if (companyId != null) 'company_id': companyId,
            'booking_id': newBookingId,
            'recipient': guestMobile,
            'type': 'client_driver_assignment',
            'content': clientMessageText,
            'status': 'sent',
          });
        } catch (_) {}
      }

      _ref.read(notificationProvider.notifier).addNotification(
            title: 'New Airport Transfer Assigned',
            message: 'Booking $newBookingId assigned to $driverName. Guest: $guestName. Pickup: $pickupLocation at $pickupTime.',
            type: NotificationType.driverAssigned,
            bookingId: newBookingId,
          );

      // Re-fetch bookings immediately to update state
      await fetchBookings();
      return newBookingId;
    } catch (e, st) {
      print('❌ [BookingRepo] CREATE BOOKING FAILED: $e');
      print(st);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
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
