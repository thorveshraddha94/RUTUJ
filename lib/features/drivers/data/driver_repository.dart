import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/driver_model.dart';
import '../../vehicles/domain/vehicle_model.dart';

class DriverState {
  final List<DriverModel> drivers;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final DriverStatus? statusFilter;
  final VehicleType? vehicleTypeFilter;

  const DriverState({
    required this.drivers,
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.statusFilter,
    this.vehicleTypeFilter,
  });

  List<DriverModel> get filteredDrivers {
    return drivers.where((driver) {
      final q = searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          driver.name.toLowerCase().contains(q) ||
          driver.mobile.contains(q) ||
          (driver.email != null && driver.email!.toLowerCase().contains(q)) ||
          (driver.username != null && driver.username!.toLowerCase().contains(q)) ||
          (driver.vehicle != null &&
              (driver.vehicle!.registrationNumber.toLowerCase().contains(q) ||
                  driver.vehicle!.make.toLowerCase().contains(q) ||
                  driver.vehicle!.model.toLowerCase().contains(q)));

      final matchesStatus = statusFilter == null || driver.status == statusFilter;
      final matchesVehicleType = vehicleTypeFilter == null ||
          (driver.vehicle != null && driver.vehicle!.type == vehicleTypeFilter);

      return matchesSearch && matchesStatus && matchesVehicleType;
    }).toList();
  }

  List<DriverModel> get activeDrivers =>
      drivers.where((d) => d.status == DriverStatus.active).toList();

  DriverState copyWith({
    List<DriverModel>? drivers,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    DriverStatus? statusFilter,
    VehicleType? vehicleTypeFilter,
    bool clearStatusFilter = false,
    bool clearVehicleTypeFilter = false,
  }) {
    return DriverState(
      drivers: drivers ?? this.drivers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      vehicleTypeFilter: clearVehicleTypeFilter ? null : (vehicleTypeFilter ?? this.vehicleTypeFilter),
    );
  }
}

class DriverNotifier extends StateNotifier<DriverState> {
  DriverNotifier()
      : super(
          const DriverState(
            drivers: [
              DriverModel(
                id: 'DRV-101',
                name: 'Amit Patel',
                mobile: '+91 98765 43210',
                email: 'amit.patel@airporttransfer.com',
                username: 'amit_p',
                status: DriverStatus.onTrip,
                upcomingBookingsCount: 2,
                currentTripBookingId: 'AT-1048',
                vehicle: VehicleModel(
                  id: 'VEH-001',
                  registrationNumber: 'GJ-01-AB-1234',
                  type: VehicleType.sedan,
                  make: 'Toyota',
                  model: 'Camry Hybrid',
                  passengerCapacity: 4,
                  luggageCapacity: 3,
                  isActive: true,
                ),
              ),
              DriverModel(
                id: 'DRV-102',
                name: 'Vikram Singh',
                mobile: '+91 98234 56789',
                email: 'vikram.singh@airporttransfer.com',
                username: 'vikram_s',
                status: DriverStatus.active,
                upcomingBookingsCount: 1,
                vehicle: VehicleModel(
                  id: 'VEH-002',
                  registrationNumber: 'GJ-01-CD-5678',
                  type: VehicleType.suv,
                  make: 'Toyota',
                  model: 'Fortuner Legender',
                  passengerCapacity: 6,
                  luggageCapacity: 5,
                  isActive: true,
                ),
              ),
              DriverModel(
                id: 'DRV-103',
                name: 'Rajesh Sharma',
                mobile: '+91 97123 45678',
                email: 'rajesh.sharma@airporttransfer.com',
                username: 'rajesh_s',
                status: DriverStatus.active,
                upcomingBookingsCount: 0,
                vehicle: VehicleModel(
                  id: 'VEH-003',
                  registrationNumber: 'GJ-01-EF-9012',
                  type: VehicleType.luxury,
                  make: 'Mercedes-Benz',
                  model: 'E-Class',
                  passengerCapacity: 3,
                  luggageCapacity: 3,
                  isActive: true,
                ),
              ),
              DriverModel(
                id: 'DRV-104',
                name: 'Suresh Kumar',
                mobile: '+91 96543 21098',
                email: 'suresh.k@airporttransfer.com',
                username: 'suresh_k',
                status: DriverStatus.inactive,
                upcomingBookingsCount: 0,
                vehicle: VehicleModel(
                  id: 'VEH-004',
                  registrationNumber: 'GJ-01-GH-3456',
                  type: VehicleType.van,
                  make: 'Kia',
                  model: 'Carnival Limousine',
                  passengerCapacity: 7,
                  luggageCapacity: 6,
                  isActive: false,
                ),
              ),
            ],
          ),
        ) {
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    try {
      final response = await Supabase.instance.client
          .from('drivers')
          .select('*, vehicles(*)');

      if (response.isNotEmpty) {
        final fetched = response
            .map((e) => DriverModel.fromSupabase(e))
            .toList();
        state = state.copyWith(drivers: fetched, isLoading: false);
      }
    } catch (_) {
      // Graceful fallback if Supabase table is unavailable or offline
    }
  }

