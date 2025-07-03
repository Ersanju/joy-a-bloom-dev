import 'cart_item.dart';

class Order {
  final String orderId;
  final List<CartItem> items;
  final double totalAmount;
  final String status; // e.g., Pending, Shipped, Delivered
  final DateTime orderDate;
  final String paymentMethod; // COD, UPI, etc.
  final String deliveryAddress;

  Order({
    required this.orderId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    required this.paymentMethod,
    required this.deliveryAddress,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      orderId: map['orderId'],
      items: (map['items'] as List<dynamic>)
          .map((i) => CartItem.fromMap(i))
          .toList(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      status: map['status'],
      orderDate: DateTime.parse(map['orderDate']),
      paymentMethod: map['paymentMethod'],
      deliveryAddress: map['deliveryAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': orderDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress,
    };
  }
}
