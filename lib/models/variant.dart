class Variant {
  final String weight;
  final int tier;
  final double price;
  final double? oldPrice;
  final double discount; // updated to double
  final String sku;

  Variant({
    required this.weight,
    required this.tier,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.sku,
  });

  factory Variant.fromJson(Map<String, dynamic> json) => Variant(
    weight: json['weight'] ?? '',
    tier: json['tier'] ?? 1,
    price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
    oldPrice:
        (json['oldPrice'] is num) ? (json['oldPrice'] as num).toDouble() : 0.0,
    discount:
        (json['discount'] is num) ? (json['discount'] as num).toDouble() : 0.0,
    sku: json['sku'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'tier': tier,
    'price': price,
    'oldPrice': oldPrice,
    'discount': discount,
    'sku': sku,
  };
}
