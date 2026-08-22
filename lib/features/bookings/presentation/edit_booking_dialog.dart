import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/booking_repository.dart';
import '../domain/booking_model.dart';
import '../domain/passenger_form_item.dart';
import '../../../core/widgets/responsive_layout.dart';

class EditBookingDialog extends ConsumerStatefulWidget {
  final dynamic booking;
  const EditBookingDialog({super.key, required this.booking});

  @override
  ConsumerState<EditBookingDialog> createState() => _EditBookingDialogState();
}

class _EditBookingDialogState extends ConsumerState<EditBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  late TextEditingController _bookedByNameController;
  late TextEditingController _bookedByPhoneController;
  late TextEditingController _wbsNoController;
  late TextEditingController _passengerNameController;
  late TextEditingController _passengerPhoneController;
  late TextEditingController _pickupController;
  late TextEditingController _dropoffController;
  late TextEditingController _fareController;
  late TextEditingController _notesController;

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

    final bookedByName =
        _getField(b, ['booked_by_name', 'bookedByName', 'coordinator_name']) ?? '';
    final bookedByPhone =
        _getField(b, ['booked_by_phone', 'bookedByPhone', 'coordinator_phone']) ?? '';
    final wbsNo =
        _getField(b, ['wbs_no', 'wbsNo', 'wbs_number']) ?? '';

    _bookedByNameController = TextEditingController(text: bookedByName);
    _bookedByPhoneController = TextEditingController(text: bookedByPhone);
    _wbsNoController = TextEditingController(text: wbsNo);
    _passengerNameController = TextEditingController(text: name);
    _passengerPhoneController = TextEditingController(text: phone);
    _pickupController = TextEditingController(text: pickup);
    _dropoffController = TextEditingController(text: dropoff);
    _fareController = TextEditingController(text: fare.toString());
    _notesController = TextEditingController(text: notes);

    final rawPassengers = b is Map ? b['passengers'] : (b is BookingModel ? b.passengers : null);
    if (rawPassengers is List && rawPassengers.isNotEmpty) {
      _passengerList = rawPassengers
          .map((p) => PassengerFormItem.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList();
      _passengerCount = _passengerList.length;
    } else {
      _passengerList = [
        PassengerFormItem(
          name: name,
          phone: phone,
          pickup: pickup,
          dropoff: dropoff,
        ),
      ];
      _passengerCount = 1;
    }

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
      if (obj.bookedByName != null && keys.contains('bookedByName'))
        return obj.bookedByName;
      if (obj.bookedByPhone != null && keys.contains('bookedByPhone'))
        return obj.bookedByPhone;
      if (obj.wbsNo != null && keys.contains('wbsNo'))
        return obj.wbsNo;
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
    for (final item in _passengerList) {
      item.dispose();
    }
    _bookedByNameController.dispose();
    _bookedByPhoneController.dispose();
    _wbsNoController.dispose();
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

      final primaryP = _passengerList.isNotEmpty ? _passengerList[0] : PassengerFormItem();
      final pName = primaryP.nameController.text.trim().isNotEmpty
          ? primaryP.nameController.text.trim()
          : _passengerNameController.text.trim();
      final pPhone = primaryP.phoneController.text.trim().isNotEmpty
          ? primaryP.phoneController.text.trim()
          : _passengerPhoneController.text.trim();
      final pPick = primaryP.pickupController.text.trim().isNotEmpty
          ? primaryP.pickupController.text.trim()
          : _pickupController.text.trim();
      final pDrop = primaryP.dropoffController.text.trim().isNotEmpty
          ? primaryP.dropoffController.text.trim()
          : _dropoffController.text.trim();

      final updates = <String, dynamic>{
        'booked_by_name': _bookedByNameController.text.trim(),
        'booked_by_phone': _bookedByPhoneController.text.trim(),
        'wbs_no': _wbsNoController.text.trim(),
        'passenger_name': pName,
        'customer_name': pName,
        'passenger_phone': pPhone,
        'customer_phone': pPhone,
        'pickup_location': pPick,
        'dropoff_location': pDrop,
        'origin': pPick,
        'destination': pDrop,
        'passengers': _passengerList.map((p) => p.toJson()).toList(),
        'passenger_count': _passengerCount,
        'passengers_count': _passengerCount,
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
                            // 1. Booked By Details
                            _buildBookedBySection(),

                            // 2. Dynamic Passenger & Route Details
                            _buildDynamicPassengersSection(),

                            // 4. Schedule & Fare
                            const Text(
                              '4. Schedule & Fare',
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

                            // 5. Driver & Vehicle
                            const Text(
                              '5. Fleet Assignment & Status',
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
