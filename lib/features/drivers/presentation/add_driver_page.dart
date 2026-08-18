import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../vehicles/domain/vehicle_model.dart';
import '../data/driver_repository.dart';
import '../domain/driver_model.dart';

class AddDriverPage extends ConsumerStatefulWidget {
  const AddDriverPage({super.key});

  @override
  ConsumerState<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends ConsumerState<AddDriverPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Driver Fields
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  DriverStatus _status = DriverStatus.active;

  // Vehicle Fields
  final _regController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _passCapController = TextEditingController(text: '4');
  final _lugCapController = TextEditingController(text: '3');
  VehicleType _vehicleType = VehicleType.sedan;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _regController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _passCapController.dispose();
    _lugCapController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(driverProvider.notifier).addDriver(
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          status: _status,
          vehicleRegistration: _regController.text.trim(),
          vehicleType: _vehicleType,
          vehicleMake: _makeController.text.trim(),
          vehicleModel: _modelController.text.trim(),
          passengerCapacity: int.tryParse(_passCapController.text.trim()) ?? 4,
          luggageCapacity: int.tryParse(_lugCapController.text.trim()) ?? 3,
        );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver and associated Vehicle added successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/admin/drivers');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Add New Driver & Vehicle', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => context.go('/admin/drivers'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1 Header: Driver Profile
                  const Row(
                    children: [
                      Icon(Icons.person_outline, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Driver Profile',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter driver profile details and contact information.',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.badge_outlined)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Mobile & Email (Optional)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mobileController,
                          decoration: const InputDecoration(labelText: 'Mobile Number *', prefixIcon: Icon(Icons.phone_outlined)),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (v.trim().length < 8) return 'Enter valid mobile number';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email Address (Optional)', prefixIcon: Icon(Icons.email_outlined)),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            if (!v.contains('@')) return 'Enter valid email';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Initial Driver Status Selection
                  DropdownButtonFormField<DriverStatus>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Initial Driver Status *'),
                    items: const [
                      DropdownMenuItem(value: DriverStatus.active, child: Text('Active (Ready)')),
                      DropdownMenuItem(value: DriverStatus.inactive, child: Text('Inactive (Suspended)')),
                    ],
                    onChanged: (val) => setState(() => _status = val!),
                  ),

                  const SizedBox(height: 28),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 20),

                  // Section 2 Header: Vehicle Details
                  const Row(
                    children: [
                      Icon(Icons.directions_car_outlined, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Assigned Vehicle Information',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Specify vehicle parameters assigned directly to this driver.',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Registration Number & Category
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _regController,
                          decoration: const InputDecoration(
                            labelText: 'Registration Number * (e.g. GJ-01-AB-1234)',
                            prefixIcon: Icon(Icons.pin_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Registration required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<VehicleType>(
                          value: _vehicleType,
                          decoration: const InputDecoration(labelText: 'Vehicle Category *'),
                          items: VehicleType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.name.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setState(() => _vehicleType = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Make & Model
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _makeController,
                          decoration: const InputDecoration(labelText: 'Make * (e.g. Toyota)', prefixIcon: Icon(Icons.build_outlined)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Make required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(labelText: 'Model * (e.g. Camry Hybrid)', prefixIcon: Icon(Icons.car_rental)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Model required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Passenger & Luggage Capacities
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _passCapController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Passenger Capacity', prefixIcon: Icon(Icons.airline_seat_recline_normal)),
                          validator: (v) => v == null || int.tryParse(v) == null ? 'Enter valid count' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lugCapController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Luggage Capacity (Bags)', prefixIcon: Icon(Icons.work_outline)),
                          validator: (v) => v == null || int.tryParse(v) == null ? 'Enter valid count' : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.go('/admin/drivers'),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check),
                        label: const Text('Save Driver & Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
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
}


