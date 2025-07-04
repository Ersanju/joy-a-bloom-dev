import 'package:joy_a_bloom_dev/models/user_address.dart';

import 'cart_item.dart';
import 'order_model.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final DateTime? dob;
  final String? gender;
  final List<String> wishlistProductIds;
  final List<UserAddress> addresses;
  final List<Order> orders;
  final List<CartItem> cartItems;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? fcmToken;

  User({
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

  factory User.fromMap(Map<String, dynamic> map, String uid) {
    return User(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      dob: map['dob'] != null ? DateTime.tryParse(map['dob']) : null,
      gender: map['gender'],
      wishlistProductIds: List<String>.from(map['wishlistProductIds'] ?? []),
      addresses: (map['addresses'] as List<dynamic>?)
          ?.map((a) => UserAddress.fromMap(a))
          .toList() ??
          [],
      orders: (map['orders'] as List<dynamic>?)
          ?.map((o) => Order.fromMap(o))
          .toList() ??
          [],
      cartItems: (map['cartItems'] as List<dynamic>?)
          ?.map((c) => CartItem.fromMap(c))
          .toList() ??
          [],
      createdAt: DateTime.parse(map['createdAt']),
      lastLoginAt:
      map['lastLoginAt'] != null ? DateTime.tryParse(map['lastLoginAt']) : null,
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'wishlistProductIds': wishlistProductIds,
      'addresses': addresses.map((a) => a.toMap()).toList(),
      'orders': orders.map((o) => o.toMap()).toList(),
      'cartItems': cartItems.map((c) => c.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'fcmToken': fcmToken,
    };
  }
}
