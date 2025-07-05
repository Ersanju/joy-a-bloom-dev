import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

class UserOrder {
  final String orderId;
  final List<CartItem> items;
  final double totalAmount;
  final String status; // Pending, Shipped, Delivered, etc.
  final DateTime orderDate;
  final String paymentMethod; // COD, UPI, Card, etc.
  final String deliveryAddress;

  UserOrder({
    required this.orderId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    required this.paymentMethod,
    required this.deliveryAddress,
  });

  factory UserOrder.fromJson(Map<String, dynamic> json) {
    return UserOrder(
      orderId: json['orderId'] ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => CartItem.fromJson(e))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Pending',
      orderDate: _parseDate(json['orderDate']),
      paymentMethod: json['paymentMethod'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': Timestamp.fromDate(orderDate),
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
