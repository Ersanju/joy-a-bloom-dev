class ChocolateAttribute {
  final String chocolateType;
  final String brand;
  final double weightInGrams;
  final int quantity;
  final bool isSugarFree;
  final double price;
  final double? oldPrice;
  final double discount;
  final String sku;

  ChocolateAttribute({
    required this.chocolateType,
    required this.brand,
    required this.weightInGrams,
    required this.quantity,
    required this.isSugarFree,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.sku,
  });

  factory ChocolateAttribute.fromJson(Map<String, dynamic> json) => ChocolateAttribute(
    chocolateType: json['chocolateType'],
    brand: json['brand'],
    weightInGrams: (json['weightInGrams'] as num).toDouble(),
    quantity: json['quantity'],
    isSugarFree: json['isSugarFree'] ?? false,
    price: (json['price'] as num).toDouble(),
    oldPrice: json['oldPrice'] != null ? (json['oldPrice'] as num).toDouble() : null,
    discount: (json['discount'] as num).toDouble(),
    sku: json['sku'],
  );

  Map<String, dynamic> toJson() => {
    'chocolateType': chocolateType,
    'brand': brand,
    'weightInGrams': weightInGrams,
    'quantity': quantity,
    'isSugarFree': isSugarFree,
    'price': price,
    'oldPrice': oldPrice,
    'discount': discount,
    'sku': sku,
  };
}
