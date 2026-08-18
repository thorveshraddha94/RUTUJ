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
            drivers: [],
          ),
        ) {
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    state = state.copyWith(isLoading: true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      String? companyId;
      if (user != null) {
        final profileRes = await client.from('profiles').select('company_id').eq('id', user.id).maybeSingle();
        companyId = profileRes?['company_id']?.toString();
      }

      final dynamic response;
      if (companyId != null && companyId.isNotEmpty) {
        response = await client.from('drivers').select('*, vehicles(*)').eq('company_id', companyId);
      } else {
        response = await client.from('drivers').select('*, vehicles(*)');
      }

      final fetched = (response as List)
          .map((e) => DriverModel.fromSupabase(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(drivers: fetched, isLoading: false);
    } catch (_) {
      state = state.copyWith(drivers: [], isLoading: false);
    }
  }

  Future<List<DriverModel>> fetchActiveDriversWithVehicles() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      String? companyId;
      if (user != null) {
        final profileRes = await client.from('profiles').select('company_id').eq('id', user.id).maybeSingle();
        companyId = profileRes?['company_id']?.toString();
      }

      final dynamic response;
      if (companyId != null && companyId.isNotEmpty) {
        response = await client
            .from('drivers')
            .select('*, vehicles(*)')
            .eq('company_id', companyId)
            .or('status.eq.Active (Ready),status.eq.active');
      } else {
        response = await client
            .from('drivers')
            .select('*, vehicles(*)')
            .or('status.eq.Active (Ready),status.eq.active');
      }

      return (response as List)
          .map((e) => DriverModel.fromSupabase(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
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
      final user = client.auth.currentUser;
      String? companyId;
      if (user != null) {
        final profileRes = await client.from('profiles').select('company_id').eq('id', user.id).maybeSingle();
        companyId = profileRes?['company_id']?.toString();
      }

      // 1. Insert into public.drivers with tenant company_id
      final driverRes = await client.from('drivers').insert({
        'full_name': name,
        'mobile_number': mobile,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        'status': statusStr,
        if (companyId case final id?) 'company_id': id,
      }).select().single();

      final driverId = (driverRes['id'] ?? '').toString();

      // 2. Insert into public.vehicles using generated driver.id & company_id
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
          if (companyId case final id?) 'company_id': id,
        }).select().single();

        vehicle = VehicleModel.fromSupabase(vehicleRes);
        final vehicleId = vehicleRes['id']?.toString();
        if (vehicleId != null) {
          await client.from('drivers').update({'vehicle_id': vehicleId}).eq('id', driverId);
        }
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



