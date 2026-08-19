import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/booking_repository.dart';
import '../domain/booking_model.dart';

class EditBookingDialog extends ConsumerStatefulWidget {
  final dynamic booking;
  const EditBookingDialog({super.key, required this.booking});

  @override
  ConsumerState<EditBookingDialog> createState() => _EditBookingDialogState();
}

class _EditBookingDialogState extends ConsumerState<EditBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  late TextEditingController _passengerNameController;
  late TextEditingController _passengerPhoneController;
  late TextEditingController _pickupController;
  late TextEditingController _dropoffController;
  late TextEditingController _fareController;
  late TextEditingController _notesController;

  DateTime? _selectedDate;
  DateTime? _endDate;
  int _durationDays = 1;
  String _tripType = 'single_day';
  TimeOfDay? _selectedTime;
  String? _selectedStatus;
  String? _selectedDriverId;
  String? _selectedVehicleId;

  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _allowedStatuses = [
    'pending',
    'assigned',
    'in_progress',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.booking;

    // Safe extraction
    final name =
        _getField(b, [
          'passenger_name',
          'passengerName',
          'customer_name',
          'guestName',
          'guest_name',
        ]) ??
        '';
    final phone =
        _getField(b, [
          'passenger_phone',
          'passengerPhone',
          'customer_phone',
          'guestMobile',
          'guest_mobile',
        ]) ??
        '';
    final pickup =
        _getField(b, ['pickup_location', 'pickupLocation', 'origin']) ?? '';
    final dropoff =
        _getField(b, ['dropoff_location', 'dropoffLocation', 'destination']) ??
        '';
    final fare =
        _getField(b, ['total_fare', 'totalFare', 'fare', 'amount']) ?? '0';
    final notes =
        _getField(b, ['notes', 'internalNotes', 'trip_notes', 'remarks']) ?? '';
    final statusRaw = (_getField(b, ['status', 'booking_status']) ?? 'pending')
        .toString()
        .toLowerCase()
        .trim();

    _passengerNameController = TextEditingController(text: name);
    _passengerPhoneController = TextEditingController(text: phone);
    _pickupController = TextEditingController(text: pickup);
    _dropoffController = TextEditingController(text: dropoff);
    _fareController = TextEditingController(text: fare.toString());
    _notesController = TextEditingController(text: notes);

    _selectedStatus = _allowedStatuses.contains(statusRaw)
        ? statusRaw
        : 'pending';
    _selectedDriverId = _getField(b, ['driver_id', 'driverId'])?.toString();
    _selectedVehicleId = _getField(b, ['vehicle_id', 'vehicleId'])?.toString();

    _tripType = (_getField(b, ['trip_type', 'tripType']) ?? 'single_day')
        .toString();
    final durationRaw = _getField(b, ['duration_days', 'durationDays']);
    _durationDays = int.tryParse(durationRaw ?? '') ?? 1;

    // Date & Time extraction
    final rawTime = _getField(b, [
      'pickup_time',
      'pickupTime',
      'pickup_datetime',
    ]);
    if (rawTime != null && rawTime.toString().isNotEmpty) {
      final dt = DateTime.tryParse(rawTime.toString());
      if (dt != null) {
        _selectedDate = dt;
        _selectedTime = TimeOfDay.fromDateTime(dt);
      }
    }

    final rawEndDate = _getField(b, ['end_date', 'endDate']);
    if (rawEndDate != null && rawEndDate.toString().isNotEmpty) {
      _endDate = DateTime.tryParse(rawEndDate.toString());
    } else if (_selectedDate != null && _durationDays > 1) {
      _endDate = _selectedDate!.add(Duration(days: _durationDays - 1));
    }

    _loadData();
  }

  String? _getField(dynamic obj, List<String> keys) {
    if (obj == null) return null;
    if (obj is Map) {
      for (final k in keys) {
        if (obj[k] != null && obj[k].toString().isNotEmpty)
          return obj[k].toString();
      }
    }
    // Reflection / property access fallback
    for (final k in keys) {
      try {
        if (obj is BookingModel) {
          final json = obj.toSupabase();
          if (json[k] != null && json[k].toString().isNotEmpty)
            return json[k].toString();
        }
      } catch (_) {}
    }
    try {
      if (obj.guestName != null && keys.contains('passengerName'))
        return obj.guestName;
      if (obj.guestMobile != null && keys.contains('passengerPhone'))
        return obj.guestMobile;
      if (obj.pickupLocation != null && keys.contains('pickupLocation'))
        return obj.pickupLocation;
      if (obj.destination != null && keys.contains('dropoffLocation'))
        return obj.destination;
      if (obj.totalFare != null && keys.contains('totalFare'))
        return obj.totalFare.toString();
      if (obj.internalNotes != null && keys.contains('notes'))
        return obj.internalNotes;
      if (obj.driverId != null && keys.contains('driverId'))
        return obj.driverId;
      if (obj.vehicleId != null && keys.contains('vehicleId'))
        return obj.vehicleId;
      if (obj.status != null && keys.contains('status'))
        return obj.status is BookingStatus
            ? (obj.status as BookingStatus).name
            : obj.status.toString();
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _passengerNameController.dispose();
    _passengerPhoneController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _fareController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = _supabase.auth.currentUser;
      String? companyId;
      if (user != null) {
        final profile = await _supabase
            .from('profiles')
            .select('company_id')
            .eq('id', user.id)
            .maybeSingle();
        companyId = profile?['company_id']?.toString();
      }

      var driversQuery = _supabase.from('drivers').select('*');
      var vehiclesQuery = _supabase.from('vehicles').select('*');

      if (companyId != null && companyId.isNotEmpty) {
        driversQuery = driversQuery.eq('company_id', companyId);
        vehiclesQuery = vehiclesQuery.eq('company_id', companyId);
      }

      final results = await Future.wait([driversQuery, vehiclesQuery]);

      if (mounted) {
        setState(() {
          _drivers = List<Map<String, dynamic>>.from(results[0] as List);
          _vehicles = List<Map<String, dynamic>>.from(results[1] as List);

          // Verify that selected driver ID exists in fetched drivers list
          if (_selectedDriverId != null &&
              !_drivers.any((d) => d['id'].toString() == _selectedDriverId)) {
            _selectedDriverId = null;
          }

          // Verify that selected vehicle ID exists in fetched vehicles list
          if (_selectedVehicleId != null &&
              !_vehicles.any((v) => v['id'].toString() == _selectedVehicleId)) {
            _selectedVehicleId = null;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDriverChanged(String? driverId) {
    setState(() {
      _selectedDriverId = driverId;
      if (driverId != null) {
        final matchedDriver = _drivers.firstWhere(
          (d) => d['id'].toString() == driverId,
          orElse: () => {},
        );
        if (matchedDriver['vehicle_id'] != null) {
          final autoVehicleId = matchedDriver['vehicle_id'].toString();
          if (_vehicles.any((v) => v['id'].toString() == autoVehicleId)) {
            _selectedVehicleId = autoVehicleId;
          }
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      DateTime? combinedPickupTime;
      if (_selectedDate != null) {
        final time = _selectedTime ?? const TimeOfDay(hour: 0, minute: 0);
        combinedPickupTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          time.hour,
          time.minute,
        );
      }

      final bookingId = _getField(widget.booking, ['id']) ?? widget.booking.id;

      final updates = <String, dynamic>{
        'passenger_name': _passengerNameController.text.trim(),
        'customer_name': _passengerNameController.text.trim(),
        'passenger_phone': _passengerPhoneController.text.trim(),
        'customer_phone': _passengerPhoneController.text.trim(),
        'pickup_location': _pickupController.text.trim(),
        'dropoff_location': _dropoffController.text.trim(),
        'origin': _pickupController.text.trim(),
        'destination': _dropoffController.text.trim(),
        'total_fare': double.tryParse(_fareController.text.trim()) ?? 0.0,
        'amount': double.tryParse(_fareController.text.trim()) ?? 0.0,
        'status': _selectedStatus,
        'booking_status': _selectedStatus,
        'notes': _notesController.text.trim(),
      };

      if (_selectedDriverId != null && _selectedDriverId!.isNotEmpty) {
        updates['driver_id'] = _selectedDriverId;
      } else {
        updates['driver_id'] = null;
      }

      if (_selectedVehicleId != null && _selectedVehicleId!.isNotEmpty) {
        updates['vehicle_id'] = _selectedVehicleId;
      } else {
        updates['vehicle_id'] = null;
      }

      updates['trip_type'] = _tripType;
      if (_selectedDate != null) {
        updates['start_date'] = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      }
      if (_endDate != null) {
        updates['end_date'] = DateFormat('yyyy-MM-dd').format(_endDate!);
      }
      updates['duration_days'] = _durationDays;

      if (combinedPickupTime != null) {
        updates['pickup_time'] = combinedPickupTime.toIso8601String();
        updates['pickup_datetime'] = combinedPickupTime.toIso8601String();
      }

      print('🚀 [EditBooking] Sending updates: $updates');
      await _supabase.from('bookings').update(updates).eq('id', bookingId);

      try {
        ref.read(bookingListProvider.notifier).loadBookings();
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking updated successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final code =
        _getField(widget.booking, [
          'booking_code',
          'displayCode',
          'reference_code',
        ]) ??
        'BK';

    return Dialog(
      backgroundColor: const Color(0xFF131E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Modal Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.edit_note,
                              color: Color(0xFF38BDF8),
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit Booking — $code',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF1F2E45)),
                    const SizedBox(height: 12),

                    // Scrollable Inputs Area
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Passenger Details
                            const Text(
                              '1. Passenger Information',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Passenger Name *',
                                    _passengerNameController,
                                    Icons.person_outline,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    'Contact Phone *',
                                    _passengerPhoneController,
                                    Icons.phone_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 2. Route
                            const Text(
                              '2. Trip Route Details',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              'Pickup Address *',
                              _pickupController,
                              Icons.trip_origin,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              'Dropoff Address *',
                              _dropoffController,
                              Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 16),

                            // 3. Schedule & Fare
                            const Text(
                              '3. Schedule & Fare',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _pickDate,
                                    child: _buildPickerContainer(
                                      label: 'Pickup Date',
                                      value: _selectedDate != null
                                          ? dateFormat.format(_selectedDate!)
                                          : 'Select Date',
                                      icon: Icons.calendar_today_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: _pickTime,
                                    child: _buildPickerContainer(
                                      label: 'Pickup Time',
                                      value: _selectedTime != null
                                          ? _selectedTime!.format(context)
                                          : 'Select Time',
                                      icon: Icons.access_time,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    'Fare (₹)',
                                    _fareController,
                                    Icons.currency_rupee,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 4. Driver & Vehicle
                            const Text(
                              '4. Fleet Assignment & Status',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    value: _selectedDriverId,
                                    dropdownColor: const Color(0xFF0F172A),
                                    decoration: _dropdownDecoration(
                                      'Assigned Driver',
                                      Icons.badge_outlined,
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(
                                          'Unassigned',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      ..._drivers.map(
                                        (d) => DropdownMenuItem<String?>(
                                          value: d['id'].toString(),
                                          child: Text(
                                            d['name'] ??
                                                d['full_name'] ??
                                                'Driver',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: _onDriverChanged,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    value: _selectedVehicleId,
                                    dropdownColor: const Color(0xFF0F172A),
                                    decoration: _dropdownDecoration(
                                      'Assigned Vehicle',
                                      Icons.directions_car_outlined,
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(
                                          'No Vehicle',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      ..._vehicles.map(
                                        (v) => DropdownMenuItem<String?>(
                                          value: v['id'].toString(),
                                          child: Text(
                                            '${v['model'] ?? v['make'] ?? "Car"} (${v['registration_number'] ?? v['plate_number'] ?? ""})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) => setState(
                                      () => _selectedVehicleId = val,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Status & Notes
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedStatus,
                                    dropdownColor: const Color(0xFF0F172A),
                                    decoration: _dropdownDecoration(
                                      'Status',
                                      Icons.flag_outlined,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'pending',
                                        child: Text(
                                          'Pending',
                                          style: TextStyle(
                                            color: Colors.orangeAccent,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'assigned',
                                        child: Text(
                                          'Assigned',
                                          style: TextStyle(
                                            color: Colors.amberAccent,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'in_progress',
                                        child: Text(
                                          'In Progress',
                                          style: TextStyle(
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'completed',
                                        child: Text(
                                          'Completed',
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'cancelled',
                                        child: Text(
                                          'Cancelled',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) =>
                                        setState(() => _selectedStatus = val),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    'Notes',
                                    _notesController,
                                    Icons.notes_outlined,
                                    required: false,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF1F2E45)),
                    const SizedBox(height: 8),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.save_outlined,
                                  size: 18,
                                  color: Colors.white,
                                ),
                          label: Text(
                            _isSaving ? 'Updating...' : 'Save Changes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveChanges,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPickerContainer({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1F2E45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1F2E45)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1F2E45)),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1F2E45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1F2E45)),
        ),
      ),
      validator: required
          ? (val) => val == null || val.trim().isEmpty ? 'Required' : null
          : null,
    );
  }
}
