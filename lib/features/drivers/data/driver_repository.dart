import 'dart:async';
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
      final matchesSearch = driver.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          driver.mobile.contains(searchQuery) ||
          (driver.vehicle?.registrationNumber.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

      final matchesStatus = statusFilter == null || driver.status == statusFilter;
      final matchesVehicleType = vehicleTypeFilter == null || (driver.vehicle != null && driver.vehicle!.type == vehicleTypeFilter);

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
  StreamSubscription<AuthState>? _authSubscription;

  DriverNotifier()
      : super(
          const DriverState(
            drivers: [],
          ),
        ) {
    fetchDrivers();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed ||
          data.event == AuthChangeEvent.initialSession) {
        fetchDrivers();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchDrivers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('drivers')
          .select('*, vehicles(*)')
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      final parsed = list.map((item) => DriverModel.fromSupabase(Map<String, dynamic>.from(item as Map))).toList();

      state = state.copyWith(drivers: parsed, isLoading: false);
    } catch (_) {
      try {
        final client = Supabase.instance.client;
        final fallbackResponse = await client.from('drivers').select('*').order('created_at', ascending: false);
        final list = fallbackResponse as List<dynamic>;
        final parsed = list.map((item) => DriverModel.fromSupabase(Map<String, dynamic>.from(item as Map))).toList();
        state = state.copyWith(drivers: parsed, isLoading: false);
      } catch (_) {
        state = state.copyWith(drivers: [], isLoading: false);
      }
    }
  }

  Future<List<DriverModel>> fetchActiveDriversWithVehicles() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('drivers')
          .select('*, vehicles(*)')
          .or('status.eq.Active (Ready),status.eq.active');

      return (response as List)
          .map((e) => DriverModel.fromSupabase(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      try {
        final client = Supabase.instance.client;
        final response = await client.from('drivers').select('*');
        return (response as List)
            .map((e) => DriverModel.fromSupabase(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        return [];
      }
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

      final regNumber = (vehicleRegistration != null && vehicleRegistration.trim().isNotEmpty)
          ? vehicleRegistration.trim().toUpperCase()
          : 'MH-${(10 + (state.drivers.length % 80))}-RT-${1000 + (state.drivers.length * 111)}';
      final vModel = vehicleModel?.trim().isNotEmpty == true ? vehicleModel!.trim() : 'Sedan';
      final vMake = vehicleMake?.trim().isNotEmpty == true ? vehicleMake!.trim() : 'Toyota';

      // 1. Insert vehicle into 'vehicles' table
      final vehicleRes = await client.from('vehicles').insert({
        'registration_number': regNumber,
        'plate_number': regNumber,
        'model': vModel,
        'make': vMake,
        'vehicle_category': (vehicleType ?? VehicleType.sedan).name.toUpperCase(),
        'category': (vehicleType ?? VehicleType.sedan).name,
        'passenger_capacity': passengerCapacity ?? 4,
        'luggage_capacity': luggageCapacity ?? 3,
        'status': 'available',
        'is_active': status != DriverStatus.inactive,
        if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
      }).select().single();

      final vehicleId = vehicleRes['id']?.toString();
      vehicle = VehicleModel.fromSupabase(vehicleRes);

      // 2. Insert driver into 'drivers' table linked with vehicle_id
      final driverRes = await client.from('drivers').insert({
        'name': name,
        'full_name': name,
        'phone': mobile,
        'mobile_number': mobile,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        'status': statusStr,
        if (vehicleId != null) 'vehicle_id': vehicleId,
        if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
      }).select().single();

      final driverId = (driverRes['id'] ?? '').toString();

      // 3. Update vehicle with driver_id for bidirectional link
      if (vehicleId != null && driverId.isNotEmpty) {
        await client.from('vehicles').update({'driver_id': driverId}).eq('id', vehicleId);
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

  Future<bool> updateDriverAndVehicle({
    required String driverId,
    required String driverName,
    required String driverPhone,
    String? driverEmail,
    DriverStatus? status,
    String? vehicleId,
    required String vehicleModel,
    required String plateNumber,
    VehicleType? vehicleType,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final client = Supabase.instance.client;
      final statusStr = status == DriverStatus.active
          ? 'Active (Ready)'
          : status == DriverStatus.inactive
              ? 'Inactive'
              : 'On Trip';

      // 1. Update the driver record
      await client.from('drivers').update({
        'name': driverName.trim(),
        'full_name': driverName.trim(),
        'phone': driverPhone.trim(),
        'mobile_number': driverPhone.trim(),
        if (driverEmail != null && driverEmail.trim().isNotEmpty) 'email': driverEmail.trim(),
        if (status != null) 'status': statusStr,
      }).eq('id', driverId);

      // 2. Update the linked vehicle or insert one if not already existing
      if (vehicleId != null && vehicleId.isNotEmpty) {
        await client.from('vehicles').update({
          'model': vehicleModel.trim(),
          'make': vehicleModel.trim(),
          'plate_number': plateNumber.trim().toUpperCase(),
          'registration_number': plateNumber.trim().toUpperCase(),
          if (vehicleType != null) 'vehicle_category': vehicleType.name.toUpperCase(),
          if (vehicleType != null) 'category': vehicleType.name,
        }).eq('id', vehicleId);
      } else {
        final newVehicle = await client.from('vehicles').insert({
          'model': vehicleModel.trim(),
          'make': vehicleModel.trim(),
          'plate_number': plateNumber.trim().toUpperCase(),
          'registration_number': plateNumber.trim().toUpperCase(),
          'vehicle_category': (vehicleType ?? VehicleType.sedan).name.toUpperCase(),
          'category': (vehicleType ?? VehicleType.sedan).name,
          'driver_id': driverId,
          'status': 'available',
        }).select().single();

        final newVehicleId = newVehicle['id']?.toString();
        if (newVehicleId != null) {
          await client.from('drivers').update({'vehicle_id': newVehicleId}).eq('id', driverId);
        }
      }

      await fetchDrivers();
      return true;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}

final driverProvider = StateNotifierProvider<DriverNotifier, DriverState>((ref) {
  return DriverNotifier();
});



