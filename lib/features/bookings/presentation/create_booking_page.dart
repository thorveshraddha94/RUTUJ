import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../drivers/data/driver_repository.dart';
import '../../drivers/domain/driver_model.dart';
import '../../vehicles/domain/vehicle_model.dart';
import '../data/booking_repository.dart';

class CreateBookingPage extends ConsumerStatefulWidget {
  const CreateBookingPage({super.key});

  @override
  ConsumerState<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends ConsumerState<CreateBookingPage> {
  final _formKey = GlobalKey<FormState>();

  // Section 1: Client Details
  final _clientNameController = TextEditingController();
  final _clientContactController = TextEditingController();
  final _clientRefController = TextEditingController();
  final _internalNotesController = TextEditingController();

  // Section 2: Guest Details
  final _guestNameController = TextEditingController();
  final _guestMobileController = TextEditingController();
  final _guestEmailController = TextEditingController();
  int _passengersCount = 1;
  int _luggageCount = 1;
  bool _isVip = false;
  final _specialAssistanceController = TextEditingController();
  final _guestNotesController = TextEditingController();

  // Section 3: Flight Details
  final _flightNumberController = TextEditingController();
  String _flightType = 'Arrival';
  final _airportController = TextEditingController(text: 'Ahmedabad International (AMD)');
  final _terminalController = TextEditingController(text: 'Terminal 2');
  DateTime _flightDate = DateTime.now();
  TimeOfDay _flightTime = const TimeOfDay(hour: 9, minute: 45);

  // Section 4: Pickup Details
  DateTime _pickupDate = DateTime.now();
  TimeOfDay _pickupTime = const TimeOfDay(hour: 10, minute: 0);
  final _pickupLocationController = TextEditingController(text: 'Ahmedabad Airport T2 Arrival Exit');
  final _pickupTerminalController = TextEditingController(text: 'Terminal 2');
  final _pickupNotesController = TextEditingController();

  // Section 5: Drop Details
  final _destinationController = TextEditingController();
  final _destinationAddressController = TextEditingController();
  final _dropNotesController = TextEditingController();

  // Section 6: Driver & Vehicle Selection
  DriverModel? _selectedDriver;
  VehicleModel? get _selectedVehicle => _selectedDriver?.vehicle;
  List<DriverModel>? _supabaseActiveDrivers;

  // Section 7: Reminder Setup
  String _reminderDuration = '2 hours';
  bool _notifyPush = true;
  bool _notifySms = true;

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
    _clientNameController.dispose();
    _clientContactController.dispose();
    _clientRefController.dispose();
    _internalNotesController.dispose();
    _guestNameController.dispose();
    _guestMobileController.dispose();
    _guestEmailController.dispose();
    _specialAssistanceController.dispose();
    _guestNotesController.dispose();
    _flightNumberController.dispose();
    _airportController.dispose();
    _terminalController.dispose();
    _pickupLocationController.dispose();
    _pickupTerminalController.dispose();
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
          content: Text('Please fill out all required fields across sections.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedDriver == null || _selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an active driver with an assigned vehicle in Section 6.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final flightDateStr = DateFormat('dd MMM yyyy').format(_flightDate);
      final flightTimeStr = _flightTime.format(context);
      final pickupDateStr = DateFormat('dd MMM yyyy').format(_pickupDate);
      final pickupTimeStr = _pickupTime.format(context);

      final newBookingId = await ref.read(bookingProvider.notifier).createBooking(
            clientName: _clientNameController.text.trim(),
            clientContact: _clientContactController.text.trim(),
            clientReference: _clientRefController.text.trim().isEmpty ? null : _clientRefController.text.trim(),
            internalNotes: _internalNotesController.text.trim().isEmpty ? null : _internalNotesController.text.trim(),
            guestName: _guestNameController.text.trim(),
            guestMobile: _guestMobileController.text.trim(),
            guestEmail: _guestEmailController.text.trim(),
            passengersCount: _passengersCount,
            luggageCount: _luggageCount,
            isVip: _isVip,
            specialAssistance: _specialAssistanceController.text.trim().isEmpty ? null : _specialAssistanceController.text.trim(),
            guestNotes: _guestNotesController.text.trim().isEmpty ? null : _guestNotesController.text.trim(),
            flightNumber: _flightNumberController.text.trim(),
            flightType: _flightType,
            airport: _airportController.text.trim(),
            terminal: _terminalController.text.trim(),
            flightDate: flightDateStr,
            flightTime: flightTimeStr,
            pickupDate: pickupDateStr,
            pickupTime: pickupTimeStr,
            pickupLocation: _pickupLocationController.text.trim(),
            pickupTerminal: _pickupTerminalController.text.trim().isEmpty ? null : _pickupTerminalController.text.trim(),
            pickupNotes: _pickupNotesController.text.trim().isEmpty ? null : _pickupNotesController.text.trim(),
            destination: _destinationController.text.trim(),
            destinationAddress: _destinationAddressController.text.trim(),
            dropNotes: _dropNotesController.text.trim().isEmpty ? null : _dropNotesController.text.trim(),
            vehicleId: _selectedVehicle!.id,
            vehicleType: _selectedVehicle!.type.name.toUpperCase(),
            vehicleReg: _selectedVehicle!.registrationNumber,
            driverId: _selectedDriver!.id,
            driverName: _selectedDriver!.name,
            driverMobile: _selectedDriver!.mobile,
            reminderDuration: _reminderDuration,
            notifyPush: _notifyPush,
            notifySms: _notifySms,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking $newBookingId created and assigned successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/admin/bookings/$newBookingId');
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
        title: const Text('Create New Airport Booking', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
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
              // SECTION 1: Client Details
              _buildSectionCard(
                sectionNumber: '1',
                title: 'Client Details',
                icon: Icons.business_outlined,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _clientNameController,
                            decoration: const InputDecoration(labelText: 'Client / Company Name *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _clientContactController,
                            decoration: const InputDecoration(labelText: 'Client Contact Number *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
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
                            decoration: const InputDecoration(labelText: 'Internal Operations Notes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 2: Guest Details
              _buildSectionCard(
                sectionNumber: '2',
                title: 'Guest Details',
                icon: Icons.person_outline,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _guestNameController,
                            decoration: const InputDecoration(labelText: 'Guest Full Name *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _guestMobileController,
                            decoration: const InputDecoration(labelText: 'Guest Mobile Number *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _guestEmailController,
                            decoration: const InputDecoration(labelText: 'Guest Email Address *'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (!v.contains('@')) return 'Enter valid email';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _passengersCount,
                                  decoration: const InputDecoration(labelText: 'Passengers'),
                                  items: List.generate(10, (i) => i + 1)
                                      .map((val) => DropdownMenuItem(value: val, child: Text('$val Person(s)')))
                                      .toList(),
                                  onChanged: (val) => setState(() => _passengersCount = val!),
                                ),
                              ),
                              const SizedBox(width: 12),
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
                            decoration: const InputDecoration(labelText: 'Special Assistance (e.g. Wheelchair, Child Seat)'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _guestNotesController,
                            decoration: const InputDecoration(labelText: 'Guest Identification Notes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 3: Flight Details
              _buildSectionCard(
                sectionNumber: '3',
                title: 'Flight Details',
                icon: Icons.flight_takeoff_outlined,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _flightNumberController,
                            decoration: const InputDecoration(labelText: 'Flight Number (e.g. AI-542) *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _flightType,
                            decoration: const InputDecoration(labelText: 'Flight Type *'),
                            items: const [
                              DropdownMenuItem(value: 'Arrival', child: Text('Arrival Flight')),
                              DropdownMenuItem(value: 'Departure', child: Text('Departure Flight')),
                            ],
                            onChanged: (val) => setState(() => _flightType = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _airportController,
                            decoration: const InputDecoration(labelText: 'Airport Name *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _terminalController,
                            decoration: const InputDecoration(labelText: 'Terminal *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            tileColor: AppColors.secondarySurface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: const Icon(Icons.calendar_month, color: AppColors.primary),
                            title: const Text('Flight Date', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                            subtitle: Text(DateFormat('dd MMM yyyy').format(_flightDate), style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _flightDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => _flightDate = picked);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            tileColor: AppColors.secondarySurface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: const Icon(Icons.access_time, color: AppColors.primary),
                            title: const Text('Flight Time', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                            subtitle: Text(_flightTime.format(context), style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: _flightTime);
                              if (picked != null) setState(() => _flightTime = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 4: Pickup Details
              _buildSectionCard(
                sectionNumber: '4',
                title: 'Pickup Details',
                icon: Icons.pin_drop_outlined,
                child: Column(
                  children: [
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
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => _pickupDate = picked);
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pickupLocationController,
                            decoration: const InputDecoration(labelText: 'Pickup Location Name *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _pickupTerminalController,
                            decoration: const InputDecoration(labelText: 'Pickup Gate / Terminal'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pickupNotesController,
                      decoration: const InputDecoration(labelText: 'Pickup Instructions / Nameplate Text'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 5: Drop Details
              _buildSectionCard(
                sectionNumber: '5',
                title: 'Destination Drop Details',
                icon: Icons.flag_outlined,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _destinationController,
                            decoration: const InputDecoration(labelText: 'Destination Hotel / Landmark *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _destinationAddressController,
                            decoration: const InputDecoration(labelText: 'Full Destination Address *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dropNotesController,
                      decoration: const InputDecoration(labelText: 'Drop Notes / Concierge Delivery'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 6: Driver & Vehicle Assignment (Merged)
              _buildSectionCard(
                sectionNumber: '6',
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
                      '* Only active drivers are displayed. Selecting a driver automatically links their assigned vehicle.',
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

              // SECTION 7: Reminder Setup
              _buildSectionCard(
                sectionNumber: '7',
                title: 'Reminder & Notification Setup',
                icon: Icons.notifications_active_outlined,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              CheckboxListTile(
                                value: _notifyPush,
                                title: const Text('Push Notification', style: TextStyle(color: AppColors.primaryText, fontSize: 13)),
                                onChanged: (val) => setState(() => _notifyPush = val ?? true),
                              ),
                              CheckboxListTile(
                                value: _notifySms,
                                title: const Text('SMS Notification', style: TextStyle(color: AppColors.primaryText, fontSize: 13)),
                                onChanged: (val) => setState(() => _notifySms = val ?? true),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

