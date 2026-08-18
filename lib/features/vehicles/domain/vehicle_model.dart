enum VehicleType { sedan, suv, luxury, van }

class VehicleModel {
  final String id;
  final String registrationNumber;
  final VehicleType type;
  final String make;
  final String model;
  final int passengerCapacity;
  final int luggageCapacity;
  final bool isActive;

  const VehicleModel({
    required this.id,
    required this.registrationNumber,
    required this.type,
    required this.make,
    required this.model,
    required this.passengerCapacity,
    required this.luggageCapacity,
    this.isActive = true,
  });

  String get displayName => '$make $model ($registrationNumber)';

  VehicleModel copyWith({
    String? id,
    String? registrationNumber,
    VehicleType? type,
    String? make,
    String? model,
    int? passengerCapacity,
    int? luggageCapacity,
    bool? isActive,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      type: type ?? this.type,
      make: make ?? this.make,
      model: model ?? this.model,
      passengerCapacity: passengerCapacity ?? this.passengerCapacity,
      luggageCapacity: luggageCapacity ?? this.luggageCapacity,
      isActive: isActive ?? this.isActive,
    );
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      registrationNumber: json['registrationNumber'] as String,
      type: _typeFromString(json['type'] as String),
      make: json['make'] as String,
      model: json['model'] as String,
      passengerCapacity: json['passengerCapacity'] as int,
      luggageCapacity: json['luggageCapacity'] as int,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'registrationNumber': registrationNumber,
        'type': type.name.toUpperCase(),
        'make': make,
        'model': model,
        'passengerCapacity': passengerCapacity,
        'luggageCapacity': luggageCapacity,
        'isActive': isActive,
      };

  factory VehicleModel.fromSupabase(Map<String, dynamic> json) {
    return VehicleModel(
      id: (json['id'] ?? '').toString(),
      registrationNumber: (json['registration_number'] ?? json['registrationNumber'] ?? '').toString(),
      type: _typeFromString((json['vehicle_category'] ?? json['type'] ?? 'SEDAN').toString()),
      make: (json['make'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      passengerCapacity: int.tryParse(json['passenger_capacity']?.toString() ?? '') ??
          int.tryParse(json['passengerCapacity']?.toString() ?? '') ??
          4,
      luggageCapacity: int.tryParse(json['luggage_capacity']?.toString() ?? '') ??
          int.tryParse(json['luggageCapacity']?.toString() ?? '') ??
          3,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toSupabase(String driverId) => {
        'driver_id': driverId,
        'registration_number': registrationNumber,
        'vehicle_category': type.name.toUpperCase(),
        'make': make,
        'model': model,
        'passenger_capacity': passengerCapacity,
        'luggage_capacity': luggageCapacity,
        'is_active': isActive,
      };

  static VehicleType _typeFromString(String str) {
    switch (str.toUpperCase()) {
      case 'SUV':
        return VehicleType.suv;
      case 'LUXURY':
        return VehicleType.luxury;
      case 'VAN':
        return VehicleType.van;
      case 'SEDAN':
      default:
        return VehicleType.sedan;
    }
  }
}

