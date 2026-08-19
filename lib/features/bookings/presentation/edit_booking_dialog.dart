import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/booking_repository.dart';
import '../domain/booking_model.dart';

class EditBookingDialog extends ConsumerStatefulWidget {
  final dynamic booking; // BookingModel
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
  TimeOfDay? _selectedTime;
  String? _selectedStatus;
  String? _selectedDriverId;
  String? _selectedVehicleId;

  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoadingDropdowns = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.booking;

    _passengerNameController = TextEditingController(text: b.passengerName ?? b.guestName ?? '');
    _passengerPhoneController = TextEditingController(text: b.passengerPhone ?? b.guestMobile ?? '');
    _pickupController = TextEditingController(text: b.pickupLocation ?? '');
    _dropoffController = TextEditingController(text: b.dropoffLocation ?? b.destination ?? '');
    _fareController = TextEditingController(text: '${b.totalFare > 0 ? b.totalFare : 0}');
    _notesController = TextEditingController(text: b.internalNotes ?? b.notes ?? '');

    final rawStatus = b.status is BookingStatus ? (b.status as BookingStatus).name : (b.status ?? 'pending');
    _selectedStatus = rawStatus.toString().toLowerCase();
    _selectedDriverId = b.driverId?.toString();
    _selectedVehicleId = b.vehicleId?.toString();

    if (b.pickupDate != null && b.pickupDate.toString().isNotEmpty) {
      _selectedDate = DateTime.tryParse(b.pickupDate.toString());
    }
    if (b.pickupTime != null && b.pickupTime.toString().isNotEmpty) {
      final dt = DateTime.tryParse(b.pickupTime.toString());
      if (dt != null) {
        _selectedDate ??= dt;
        _selectedTime = TimeOfDay.fromDateTime(dt);
      }
    }

    _loadDriversAndVehicles();
  }

  Future<void> _loadDriversAndVehicles() async {
    try {
      final user = _supabase.auth.currentUser;
      String? companyId;
      if (user != null) {
        final profile = await _supabase.from('profiles').select('company_id').eq('id', user.id).maybeSingle();
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
          _isLoadingDropdowns = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDropdowns = false);
    }
  }

  void _onDriverSelected(String? driverId) {
    setState(() {
      _selectedDriverId = driverId;
      if (driverId != null) {
        final matchedDriver = _drivers.firstWhere(
          (d) => d['id'].toString() == driverId,
          orElse: () => {},
        );
        if (matchedDriver['vehicle_id'] != null) {
          _selectedVehicleId = matchedDriver['vehicle_id'].toString();
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
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

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      DateTime? fullPickupDateTime;
      if (_selectedDate != null) {
        final time = _selectedTime ?? const TimeOfDay(hour: 0, minute: 0);
        fullPickupDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          time.hour,
          time.minute,
        );
      }

      final pickupStr = fullPickupDateTime != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(fullPickupDateTime)
          : null;

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
        if (pickupStr != null) 'pickup_time': pickupStr,
        if (pickupStr != null) 'pickup_datetime': pickupStr,
        if (_selectedDriverId != null) 'driver_id': _selectedDriverId,
        if (_selectedVehicleId != null) 'vehicle_id': _selectedVehicleId,
      };

      await ref.read(bookingListProvider.notifier).updateBooking(widget.booking.id.toString(), updates);

      if (mounted) {
        Navigator.of(context).pop();
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
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayCodeStr = widget.booking is BookingModel
        ? (widget.booking as BookingModel).displayCode
        : (widget.booking.id != null && widget.booking.id.toString().length >= 8
            ? widget.booking.id.toString().substring(0, 8)
            : 'BOOKING');

    return Dialog(
      backgroundColor: const Color(0xFF131E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 640,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note, color: Color(0xFF38BDF8), size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Edit Booking — $displayCodeStr',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 16),

                // 1. Passenger Info
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Passenger Name *', _passengerNameController, Icons.person_outline),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField('Passenger Phone *', _passengerPhoneController, Icons.phone_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Route Info
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Pickup Location *', _pickupController, Icons.trip_origin),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField('Dropoff Location *', _dropoffController, Icons.location_on_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Schedule Pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1F2E45)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Color(0xFF38BDF8), size: 18),
                              const SizedBox(width: 10),
                              Text(
                                _selectedDate != null
                                    ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                                    : 'Select Date',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1F2E45)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFF38BDF8), size: 18),
                              const SizedBox(width: 10),
                              Text(
                                _selectedTime != null
                                    ? _selectedTime!.format(context)
                                    : 'Select Time',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Driver & Vehicle Assignment
                if (_isLoadingDropdowns)
                  const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                else
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _drivers.any((d) => d['id'].toString() == _selectedDriverId)
                              ? _selectedDriverId
                              : null,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Assign Driver',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2E45))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2E45))),
                          ),
                          items: _drivers.map((d) {
                            final name = (d['name'] ?? d['full_name'] ?? 'Driver').toString();
                            final phone = (d['mobile'] ?? d['mobile_number'] ?? '').toString();
                            return DropdownMenuItem<String>(
                              value: d['id'].toString(),
                              child: Text('$name ($phone)', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: _onDriverSelected,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _vehicles.any((v) => v['id'].toString() == _selectedVehicleId)
                              ? _selectedVehicleId
                              : null,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Assign Vehicle',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2E45))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2E45))),
                          ),
                          items: _vehicles.map((v) {
                            final make = (v['make'] ?? '').toString();
                            final model = (v['model'] ?? '').toString();
                            final reg = (v['registration_number'] ?? v['plate_number'] ?? '').toString();
                            return DropdownMenuItem<String>(
                              value: v['id'].toString(),
                              child: Text('$make $model ($reg)', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedVehicleId = val),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // 5. Status & Fare
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Booking Status',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2E45))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2E45))),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                          DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: (val) => setState(() => _selectedStatus = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField('Total Fare (\$)', _fareController, Icons.attach_money),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. Internal Notes
                _buildTextField('Internal Notes / Special Instructions', _notesController, Icons.notes_outlined),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined, size: 18, color: Colors.white),
                      label: Text(_isSaving ? 'Saving...' : 'Save Changes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: _isSaving ? null : _submitUpdate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2E45))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2E45))),
      ),
      validator: (val) => (label.contains('*') && (val == null || val.trim().isEmpty)) ? 'Required field' : null,
    );
  }
}
