class CartItem {
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final String variant; // unique variant ID (e.g., productId_sku)
  final double price;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.variant,
    required this.price,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'],
      productName: json['productName'],
      productImage: json['productImage'],
      quantity: json['quantity'],
      variant: json['variant'],
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productImage': productImage,
    'quantity': quantity,
    'variant': variant,
    'price': price,
  };

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      productName: productName,
      productImage: productImage,
      quantity: quantity ?? this.quantity,
      variant: variant,
      price: price,
    );
  }

  static CartItem empty() => CartItem(
    productId: '',
    productName: '',
    productImage: '',
    quantity: 0,
    variant: '',
    price: 0.0,
  );
}
