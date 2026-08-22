import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../drivers/data/driver_repository.dart';
import '../../drivers/domain/driver_model.dart';
import '../../vehicles/domain/vehicle_model.dart';
import '../../../core/services/whatsapp_service.dart';
import '../data/booking_repository.dart';
import '../domain/booking_model.dart';
import '../domain/passenger_form_item.dart';
import '../../../core/widgets/responsive_layout.dart';

class CreateBookingPage extends ConsumerStatefulWidget {
  const CreateBookingPage({super.key});

  @override
  ConsumerState<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends ConsumerState<CreateBookingPage> {
  final _formKey = GlobalKey<FormState>();

  // Section 1: Booked By
  final _bookedByNameController = TextEditingController();
  final _bookedByPhoneController = TextEditingController();
  final _wbsNoController = TextEditingController();

  // Section 2: Dynamic Passenger & Route List
  int _passengerCount = 1;
  List<PassengerFormItem> _passengerList = [PassengerFormItem()];

  void _updatePassengerCount(int count) {
    if (count == _passengerCount) return;
    setState(() {
      _passengerCount = count;
      while (_passengerList.length < count) {
        final defaultPickup = _passengerList.isNotEmpty ? _passengerList[0].pickupController.text : '';
        final defaultDropoff = _passengerList.isNotEmpty ? _passengerList[0].dropoffController.text : '';
        _passengerList.add(PassengerFormItem(pickup: defaultPickup, dropoff: defaultDropoff));
      }
      while (_passengerList.length > count) {
        final item = _passengerList.removeLast();
        item.dispose();
      }
    });
  }

  final _guestNameController = TextEditingController();
  final _guestMobileController = TextEditingController();
  final _guestEmailController = TextEditingController();
  final _clientRefController = TextEditingController();
  final _internalNotesController = TextEditingController();
  int _passengersCount = 1;
  int _luggageCount = 1;
  bool _isVip = false;
  final _specialAssistanceController = TextEditingController();
  final _guestNotesController = TextEditingController();

  // Section 2: Trip Route
  final _pickupLocationController = TextEditingController();
  final _pickupNotesController = TextEditingController();
  final _destinationController = TextEditingController();
  final _destinationAddressController = TextEditingController();
  final _dropNotesController = TextEditingController();

  // Section 3: Schedule
  String _tripType = 'single_day'; // 'single_day' or 'multi_day'
  DateTime _pickupDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  int _durationDays = 1;
  TimeOfDay _pickupTime = const TimeOfDay(hour: 10, minute: 0);

  // Section 4: Driver & Vehicle Selection
  DriverModel? _selectedDriver;
  VehicleModel? get _selectedVehicle => _selectedDriver?.vehicle;
  List<DriverModel>? _supabaseActiveDrivers;

  // Section 5: Reminder & Notification Setup
  String _reminderDuration = '2 hours';
  bool _notifyClientDriverDetails = true;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchSupabaseActiveDrivers();
  }

