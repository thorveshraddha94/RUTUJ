import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../bookings/data/booking_repository.dart';
import '../../bookings/domain/booking_model.dart';
import '../../drivers/data/driver_repository.dart';
import '../../vehicles/data/vehicle_repository.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _searchQuery = '';
  String? _selectedDriverId;
  String? _selectedVehicleId;

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final driverState = ref.watch(driverProvider);
    final vehicleState = ref.watch(vehicleProvider);

    final historyBookings = bookingState.bookings.where((b) {
      final isArchived = b.status.name == 'completed' || b.status.name == 'cancelled';
      final matchesSearch = b.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.guestName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.clientName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDriver = _selectedDriverId == null || b.driverId == _selectedDriverId;
      final matchesVehicle = _selectedVehicleId == null || b.vehicleId == _selectedVehicleId;

      return isArchived && matchesSearch && matchesDriver && matchesVehicle;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transfer Audit & Booking History Archive',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Retained history of completed and cancelled airport transfers',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Filter Controls Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search history by Booking ID, Guest, Client...',
                    prefixIcon: Icon(Icons.search, color: AppColors.secondaryText),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedDriverId,
                        decoration: const InputDecoration(labelText: 'Filter by Driver'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Drivers')),
                          ...driverState.drivers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                        ],
                        onChanged: (v) => setState(() => _selectedDriverId = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedVehicleId,
                        decoration: const InputDecoration(labelText: 'Filter by Vehicle'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Vehicles')),
                          ...vehicleState.vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.displayName))),
                        ],
                        onChanged: (v) => setState(() => _selectedVehicleId = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // History Table
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: historyBookings.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('No historical records match the selected filters.', style: TextStyle(color: AppColors.secondaryText)),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.secondarySurface),
                      columns: const [
                        DataColumn(label: Text('Booking ID', style: _headerStyle)),
                        DataColumn(label: Text('Guest Name', style: _headerStyle)),
                        DataColumn(label: Text('Client Company', style: _headerStyle)),
                        DataColumn(label: Text('Flight & Airport', style: _headerStyle)),
                        DataColumn(label: Text('Driver', style: _headerStyle)),
                        DataColumn(label: Text('Vehicle', style: _headerStyle)),
                        DataColumn(label: Text('Final Status', style: _headerStyle)),
                        DataColumn(label: Text('Audit View', style: _headerStyle)),
                      ],
                      rows: historyBookings.map((b) {
                        return DataRow(
                          cells: [
                            DataCell(Text(b.id, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                            DataCell(Text(b.guestName, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600))),
                            DataCell(Text(b.clientName, style: const TextStyle(color: AppColors.secondaryText))),
                            DataCell(Text('${b.flightNumber} (${b.airport})')),
                            DataCell(Text(b.driverName ?? 'N/A')),
                            DataCell(Text(b.vehicleRegistration ?? 'N/A')),
                            DataCell(StatusBadge(status: b.status.displayName)),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.history_edu, color: AppColors.primary, size: 20),
                                onPressed: () => context.go('/admin/bookings/${b.id}'),
                                tooltip: 'View Complete Audit Trail',
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
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
