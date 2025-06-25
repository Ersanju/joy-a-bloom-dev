class ToyAttribute {
  final String ageGroup;
  final String material;
  final String brand;
  final double price;
  final String sku;

  ToyAttribute({
    required this.ageGroup,
    required this.material,
    required this.brand,
    required this.price,
    required this.sku,
  });

  factory ToyAttribute.fromJson(Map<String, dynamic> json) => ToyAttribute(
    ageGroup: json['ageGroup'],
    material: json['material'],
    brand: json['brand'],
    price: (json['price'] as num).toDouble(),
    sku: json['sku'],
  );

  Map<String, dynamic> toJson() => {
    'ageGroup': ageGroup,
    'material': material,
    'brand': brand,
    'price': price,
    'sku': sku,
  };
}
