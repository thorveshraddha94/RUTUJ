import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../vehicles/domain/vehicle_model.dart';
import '../data/driver_repository.dart';
import '../domain/driver_model.dart';
import 'edit_driver_dialog.dart';

class DriversPage extends ConsumerStatefulWidget {
  const DriversPage({super.key});

  @override
  ConsumerState<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends ConsumerState<DriversPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverProvider.notifier).fetchDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);
    final notifier = ref.read(driverProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver & Fleet Management',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Unified management of drivers, credentials, and assigned fleet vehicles',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/admin/drivers/create'),
                icon: const Icon(Icons.person_add_alt_outlined),
                label: const Text('+ Add Driver & Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search & Combined Filter Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by driver name, mobile, reg number, make, or model...',
                      prefixIcon: Icon(Icons.search, color: AppColors.secondaryText),
                    ),
                    onChanged: (q) => notifier.setSearchQuery(q),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<DriverStatus?>(
                  value: driverState.statusFilter,
                  dropdownColor: AppColors.secondarySurface,
                  hint: const Text('Driver Status', style: TextStyle(color: AppColors.secondaryText)),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Driver Statuses')),
                    DropdownMenuItem(value: DriverStatus.active, child: Text('Active Only')),
                    DropdownMenuItem(value: DriverStatus.onTrip, child: Text('On Trip Only')),
                    DropdownMenuItem(value: DriverStatus.inactive, child: Text('Inactive Only')),
                  ],
                  onChanged: (s) => notifier.setStatusFilter(s),
                ),
                const SizedBox(width: 16),
                DropdownButton<VehicleType?>(
                  value: driverState.vehicleTypeFilter,
                  dropdownColor: AppColors.secondarySurface,
                  hint: const Text('Vehicle Category', style: TextStyle(color: AppColors.secondaryText)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Vehicle Categories')),
                    ...VehicleType.values.map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
                      ),
                    ),
                  ],
                  onChanged: (v) => notifier.setVehicleTypeFilter(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Drivers & Fleet Unified Table
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: driverState.filteredDrivers.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_off_outlined, size: 54, color: AppColors.secondaryText),
                        const SizedBox(height: 14),
                        const Text(
                          'No drivers or vehicles found',
                          style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add your first driver and linked vehicle profile to assign transfer bookings.',
                          style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/admin/drivers/create'),
                          icon: const Icon(Icons.person_add),
                          label: const Text('+ Add New Driver & Vehicle'),
                        ),
                      ],
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final horizontalScrollController = ScrollController();
                      final verticalScrollController = ScrollController();
                      return Scrollbar(
                        controller: verticalScrollController,
                        thumbVisibility: true,
                        child: Scrollbar(
                          controller: horizontalScrollController,
                          thumbVisibility: true,
                          notificationPredicate: (notif) => notif.depth == 1,
                          child: SingleChildScrollView(
                            controller: verticalScrollController,
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              controller: horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 1100),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(AppColors.secondarySurface),
                                  columns: const [
                                    DataColumn(label: Text('Driver ID', style: _headerStyle)),
                        DataColumn(label: Text('Driver Profile', style: _headerStyle)),
                        DataColumn(label: Text('Contact Info', style: _headerStyle)),
                        DataColumn(label: Text('Assigned Vehicle', style: _headerStyle)),
                        DataColumn(label: Text('Category & Specs', style: _headerStyle)),
                        DataColumn(label: Text('Upcoming Trips', style: _headerStyle)),
                        DataColumn(label: Text('Status', style: _headerStyle)),
                        DataColumn(label: Text('Active Toggle', style: _headerStyle)),
                        DataColumn(label: Text('Actions', style: _headerStyle)),
                      ],
                      rows: driverState.filteredDrivers.map((driver) {
                        final vehicle = driver.vehicle;
                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Text(
                                  driver.displayCode,
                                  style: const TextStyle(
                                    color: Color(0xFF60A5FA),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary.withOpacity(0.2),
                                    child: Text(
                                      driver.name.isNotEmpty ? driver.name[0] : 'D',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(driver.name, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(driver.mobile, style: const TextStyle(color: AppColors.primaryText, fontSize: 13)),
                                  Text(
                                    driver.email != null && driver.email!.isNotEmpty ? driver.email! : 'No email',
                                    style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                                  ),
                                ],
                              ),
                            ),

                            DataCell(
                              vehicle != null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${vehicle.make} ${vehicle.model}', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondarySurface,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Text(
                                            vehicle.registrationNumber,
                                            style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(driver.assignedVehicleReg ?? 'Unassigned', style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                            ),
                            DataCell(
                              vehicle != null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.12),
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
                                        const SizedBox(height: 2),
                                        Text(
                                          '${vehicle.passengerCapacity} Seats • ${vehicle.luggageCapacity} Bags',
                                          style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                                        ),
                                      ],
                                    )
                                  : const Text('—', style: TextStyle(color: AppColors.secondaryText)),
                            ),
                            DataCell(Text('${driver.upcomingBookingsCount} trip(s)', style: const TextStyle(color: AppColors.primaryText))),
                            DataCell(StatusBadge(status: driver.status.name.toUpperCase())),
                            DataCell(
                              Switch(
                                value: driver.status != DriverStatus.inactive,
                                activeColor: AppColors.success,
                                onChanged: (val) => notifier.toggleDriverStatus(driver.id),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                tooltip: 'Edit Driver & Vehicle',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => EditDriverDialog(driver: driver),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    color: AppColors.secondaryText,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );
}

