import 'cart_item.dart';
import 'user_address.dart';

class Order {
  final String orderId;
  final String userId;
  final List<CartItem> items;
  final UserAddress deliveryAddress;
  final DateTime deliveryDate;
  final String timeSlot;
  final double totalAmount;
  final double discount;
  final double finalAmount;
  final String paymentMethod;
  final String paymentStatus; // Paid, Failed, Pending
  final DateTime createdAt;
  final String orderStatus; // e.g., Confirmed, Preparing, Delivered

  Order({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.deliveryAddress,
    required this.deliveryDate,
    required this.timeSlot,
    required this.totalAmount,
    required this.discount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    required this.orderStatus,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'],
      userId: json['userId'],
      items:
          (json['items'] as List)
              .map((item) => CartItem.fromJson(item))
              .toList(),
      deliveryAddress: UserAddress.fromJson(json['deliveryAddress']),
      deliveryDate: DateTime.parse(json['deliveryDate']),
      timeSlot: json['timeSlot'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      finalAmount: (json['finalAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      createdAt: DateTime.parse(json['createdAt']),
      orderStatus: json['orderStatus'],
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'userId': userId,
    'items': items.map((item) => item.toJson()).toList(),
    'deliveryAddress': deliveryAddress.toJson(),
    'deliveryDate': deliveryDate.toIso8601String(),
    'timeSlot': timeSlot,
    'totalAmount': totalAmount,
    'discount': discount,
    'finalAmount': finalAmount,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'createdAt': createdAt.toIso8601String(),
    'orderStatus': orderStatus,
  };

  static Order empty() => Order(
    orderId: '',
    userId: '',
    items: [],
    deliveryAddress: UserAddress.empty(),
    deliveryDate: DateTime.now(),
    timeSlot: '',
    totalAmount: 0.0,
    discount: 0.0,
    finalAmount: 0.0,
    paymentMethod: '',
    paymentStatus: 'Pending',
    createdAt: DateTime.now(),
    orderStatus: 'Pending',
  );
}
