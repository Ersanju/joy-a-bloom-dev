class ChocolateVariant {
  final String sku;
  final double weightInGrams;
  final int quantity;
  final bool isSugarFree;
  final double price;
  final double? oldPrice;
  final double discount;

  ChocolateVariant({
    required this.sku,
    required this.weightInGrams,
    required this.quantity,
    required this.isSugarFree,
    required this.price,
    this.oldPrice,
    required this.discount,
  });

  factory ChocolateVariant.fromJson(Map<String, dynamic> json) =>
      ChocolateVariant(
        sku: json['sku'],
        weightInGrams: (json['weightInGrams'] ?? 0).toDouble(),
        quantity: json['quantity'] ?? 1,
        isSugarFree: json['isSugarFree'] ?? false,
        price: (json['price'] ?? 0).toDouble(),
        oldPrice: json['oldPrice'] != null
            ? (json['oldPrice'] as num).toDouble()
            : null,
        discount: (json['discount'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'sku': sku,
    'weightInGrams': weightInGrams,
    'quantity': quantity,
    'isSugarFree': isSugarFree,
    'price': price,
    'oldPrice': oldPrice,
    'discount': discount,
  };
}
