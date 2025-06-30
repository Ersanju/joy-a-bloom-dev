import 'chocolate_variant.dart';

class ChocolateAttribute {
  final String brand;
  final List<ChocolateVariant> variants;

  ChocolateAttribute({
    required this.brand,
    required this.variants,
  });

  factory ChocolateAttribute.fromJson(Map<String, dynamic> json) =>
      ChocolateAttribute(
        brand: json['brand'] ?? '',
        variants: (json['variants'] as List<dynamic>?)
            ?.map((v) => ChocolateVariant.fromJson(v))
            .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
    'brand': brand,
    'variants': variants.map((v) => v.toJson()).toList(),
  };
}