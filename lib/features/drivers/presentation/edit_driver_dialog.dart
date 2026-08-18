import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../vehicles/domain/vehicle_model.dart';
import '../data/driver_repository.dart';
import '../domain/driver_model.dart';

class EditDriverDialog extends ConsumerStatefulWidget {
  final DriverModel driver;

  const EditDriverDialog({super.key, required this.driver});

  @override
  ConsumerState<EditDriverDialog> createState() => _EditDriverDialogState();
}

class _EditDriverDialogState extends ConsumerState<EditDriverDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _plateNumberController;

  late DriverStatus _status;
  late VehicleType _vehicleType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    final v = d.vehicle;

    _nameController = TextEditingController(text: d.name);
    _phoneController = TextEditingController(text: d.mobile);
    _emailController = TextEditingController(text: d.email ?? '');
    _vehicleModelController = TextEditingController(text: v?.model ?? v?.make ?? 'Sedan');
    _plateNumberController = TextEditingController(text: v?.registrationNumber ?? d.assignedVehicleReg ?? '');

    _status = d.status;
    _vehicleType = v?.type ?? VehicleType.sedan;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vehicleModelController.dispose();
    _plateNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(driverProvider.notifier).updateDriverAndVehicle(
          driverId: widget.driver.id,
          driverName: _nameController.text.trim(),
          driverPhone: _phoneController.text.trim(),
          driverEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          status: _status,
          vehicleId: widget.driver.vehicle?.id,
          vehicleModel: _vehicleModelController.text.trim(),
          plateNumber: _plateNumberController.text.trim().toUpperCase(),
          vehicleType: _vehicleType,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Driver and vehicle details updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update driver. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Edit Driver & Vehicle Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '👨‍✈️ Driver Info',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Driver Full Name *',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Mobile Number *',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.email),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<DriverStatus>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'Driver Status',
                                prefixIcon: Icon(Icons.shield),
                              ),
                              items: DriverStatus.values.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(s == DriverStatus.active ? 'Active (Ready)' : s == DriverStatus.onTrip ? 'On Trip' : 'Inactive'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _status = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '🚖 Assigned Vehicle Info',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _vehicleModelController,
                              decoration: const InputDecoration(
                                labelText: 'Vehicle Make / Model *',
                                prefixIcon: Icon(Icons.directions_car),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter vehicle model' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _plateNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Plate / Reg Number *',
                                prefixIcon: Icon(Icons.badge),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter plate number' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<VehicleType>(
                        value: _vehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Category',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: VehicleType.values.map((vt) {
                          return DropdownMenuItem(
                            value: vt,
                            child: Text(vt.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _vehicleType = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, color: Colors.white),
                    label: Text(
                      _isSubmitting ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
}
