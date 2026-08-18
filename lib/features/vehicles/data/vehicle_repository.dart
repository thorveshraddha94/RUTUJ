import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vehicle_model.dart';
import '../../drivers/data/driver_repository.dart';

class VehicleState {
  final List<VehicleModel> vehicles;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final VehicleType? typeFilter;

  const VehicleState({
    required this.vehicles,
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.typeFilter,
  });

  List<VehicleModel> get filteredVehicles {
    return vehicles.where((vehicle) {
      final matchesSearch = vehicle.registrationNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
          vehicle.make.toLowerCase().contains(searchQuery.toLowerCase()) ||
          vehicle.model.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesType = typeFilter == null || vehicle.type == typeFilter;

      return matchesSearch && matchesType;
    }).toList();
  }

  List<VehicleModel> get activeVehicles =>
      vehicles.where((v) => v.isActive).toList();

  VehicleState copyWith({
    List<VehicleModel>? vehicles,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    VehicleType? typeFilter,
    bool clearTypeFilter = false,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
    );
  }
}

final vehicleProvider = Provider<VehicleState>((ref) {
  final driverState = ref.watch(driverProvider);
  final vehicles = driverState.drivers
      .where((d) => d.vehicle != null)
      .map((d) => d.vehicle!)
      .toList();
  return VehicleState(vehicles: vehicles);
});

