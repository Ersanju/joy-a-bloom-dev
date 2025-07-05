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
  final GeoPoint? location;

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

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      label: json['label'] ?? '',
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      landmark: json['landmark'] ?? '',
      pinCode: json['pinCode'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      location: json['location'] != null ? json['location'] as GeoPoint : null,
    );
  }

  Map<String, dynamic> toJson() {
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
