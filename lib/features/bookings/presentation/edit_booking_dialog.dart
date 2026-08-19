import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late TextEditingController _passengerNameController;
  late TextEditingController _passengerPhoneController;
  late TextEditingController _pickupController;
  late TextEditingController _dropoffController;
  late TextEditingController _fareController;
  String? _selectedStatus;
  String? _selectedDriverId;
  String? _selectedVehicleId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    _passengerNameController = TextEditingController(text: b.passengerName ?? '');
    _passengerPhoneController = TextEditingController(text: b.passengerPhone ?? '');
    _pickupController = TextEditingController(text: b.pickupLocation ?? '');
    _dropoffController = TextEditingController(text: b.dropoffLocation ?? '');
    _fareController = TextEditingController(text: '${b.totalFare ?? 0}');
    _selectedStatus = (b.status is BookingStatus ? (b.status as BookingStatus).name : (b.status ?? 'pending')).toString().toLowerCase();
    _selectedDriverId = b.driverId;
    _selectedVehicleId = b.vehicleId;
  }

  @override
  void dispose() {
    _passengerNameController.dispose();
    _passengerPhoneController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final updates = {
        'passenger_name': _passengerNameController.text.trim(),
        'passenger_phone': _passengerPhoneController.text.trim(),
        'pickup_location': _pickupController.text.trim(),
        'dropoff_location': _dropoffController.text.trim(),
        'total_fare': _fareController.text.trim(),
        'status': _selectedStatus,
        'driver_id': _selectedDriverId,
        'vehicle_id': _selectedVehicleId,
      };

      await ref.read(bookingListProvider.notifier).updateBooking(widget.booking.id, updates);

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
        width: 600,
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
                    Text(
                      'Edit Booking — $displayCodeStr',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF1F2E45)),
                const SizedBox(height: 16),

                // Passenger Name & Phone
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Passenger Name', _passengerNameController, Icons.person_outline),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField('Passenger Phone', _passengerPhoneController, Icons.phone_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pickup & Dropoff
                _buildTextField('Pickup Location', _pickupController, Icons.trip_origin),
                const SizedBox(height: 16),
                _buildTextField('Dropoff Location', _dropoffController, Icons.location_on_outlined),
                const SizedBox(height: 16),

                // Status & Fare
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        dropdownColor: const Color(0xFF0F172A),
                        decoration: InputDecoration(
                          labelText: 'Booking Status',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'assigned', child: Text('Assigned', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'in_progress', child: Text('In Progress', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'completed', child: Text('Completed', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (val) => setState(() => _selectedStatus = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField('Fare Amount', _fareController, Icons.currency_rupee),
                    ),
                  ],
                ),
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
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2E45))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F2E45))),
      ),
      validator: (val) => val == null || val.trim().isEmpty ? 'Required field' : null,
    );
  }
}
