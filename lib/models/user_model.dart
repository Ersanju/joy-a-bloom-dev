import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:joy_a_bloom_dev/models/user_order_model.dart';

import 'cart_item.dart';
import 'user_address.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final DateTime? dob;
  final String? gender;
  final List<String> wishlistProductIds;
  final List<UserAddress> addresses;
  final List<UserOrder> orders;
  final List<CartItem> cartItems;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? fcmToken;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.dob,
    this.gender,
    this.wishlistProductIds = const [],
    this.addresses = const [],
    this.orders = const [],
    this.cartItems = const [],
    required this.createdAt,
    this.lastLoginAt,
    this.fcmToken,
  });

  factory AppUser.fromJson(Map<String, dynamic> json, String uid) {
    return AppUser(
      uid: uid,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      dob: _parseDate(json['dob']),
      gender: json['gender'],
      wishlistProductIds: List<String>.from(json['wishlistProductIds'] ?? []),
      addresses:
          (json['addresses'] as List<dynamic>?)
              ?.map((a) => UserAddress.fromJson(a))
              .toList() ??
          [],
      orders:
          (json['orders'] as List<dynamic>?)
              ?.map((o) => UserOrder.fromJson(o))
              .toList() ??
          [],
      cartItems:
          (json['cartItems'] as List<dynamic>?)
              ?.map((c) => CartItem.fromJson(c))
              .toList() ??
          [],
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDate(json['lastLoginAt']),
      fcmToken: json['fcmToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'gender': gender,
      'wishlistProductIds': wishlistProductIds,
      'addresses': addresses.map((a) => a.toJson()).toList(),
      'orders': orders.map((o) => o.toJson()).toList(),
      'cartItems': cartItems.map((c) => c.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'fcmToken': fcmToken,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