  Future<void> _fetchSupabaseActiveDrivers() async {
    try {
      final response = await Supabase.instance.client
          .from('drivers')
          .select('*, vehicles(*)')
          .or('status.eq.Active (Ready),status.eq.active');
      if (response.isNotEmpty && mounted) {
        setState(() {
          _supabaseActiveDrivers = response
              .map((e) => DriverModel.fromSupabase(e))
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final item in _passengerList) {
      item.dispose();
    }
    _bookedByNameController.dispose();
    _bookedByPhoneController.dispose();
    _wbsNoController.dispose();
    _clientRefController.dispose();
    _internalNotesController.dispose();
    _guestNameController.dispose();
    _guestMobileController.dispose();
    _guestEmailController.dispose();
    _specialAssistanceController.dispose();
    _guestNotesController.dispose();
    _pickupLocationController.dispose();
    _pickupNotesController.dispose();
    _destinationController.dispose();
    _destinationAddressController.dispose();
    _dropNotesController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all required fields.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedDriver == null || _selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an active driver with an assigned vehicle.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final combinedStartDateTime = DateTime(
        _pickupDate.year,
        _pickupDate.month,
        _pickupDate.day,
        _pickupTime.hour,
        _pickupTime.minute,
      );
      final pickupDateStr = DateFormat('yyyy-MM-dd').format(_pickupDate);
      final pickupTimeStr = _pickupTime.format(context);
      const totalFare = 0.0;

      final primaryP = _passengerList.isNotEmpty ? _passengerList[0] : PassengerFormItem();
      final pName = primaryP.nameController.text.trim().isNotEmpty
          ? primaryP.nameController.text.trim()
          : _guestNameController.text.trim();
      final pPhone = primaryP.phoneController.text.trim().isNotEmpty
          ? primaryP.phoneController.text.trim()
          : _guestMobileController.text.trim();
      final pPick = primaryP.pickupController.text.trim().isNotEmpty
          ? primaryP.pickupController.text.trim()
          : _pickupLocationController.text.trim();
      final pDrop = primaryP.dropoffController.text.trim().isNotEmpty
          ? primaryP.dropoffController.text.trim()
          : (_destinationController.text.trim().isNotEmpty
              ? _destinationController.text.trim()
              : _destinationAddressController.text.trim());

      final payload = <String, dynamic>{
        'booked_by_name': _bookedByNameController.text.trim(),
        'booked_by_phone': _bookedByPhoneController.text.trim(),
        'wbs_no': _wbsNoController.text.trim(),
        'passenger_name': pName,
        'customer_name': pName,
        'passenger_phone': pPhone,
        'customer_phone': pPhone,
        'guest_email': _guestEmailController.text.trim(),
        'pickup_location': pPick,
        'dropoff_location': pDrop,
        'origin': pPick,
        'destination': pDrop,
        'passengers': _passengerList.map((p) => p.toJson()).toList(),
        'trip_type': _tripType,
        'start_date': _pickupDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
        'duration_days': _durationDays,
        'pickup_time': combinedStartDateTime.toIso8601String(),
        'pickup_datetime': combinedStartDateTime.toIso8601String(),
        'total_fare': totalFare,
        'amount': totalFare,
        'status': 'assigned',
        'booking_status': 'assigned',
        'driver_id': _selectedDriver?.id,
        'vehicle_id': _selectedVehicle?.id,
        'driver_name': _selectedDriver?.name,
        'driver_mobile': _selectedDriver?.mobile,
        'vehicle_registration': _selectedVehicle?.registrationNumber,
        'vehicle_type': _selectedVehicle?.type.name.toUpperCase(),
        'notes': _internalNotesController.text.trim(),
        'booking_reference': _clientRefController.text.trim(),
        'passenger_count': _passengerCount,
        'passengers_count': _passengerCount,
        'luggage_count': _luggageCount,
        'is_vip': _isVip,
        'special_assistance': _specialAssistanceController.text.trim(),
        'reminder_duration': _reminderDuration,
        'notify_client_driver_details': _notifyClientDriverDetails,
      };

      final newBookingId = await ref.read(bookingProvider.notifier).createBookingFromMapWithId(payload);

      if (mounted) {
        if (_notifyClientDriverDetails) {
          final createdBooking = BookingModel(
            id: newBookingId,
            referenceCode: newBookingId.length >= 6 ? 'BK-${newBookingId.substring(0, 6).toUpperCase()}' : 'BK-TRIP',
            bookedByName: _bookedByNameController.text.trim(),
            bookedByPhone: _bookedByPhoneController.text.trim(),
            wbsNo: _wbsNoController.text.trim(),
            guestName: pName,
            guestMobile: pPhone,
            guestEmail: _guestEmailController.text.trim(),
            passengersCount: _passengerCount,
            luggageCount: _luggageCount,
            flightNumber: '',
            flightType: 'Arrival',
            airport: '',
            terminal: '',
            flightDate: '',
            flightTime: '',
            pickupDate: pickupDateStr,
            pickupTime: pickupTimeStr,
            pickupLocation: pPick,
            destination: pDrop,
            destinationAddress: pDrop,
            passengers: _passengerList.map((p) => p.toJson()).toList(),
            vehicleType: '${_selectedVehicle!.make} ${_selectedVehicle!.model}',
            vehicleRegistration: _selectedVehicle!.registrationNumber,
            driverName: _selectedDriver!.name,
            driverMobile: _selectedDriver!.mobile,
            status: BookingStatus.assigned,
            createdAt: DateTime.now(),
            timeline: const [],
            tripType: _tripType,
            startDate: DateFormat('yyyy-MM-dd').format(_pickupDate),
            endDate: DateFormat('yyyy-MM-dd').format(_endDate),
            durationDays: _durationDays,
          );

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => _buildSuccessDialog(dialogContext, createdBooking),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking $newBookingId created successfully.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/admin/bookings');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create booking: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);
    final activeDrivers = _supabaseActiveDrivers ?? driverState.activeDrivers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Create New Booking', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => context.go('/admin/bookings'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: Booked By
              _buildBookedBySection(),

              // SECTION 2: Dynamic Passenger & Route Details
              _buildDynamicPassengersSection(),

              // SECTION 3: Additional Booking Details
              _buildSectionCard(
                sectionNumber: '3',
                title: 'Additional Booking Details',
                icon: Icons.tune_outlined,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _guestEmailController,
                            decoration: const InputDecoration(labelText: 'Email Address'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _luggageCount,
                            decoration: const InputDecoration(labelText: 'Luggage Count'),
                            items: List.generate(10, (i) => i + 1)
                                .map((val) => DropdownMenuItem(value: val, child: Text('$val Bags')))
                                .toList(),
                            onChanged: (val) => setState(() => _luggageCount = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _clientRefController,
                            decoration: const InputDecoration(labelText: 'Booking Reference / PO #'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _internalNotesController,
                            decoration: const InputDecoration(labelText: 'Internal Notes'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Switch(
                          value: _isVip,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _isVip = val),
                        ),
                        const SizedBox(width: 8),
                        const Text('VIP / Priority Guest', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _specialAssistanceController,
                            decoration: const InputDecoration(labelText: 'Special Assistance Notes'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _guestNotesController,
                            decoration: const InputDecoration(labelText: 'Guest Notes'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pickupNotesController,
                            decoration: const InputDecoration(labelText: 'Pickup Instructions / Landmark Notes'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _dropNotesController,
                            decoration: const InputDecoration(labelText: 'Dropoff Instructions'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 4: Trip Schedule
              _buildSectionCard(
                sectionNumber: '4',
                title: 'Trip Schedule',
                icon: Icons.calendar_month_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip Type Selector
                    Row(
                      children: [
                        _buildTripTypeChip(
                          label: 'Single Day Transfer',
                          isSelected: _tripType == 'single_day',
                          onTap: () {
                            setState(() {
                              _tripType = 'single_day';
                              _durationDays = 1;
                              _endDate = _pickupDate;
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildTripTypeChip(
                          label: 'Multi-Day Package (e.g. 5 Days)',
                          isSelected: _tripType == 'multi_day',
                          onTap: () {
                            setState(() {
                              _tripType = 'multi_day';
                              if (_durationDays <= 1) {
                                _durationDays = 5;
                                _endDate = _pickupDate.add(const Duration(days: 4));
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_tripType == 'single_day') ...[
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              tileColor: AppColors.secondarySurface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              leading: const Icon(Icons.calendar_month, color: AppColors.primary),
                              title: const Text('Pickup Date *', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                              subtitle: Text(DateFormat('dd MMM yyyy').format(_pickupDate), style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _pickupDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _pickupDate = picked;
                                    _endDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ListTile(
                              tileColor: AppColors.secondarySurface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              leading: const Icon(Icons.access_time, color: AppColors.primary),
                              title: const Text('Pickup Time *', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                              subtitle: Text(_pickupTime.format(context), style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                              onTap: () async {
                                final picked = await showTimePicker(context: context, initialTime: _pickupTime);
                                if (picked != null) setState(() => _pickupTime = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ListTile(
                              tileColor: AppColors.secondarySurface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              leading: const Icon(Icons.date_range, color: AppColors.primary),
                              title: const Text('Trip Date Range *', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                              subtitle: Text(
                                '${DateFormat('dd MMM').format(_pickupDate)} ➔ ${DateFormat('dd MMM yyyy').format(_endDate)} ($_durationDays Days)',
                                style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
                              ),
                              onTap: () async {
                                final pickedRange = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  initialDateRange: DateTimeRange(start: _pickupDate, end: _endDate),
                                );
                                if (pickedRange != null) {
                                  setState(() {
                                    _pickupDate = pickedRange.start;
                                    _endDate = pickedRange.end;
                                    _durationDays = pickedRange.end.difference(pickedRange.start).inDays + 1;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.secondarySurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Duration', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                                      Text('$_durationDays Days', style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.secondaryText),
                                        onPressed: _durationDays > 2
                                            ? () => setState(() {
                                                  _durationDays--;
                                                  _endDate = _pickupDate.add(Duration(days: _durationDays - 1));
                                                })
                                            : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                                        onPressed: () => setState(() {
                                          _durationDays++;
                                          _endDate = _pickupDate.add(Duration(days: _durationDays - 1));
                                        }),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ListTile(
                              tileColor: AppColors.secondarySurface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              leading: const Icon(Icons.access_time, color: AppColors.primary),
                              title: const Text('Daily Pickup Time', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                              subtitle: Text(_pickupTime.format(context), style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                              onTap: () async {
                                final picked = await showTimePicker(context: context, initialTime: _pickupTime);
                                if (picked != null) setState(() => _pickupTime = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 5: Driver & Vehicle Assignment
              _buildSectionCard(
                sectionNumber: '5',
                title: 'Driver & Vehicle Assignment',
                icon: Icons.badge_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<DriverModel>(
                      value: _selectedDriver,
                      decoration: const InputDecoration(labelText: 'Select Active Driver *'),
                      hint: const Text('Choose available active driver'),
                      items: activeDrivers
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('${d.name} (${d.mobile}) — Upcoming: ${d.upcomingBookingsCount} bookings'),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedDriver = val),
                      validator: (v) {
                        if (v == null) return 'Driver assignment required';
                        if (v.vehicle == null) return 'Selected driver has no vehicle assigned';
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '* Selecting an active driver automatically links their assigned vehicle.',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                    ),
                    const SizedBox(height: 16),
                    _selectedDriver != null && _selectedVehicle != null
                        ? _buildAssignedVehicleCard(_selectedDriver!, _selectedVehicle!)
                        : _buildVehiclePlaceholder(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 6: Reminder & Notification Setup
              _buildSectionCard(
                sectionNumber: '6',
                title: 'Reminder & Notification Setup',
                icon: Icons.notifications_active_outlined,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _reminderDuration,
                      decoration: const InputDecoration(labelText: 'Driver Reminder Schedule *'),
                      items: const [
                        DropdownMenuItem(value: '15 minutes', child: Text('15 Minutes Before Pickup')),
                        DropdownMenuItem(value: '30 minutes', child: Text('30 Minutes Before Pickup')),
                        DropdownMenuItem(value: '1 hour', child: Text('1 Hour Before Pickup')),
                        DropdownMenuItem(value: '2 hours', child: Text('2 Hours Before Pickup')),
                        DropdownMenuItem(value: '6 hours', child: Text('6 Hours Before Pickup')),
                        DropdownMenuItem(value: '12 hours', child: Text('12 Hours Before Pickup')),
                        DropdownMenuItem(value: '24 hours', child: Text('24 Hours Before Pickup')),
                      ],
                      onChanged: (val) => setState(() => _reminderDuration = val!),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _notifyClientDriverDetails,
                            activeColor: AppColors.primary,
                            title: const Row(
                              children: [
                                Icon(Icons.send_to_mobile, color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Send Driver & Vehicle Details to Client (SMS / WhatsApp)',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: const Padding(
                              padding: EdgeInsets.only(top: 4, left: 28),
                              child: Text(
                                'Automatically send an SMS/message with driver contact and vehicle info to the passenger upon assignment.',
                                style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                              ),
                            ),
                            onChanged: (val) => setState(() => _notifyClientDriverDetails = val),
                          ),
                          if (_notifyClientDriverDetails) ...[
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.phone_android, color: AppColors.primary, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Recipient: ${_guestMobileController.text.trim().isNotEmpty ? _guestMobileController.text.trim() : "Passenger Mobile"}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chat, color: AppColors.success, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'SMS / WhatsApp Auto-Dispatch',
                                          style: TextStyle(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Submit Button Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => context.go('/admin/bookings'),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('CREATE & ASSIGN BOOKING', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedVehicleCard(DriverModel driver, VehicleModel vehicle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${vehicle.make} ${vehicle.model}',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        vehicle.type.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        vehicle.registrationNumber,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${vehicle.passengerCapacity} Seats • ${vehicle.luggageCapacity} Bags',
                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link, color: AppColors.success, size: 14),
                SizedBox(width: 4),
                Text(
                  'Auto-Linked',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclePlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.secondaryText, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select an active driver to automatically link and view their assigned vehicle.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripTypeChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.secondaryText,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String sectionNumber,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  sectionNumber,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSuccessDialog(BuildContext context, BookingModel booking) {
    return Dialog(
      backgroundColor: const Color(0xFF131E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Booking Created Successfully!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Booking for ${booking.passengerName} has been assigned to ${booking.driverName ?? "Driver"}.',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Route & Details Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1F2E45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📍 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'Route: ${booking.pickupLocation} → ${booking.dropoffLocation}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('🚗 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'Vehicle: ${booking.vehicleName ?? "Vehicle"} (${booking.vehicleNumber ?? "N/A"})',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('👤 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'Driver: ${booking.driverName ?? "Driver"} (${booking.driverPhone ?? "N/A"})',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons Section
            _buildSuccessDialogActions(context, booking),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDialogActions(BuildContext context, BookingModel booking) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final hasBookedByPhone = (booking.bookedByPhone ?? '').trim().isNotEmpty;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.badge_outlined, size: 16, color: Colors.white),
            label: const Text('Send to Driver (WhatsApp)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            onPressed: () {
              WhatsAppService.sendWhatsApp(
                booking.driverPhone ?? '',
                WhatsAppService.buildDriverMessage(
                  bookingCode: booking.displayCode,
                  passengerName: booking.passengerName,
                  passengerPhone: booking.passengerPhone,
                  pickupLocation: booking.pickupLocation,
                  dropoffLocation: booking.dropoffLocation,
                  pickupTime: booking.pickupTime,
                  bookingId: booking.id,
                  tripToken: booking.tripToken,
                  passengers: booking.passengers,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.person_outline, size: 16, color: Colors.white),
            label: const Text('Send to Guest (WhatsApp)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            onPressed: () {
              WhatsAppService.sendWhatsApp(
                booking.passengerPhone,
                WhatsAppService.buildGuestMessage(
                  bookingCode: booking.displayCode,
                  pickupLocation: booking.pickupLocation,
                  dropoffLocation: booking.dropoffLocation,
                  pickupTime: booking.pickupTime,
                  driverName: booking.driverName ?? "Driver",
                  driverPhone: booking.driverPhone ?? "N/A",
                  vehicleName: booking.vehicleName,
                  vehicleNumber: booking.vehicleNumber,
                  passengers: booking.passengers,
                ),
              );
            },
          ),
          if (hasBookedByPhone) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.assignment_ind_outlined, size: 16, color: Colors.white),
              label: const Text('Send to Booked By (WhatsApp)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              onPressed: () {
                WhatsAppService.sendWhatsApp(
                  booking.bookedByPhone!,
                  WhatsAppService.buildBookedByConfirmationMessage(booking),
                );
              },
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/admin/bookings');
            },
            child: const Text('Go to Bookings List', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
        ],
      );
    }

    // Desktop Wrap Layout
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            // 1. Send to Driver
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.badge_outlined, size: 15, color: Colors.white),
              label: const Text('Send to Driver', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                WhatsAppService.sendWhatsApp(
                  booking.driverPhone ?? '',
                  WhatsAppService.buildDriverMessage(
                    bookingCode: booking.displayCode,
                    passengerName: booking.passengerName,
                    passengerPhone: booking.passengerPhone,
                    pickupLocation: booking.pickupLocation,
                    dropoffLocation: booking.dropoffLocation,
                    pickupTime: booking.pickupTime,
                    bookingId: booking.id,
                    tripToken: booking.tripToken,
                    passengers: booking.passengers,
                  ),
                );
              },
            ),

            // 2. Send to Guest / Passenger
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.person_outline, size: 15, color: Colors.white),
              label: const Text('Send to Guest', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                WhatsAppService.sendWhatsApp(
                  booking.passengerPhone,
                  WhatsAppService.buildGuestMessage(
                    bookingCode: booking.displayCode,
                    pickupLocation: booking.pickupLocation,
                    dropoffLocation: booking.dropoffLocation,
                    pickupTime: booking.pickupTime,
                    driverName: booking.driverName ?? "Driver",
                    driverPhone: booking.driverPhone ?? "N/A",
                    vehicleName: booking.vehicleName,
                    vehicleNumber: booking.vehicleNumber,
                    passengers: booking.passengers,
                  ),
                );
              },
            ),

            // 3. Send to Booked By Coordinator (if phone provided)
            if (hasBookedByPhone)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6), // Purple
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.assignment_ind_outlined, size: 15, color: Colors.white),
                label: const Text('Send to Booked By', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  WhatsAppService.sendWhatsApp(
                    booking.bookedByPhone!,
                    WhatsAppService.buildBookedByConfirmationMessage(booking),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/admin/bookings');
            },
            child: const Text('Go to Bookings List', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
        ),
      ],
    );
  }

  Widget _buildBookedBySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2E45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.assignment_ind_outlined, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 8),
              Text(
                'Booked By Details',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // 1. Name
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _bookedByNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration(
                    'Booked By Name',
                    'e.g. Travel Desk / John Doe',
                    Icons.person_outline,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Mobile Number
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _bookedByPhoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration(
                    'Booked By Mobile',
                    'e.g. 9876543210',
                    Icons.phone_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 3. WBS No.
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _wbsNoController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration(
                    'WBS No.',
                    'e.g. WBS-90210',
                    Icons.tag_outlined,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
      filled: true,
      fillColor: const Color(0xFF131E2E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2E45))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2E45))),
    );
  }

  Widget _buildDynamicPassengersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2E45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Count Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.group_outlined, color: Color(0xFF38BDF8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Passenger & Route Details',
                    style: TextStyle(color: Color(0xFF38BDF8), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Total Passengers: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131E2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1F2E45)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16, color: Colors.white70),
                          onPressed: _passengerCount > 1 ? () => _updatePassengerCount(_passengerCount - 1) : null,
                        ),
                        Text(
                          '$_passengerCount',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16, color: Colors.white70),
                          onPressed: _passengerCount < 10 ? () => _updatePassengerCount(_passengerCount + 1) : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List of Passenger Cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _passengerList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = _passengerList[index];
              final isFirst = index == 0;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131E2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isFirst ? const Color(0xFF38BDF8).withOpacity(0.4) : const Color(0xFF1F2E45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Passenger ${index + 1}${isFirst ? " (Primary)" : ""}',
                          style: TextStyle(
                            color: isFirst ? const Color(0xFF38BDF8) : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isFirst)
                          TextButton.icon(
                            icon: const Icon(Icons.copy_all, size: 14, color: Color(0xFF94A3B8)),
                            label: const Text('Same Route as Passenger 1', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            onPressed: () {
                              item.pickupController.text = _passengerList[0].pickupController.text;
                              item.dropoffController.text = _passengerList[0].dropoffController.text;
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Name & Contact Phone
                    _buildResponsiveRow(context, [
                      TextFormField(
                        controller: item.nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _inputDecoration('Passenger Name *', 'e.g. John Doe', Icons.person_outline),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: item.phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _inputDecoration('Contact Mobile *', 'e.g. 9876543210', Icons.phone_outlined),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ]),
                    const SizedBox(height: 10),

                    // Individual Pickup & Dropoff Fields
                    _buildResponsiveRow(context, [
                      TextFormField(
                        controller: item.pickupController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _inputDecoration('Pickup Location *', 'e.g. Hotel / Terminal', Icons.trip_origin),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: item.dropoffController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _inputDecoration('Dropoff Location *', 'e.g. Airport / Address', Icons.location_on_outlined),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ]),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveRow(BuildContext context, List<Widget> children) {
    final isMobile = ResponsiveLayout.isMobile(context);
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .map((child) => Padding(padding: const EdgeInsets.only(bottom: 12), child: child))
            .toList(),
      );
    }
    return Row(
      children: children
          .map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: child)))
          .toList(),
    );
  }
}
