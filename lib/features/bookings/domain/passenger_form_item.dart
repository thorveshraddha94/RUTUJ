import 'package:flutter/material.dart';

class PassengerFormItem {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController pickupController;
  final TextEditingController dropoffController;

  PassengerFormItem({
    String name = '',
    String phone = '',
    String pickup = '',
    String dropoff = '',
  })  : nameController = TextEditingController(text: name),
        phoneController = TextEditingController(text: phone),
        pickupController = TextEditingController(text: pickup),
        dropoffController = TextEditingController(text: dropoff);

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    pickupController.dispose();
    dropoffController.dispose();
  }

  Map<String, dynamic> toJson() => {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'pickup_location': pickupController.text.trim(),
        'dropoff_location': dropoffController.text.trim(),
      };

  factory PassengerFormItem.fromMap(Map<String, dynamic> map) {
    return PassengerFormItem(
      name: (map['name'] ?? map['passenger_name'] ?? map['guest_name'] ?? '').toString(),
      phone: (map['phone'] ?? map['passenger_phone'] ?? map['guest_mobile'] ?? '').toString(),
      pickup: (map['pickup_location'] ?? map['origin'] ?? map['pickup'] ?? '').toString(),
      dropoff: (map['dropoff_location'] ?? map['destination'] ?? map['dropoff'] ?? '').toString(),
    );
  }
}
