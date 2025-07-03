class CartItem {
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final String variant; // size/weight etc.
  final double price;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.variant,
    required this.price,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'],
      productName: map['productName'],
      productImage: map['productImage'],
      quantity: map['quantity'],
      variant: map['variant'],
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'variant': variant,
      'price': price,
    };
  }
}
