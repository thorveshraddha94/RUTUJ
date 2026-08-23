import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../auth/data/auth_repository.dart';
import '../../bookings/data/booking_repository.dart';

class ClientRequestBookingPage extends ConsumerStatefulWidget {
  const ClientRequestBookingPage({super.key});

  @override
  ConsumerState<ClientRequestBookingPage> createState() => _ClientRequestBookingPageState();
}

class _ClientRequestBookingPageState extends ConsumerState<ClientRequestBookingPage> {
  final _formKey = GlobalKey<FormState>();

  // Strictly required fields:
  final _passengerNameController = TextEditingController();
  final _passengerMobileController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  final _remarksController = TextEditingController();

  int _passengersCount = 1;
  int _luggageCount = 1;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(hours: 4));
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
  }

  @override
  void dispose() {
    _passengerNameController.dispose();
    _passengerMobileController.dispose();
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      setState(() => _errorMessage = 'Please select pickup date and time.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final authState = ref.read(authProvider);
      final profileRes = await supabase
          .from('profiles')
          .select('name, username, company_name, contact_phone, phone, company_id, role')
          .eq('id', user.id)
          .maybeSingle();

      final clientProfile = profileRes ?? {};
      final bookedByName = clientProfile['username'] ?? clientProfile['company_name'] ?? clientProfile['name'] ?? authState.user?.name ?? 'Client';
      final bookedByPhone = clientProfile['contact_phone'] ?? clientProfile['phone'] ?? _passengerMobileController.text.trim();

      final combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final payload = <String, dynamic>{
        'passenger_name': _passengerNameController.text.trim(),
        'passenger_phone': _passengerMobileController.text.trim(),
        'pickup_location': _pickupLocationController.text.trim(),
        'dropoff_location': _dropoffLocationController.text.trim(),
        'passenger_count': _passengersCount,
        'passengers_count': _passengersCount,
        'luggage_count': _luggageCount,
        'pickup_time': combinedDateTime.toIso8601String(),
        'pickup_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'pickup_datetime': combinedDateTime.toIso8601String(),
        'status': 'new_request',
        'booking_status': 'new_request',
        'booked_by_name': bookedByName,
        'booked_by_phone': bookedByPhone,
        'client_id': user.id,
        'notes': _remarksController.text.trim(),
        if (clientProfile['company_id'] != null) 'company_id': clientProfile['company_id'],
      };

      print('🚀 [ClientPortal] Inserting new booking request: $payload');
      await supabase.from('bookings').insert(payload);

      await ref.read(bookingProvider.notifier).fetchBookings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request submitted successfully! Ops team notified.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.go('/client/dashboard');
      }
    } catch (e) {
      print('❌ [ClientPortal] Error submitting booking request: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to submit request: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/client/dashboard'),
        ),
        title: const Text(
          'Request Airport Transfer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 14.0 : 28.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_location_alt_outlined, color: Color(0xFF38BDF8), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Booking Request',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Fill in transfer details for instant dispatch review',
                            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1. Passenger Name & Mobile
                  const Text('1. PASSENGER DETAILS', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: 'Passenger Name',
                          controller: _passengerNameController,
                          icon: Icons.person_outline,
                          hint: 'Full passenger name',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: 'Passenger Mobile Number',
                          controller: _passengerMobileController,
                          icon: Icons.phone_outlined,
                          hint: 'Mobile with country code',
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Number of Passengers & Luggage
                  const Text('2. CAPACITY REQUIREMENTS', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCounterPicker(
                          label: 'Passengers Count',
                          value: _passengersCount,
                          icon: Icons.groups_outlined,
                          onChanged: (val) => setState(() => _passengersCount = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCounterPicker(
                          label: 'Luggage / Bags',
                          value: _luggageCount,
                          icon: Icons.luggage_outlined,
                          onChanged: (val) => setState(() => _luggageCount = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Pickup Location & Dropoff Location
                  const Text('3. ROUTE DETAILS', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildFormField(
                    label: 'Pickup Location',
                    controller: _pickupLocationController,
                    icon: Icons.my_location,
                    hint: 'Terminal / Address / Airport name',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Pickup location required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildFormField(
                    label: 'Dropoff Location',
                    controller: _dropoffLocationController,
                    icon: Icons.location_on_outlined,
                    hint: 'Destination hotel / Address',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Dropoff location required' : null,
                  ),
                  const SizedBox(height: 16),

                  // 4. Pickup Date & Time
                  const Text('4. PICKUP DATE & TIME', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: _buildPickerBox(
                            label: 'Pickup Date',
                            value: _selectedDate != null ? dateFormat.format(_selectedDate!) : 'Select Date',
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickTime,
                          child: _buildPickerBox(
                            label: 'Pickup Time',
                            value: _selectedTime != null ? _selectedTime!.format(context) : 'Select Time',
                            icon: Icons.access_time_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Remarks / Special Instructions
                  const Text('5. REMARKS / SPECIAL INSTRUCTIONS', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildFormField(
                    label: 'Remarks',
                    controller: _remarksController,
                    icon: Icons.notes_outlined,
                    hint: 'Flight no., VIP instructions or specific requests (Optional)',
                    maxLines: 3,
                    required: false,
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),

                  // Submit Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.go('/client/dashboard'),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        label: Text(
                          _isSubmitting ? 'Submitting...' : 'Submit Request',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF38BDF8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterPicker({
    required String label,
    required int value,
    required IconData icon,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1F2E45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 8),
                  Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF94A3B8), size: 20),
                    onPressed: value > 1 ? () => onChanged(value - 1) : null,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF38BDF8), size: 20),
                    onPressed: value < 50 ? () => onChanged(value + 1) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickerBox({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1F2E45)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
