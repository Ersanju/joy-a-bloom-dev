import 'package:cloud_firestore/cloud_firestore.dart';

class UserAddress {
  final String label;
  final String street;
  final String area;
  final String landmark;
  final String pinCode;
  final String city;
  final String state;
  final String country;
  final GeoPoint? location; // NEW FIELD

  UserAddress({
    required this.label,
    required this.street,
    required this.area,
    required this.landmark,
    required this.pinCode,
    required this.city,
    required this.state,
    required this.country,
    this.location,
  });

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      label: map['label'] ?? '',
      street: map['street'] ?? '',
      area: map['area'] ?? '',
      landmark: map['landmark'] ?? '',
      pinCode: map['pinCode'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
      location: map['location'] != null ? map['location'] as GeoPoint : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'street': street,
      'area': area,
      'landmark': landmark,
      'pinCode': pinCode,
      'city': city,
      'state': state,
      'country': country,
      'location': location,
    };
  }
}
