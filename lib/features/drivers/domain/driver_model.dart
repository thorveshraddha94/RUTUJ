import '../../vehicles/domain/vehicle_model.dart';

enum DriverStatus { active, inactive, onTrip }

class DriverModel {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String? username;
  final DriverStatus status;
  final int upcomingBookingsCount;
  final String? currentTripBookingId;
  final String? rawAssignedVehicleReg;
  final VehicleModel? vehicle;

  const DriverModel({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.username,
    required this.status,
    this.upcomingBookingsCount = 0,
    this.currentTripBookingId,
    String? assignedVehicleReg,
    this.vehicle,
  }) : rawAssignedVehicleReg = assignedVehicleReg;

  String? get assignedVehicleReg => vehicle?.registrationNumber ?? rawAssignedVehicleReg;

  bool get isActive => status == DriverStatus.active || status == DriverStatus.onTrip;

  DriverModel copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? username,
    DriverStatus? status,
    int? upcomingBookingsCount,
    String? currentTripBookingId,
    String? assignedVehicleReg,
    VehicleModel? vehicle,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      username: username ?? this.username,
      status: status ?? this.status,
      upcomingBookingsCount: upcomingBookingsCount ?? this.upcomingBookingsCount,
      currentTripBookingId: currentTripBookingId ?? this.currentTripBookingId,
      assignedVehicleReg: assignedVehicleReg ?? this.assignedVehicleReg,
      vehicle: vehicle ?? this.vehicle,
    );
  }

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as String,
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      status: _statusFromString(json['status'] as String),
      upcomingBookingsCount: json['upcomingBookingsCount'] as int? ?? 0,
      currentTripBookingId: json['currentTripBookingId'] as String?,
      assignedVehicleReg: json['assignedVehicleReg'] as String?,
      vehicle: json['vehicle'] != null
          ? VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        if (email != null) 'email': email,
        if (username != null) 'username': username,
        'status': status.name.toUpperCase(),
        'upcomingBookingsCount': upcomingBookingsCount,
        'currentTripBookingId': currentTripBookingId,
        'assignedVehicleReg': assignedVehicleReg,
        if (vehicle != null) 'vehicle': vehicle!.toJson(),
      };

  factory DriverModel.fromSupabase(Map<String, dynamic> json) {
    VehicleModel? v;
    if (json['vehicles'] != null) {
      if (json['vehicles'] is List && (json['vehicles'] as List).isNotEmpty) {
        v = VehicleModel.fromSupabase((json['vehicles'] as List).first as Map<String, dynamic>);
      } else if (json['vehicles'] is Map<String, dynamic>) {
        v = VehicleModel.fromSupabase(json['vehicles'] as Map<String, dynamic>);
      }
    } else if (json['vehicle'] != null) {
      v = VehicleModel.fromSupabase(json['vehicle'] as Map<String, dynamic>);
    }

    return DriverModel(
      id: (json['id'] ?? '').toString(),
      name: (json['full_name'] ?? json['name'] ?? '').toString(),
      mobile: (json['mobile_number'] ?? json['mobile'] ?? '').toString(),
      email: json['email'] as String?,
      username: json['username'] as String?,
      status: _statusFromString((json['status'] ?? 'Active (Ready)').toString()),
      upcomingBookingsCount: int.tryParse(json['upcoming_bookings_count']?.toString() ?? '') ??
          int.tryParse(json['upcomingBookingsCount']?.toString() ?? '') ??
          0,
      currentTripBookingId: json['current_trip_booking_id'] as String? ?? json['currentTripBookingId'] as String?,
      assignedVehicleReg: json['assigned_vehicle_reg'] as String? ?? json['assignedVehicleReg'] as String?,
      vehicle: v,
    );
  }

  Map<String, dynamic> toSupabase() => {
        'full_name': name,
        'mobile_number': mobile,
        if (email != null) 'email': email,
        'status': status == DriverStatus.active
            ? 'Active (Ready)'
            : status == DriverStatus.onTrip
                ? 'On Trip'
                : 'Inactive',
      };

  static DriverStatus _statusFromString(String str) {
    final s = str.toUpperCase();
    if (s.contains('ON') || s.contains('TRIP')) {
      return DriverStatus.onTrip;
    }
    if (s.contains('INACTIVE')) {
      return DriverStatus.inactive;
    }
    return DriverStatus.active;
  }
}