  Future<List<DriverModel>> fetchActiveDriversWithVehicles() async {
    try {
      final response = await Supabase.instance.client
          .from('drivers')
          .select('*, vehicles(*)')
          .or('status.eq.Active (Ready),status.eq.active');

      if (response.isNotEmpty) {
        return response
            .map((e) => DriverModel.fromSupabase(e))
            .toList();
      }
    } catch (_) {}
    return state.activeDrivers;
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(DriverStatus? status) {
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null);
  }

  void setVehicleTypeFilter(VehicleType? vehicleType) {
    state = state.copyWith(vehicleTypeFilter: vehicleType, clearVehicleTypeFilter: vehicleType == null);
  }

  Future<bool> addDriver({
    required String name,
    required String mobile,
    String? email,
    required DriverStatus status,
    String? vehicleRegistration,
    VehicleType? vehicleType,
    String? vehicleMake,
    String? vehicleModel,
    int? passengerCapacity,
    int? luggageCapacity,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    VehicleModel? vehicle;
    final statusStr = status == DriverStatus.active
        ? 'Active (Ready)'
        : status == DriverStatus.inactive
            ? 'Inactive'
            : 'On Trip';

    try {
      final client = Supabase.instance.client;

      // 1. Insert into public.drivers
      final driverRes = await client.from('drivers').insert({
        'full_name': name,
        'mobile_number': mobile,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        'status': statusStr,
      }).select().single();

      final driverId = (driverRes['id'] ?? '').toString();

      // 2. Insert into public.vehicles using generated driver.id
      if (vehicleRegistration != null && vehicleRegistration.trim().isNotEmpty) {
        final vehicleRes = await client.from('vehicles').insert({
          'driver_id': driverId,
          'registration_number': vehicleRegistration.trim().toUpperCase(),
          'vehicle_category': (vehicleType ?? VehicleType.sedan).name.toUpperCase(),
          'make': vehicleMake?.trim() ?? 'Toyota',
          'model': vehicleModel?.trim() ?? 'Sedan',
          'passenger_capacity': passengerCapacity ?? 4,
          'luggage_capacity': luggageCapacity ?? 3,
          'is_active': status != DriverStatus.inactive,
        }).select().single();

        vehicle = VehicleModel.fromSupabase(vehicleRes);
      }

      await fetchDrivers();
      return true;
    } catch (_) {
      // Local fallback in case database endpoint is unreachable
      if (vehicleRegistration != null && vehicleRegistration.trim().isNotEmpty) {
        vehicle = VehicleModel(
          id: 'VEH-00${state.drivers.length + 1}',
          registrationNumber: vehicleRegistration.trim().toUpperCase(),
          type: vehicleType ?? VehicleType.sedan,
          make: vehicleMake?.trim() ?? 'Toyota',
          model: vehicleModel?.trim() ?? 'Sedan',
          passengerCapacity: passengerCapacity ?? 4,
          luggageCapacity: luggageCapacity ?? 3,
          isActive: status != DriverStatus.inactive,
        );
      }

      final newDriver = DriverModel(
        id: 'DRV-${100 + state.drivers.length + 1}',
        name: name,
        mobile: mobile,
        email: email?.trim().isEmpty ?? true ? null : email?.trim(),
        status: status,
        upcomingBookingsCount: 0,
        vehicle: vehicle,
      );

      state = state.copyWith(
        drivers: [newDriver, ...state.drivers],
        isLoading: false,
      );
      return true;
    }
  }

  Future<void> toggleDriverStatus(String driverId) async {
    final updatedList = state.drivers.map((driver) {
      if (driver.id == driverId) {
        final newStatus = driver.status == DriverStatus.inactive
            ? DriverStatus.active
            : DriverStatus.inactive;
        final updatedVehicle = driver.vehicle?.copyWith(isActive: newStatus != DriverStatus.inactive);
        return driver.copyWith(status: newStatus, vehicle: updatedVehicle);
      }
      return driver;
    }).toList();

    try {
      final target = state.drivers.firstWhere((d) => d.id == driverId);
      final newStatusStr = target.status == DriverStatus.inactive ? 'Active (Ready)' : 'Inactive';
      await Supabase.instance.client
          .from('drivers')
          .update({'status': newStatusStr})
          .eq('id', driverId);
    } catch (_) {}

    state = state.copyWith(drivers: updatedList);
  }
}

final driverProvider = StateNotifierProvider<DriverNotifier, DriverState>((ref) {
  return DriverNotifier();
});



