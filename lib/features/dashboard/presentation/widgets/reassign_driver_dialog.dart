import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../bookings/data/booking_repository.dart';
import '../../../drivers/data/driver_repository.dart';
import '../../../vehicles/data/vehicle_repository.dart';
import '../../../drivers/domain/driver_model.dart';
import '../../../vehicles/domain/vehicle_model.dart';

class ReassignDriverDialog extends ConsumerStatefulWidget {
  final String bookingId;

  const ReassignDriverDialog({super.key, required this.bookingId});

  @override
  ConsumerState<ReassignDriverDialog> createState() => _ReassignDriverDialogState();
}

class _ReassignDriverDialogState extends ConsumerState<ReassignDriverDialog> {
  DriverModel? _selectedDriver;
  VehicleModel? _selectedVehicle;

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);
    final vehicleState = ref.watch(vehicleProvider);
    final activeDrivers = driverState.drivers.where((d) => d.status != DriverStatus.inactive).toList();
    final activeVehicles = vehicleState.activeVehicles;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.person_add_alt_1_outlined, color: AppColors.warning),
          const SizedBox(width: 10),
          Text(
            'Reassign Driver for ${widget.bookingId}',
            style: const TextStyle(color: AppColors.primaryText, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a replacement active driver and vehicle. The previous driver will be unassigned and notified immediately.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Select Driver Dropdown
            const Text('New Active Driver *', style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<DriverModel>(
              value: _selectedDriver,
              hint: const Text('Choose active driver'),
              items: activeDrivers.map((driver) {
                return DropdownMenuItem(
                  value: driver,
                  child: Text('${driver.name} (${driver.mobile}) - ${driver.status.name}'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedDriver = val),
            ),
            const SizedBox(height: 18),

            // Select Vehicle Dropdown
            const Text('New Active Vehicle *', style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<VehicleModel>(
              value: _selectedVehicle,
              hint: const Text('Choose active vehicle'),
              items: activeVehicles.map((vehicle) {
                return DropdownMenuItem(
                  value: vehicle,
                  child: Text('${vehicle.displayName} [${vehicle.type.name.toUpperCase()}]'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedVehicle = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_selectedDriver == null || _selectedVehicle == null)
              ? null
              : () async {
                  await ref.read(bookingProvider.notifier).reassignDriver(
                        bookingId: widget.bookingId,
                        newDriverId: _selectedDriver!.id,
                        newDriverName: _selectedDriver!.name,
                        newDriverMobile: _selectedDriver!.mobile,
                        newVehicleId: _selectedVehicle!.id,
                        newVehicleReg: _selectedVehicle!.registrationNumber,
                        newVehicleType: _selectedVehicle!.type.name.toUpperCase(),
                      );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Booking ${widget.bookingId} reassigned to ${_selectedDriver!.name} successfully.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
          child: const Text('Confirm Reassignment'),
        ),
      ],
    );
  }
}
