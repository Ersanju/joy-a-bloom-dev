class CartItem {
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final String variant; // unique variant ID (e.g., productId_sku)
  final double price;

  // ✅ New optional fields
  final String? cakeMessage;
  final Map<String, dynamic>? cardMessageData;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.variant,
    required this.price,
    this.cakeMessage,
    this.cardMessageData,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'],
      productName: json['productName'],
      productImage: json['productImage'],
      quantity: json['quantity'],
      variant: json['variant'],
      price: (json['price'] as num).toDouble(),

      // ✅ safely parse optional fields
      cakeMessage: json['cakeMessage'],
      cardMessageData:
          json['cardMessageData'] != null
              ? Map<String, dynamic>.from(json['cardMessageData'])
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productImage': productImage,
    'quantity': quantity,
    'variant': variant,
    'price': price,
    if (cakeMessage != null) 'cakeMessage': cakeMessage,
    if (cardMessageData != null) 'cardMessageData': cardMessageData,
  };

  CartItem copyWith({
    int? quantity,
    String? cakeMessage,
    Map<String, dynamic>? cardMessageData,
  }) {
    return CartItem(
      productId: productId,
      productName: productName,
      productImage: productImage,
      quantity: quantity ?? this.quantity,
      variant: variant,
      price: price,
      cakeMessage: cakeMessage ?? this.cakeMessage,
      cardMessageData: cardMessageData ?? this.cardMessageData,
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
