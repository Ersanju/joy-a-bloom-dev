import 'package:joy_a_bloom_dev/models/shape.dart';
import 'package:joy_a_bloom_dev/models/variant.dart';

class CakeAttribute {
  final Variant defaultVariant;
  final List<Variant> variants;
  final List<Shape> shapes;
  final bool isEgglessAvailable;

  CakeAttribute({
    required this.defaultVariant,
    required this.variants,
    required this.shapes,
    required this.isEgglessAvailable,
  });

  factory CakeAttribute.fromJson(Map<String, dynamic> json) => CakeAttribute(
    defaultVariant: Variant.fromJson(json['defaultVariant']),
    variants: List<Variant>.from((json['variants'] as List).map((e) => Variant.fromJson(e))),
    shapes: List<Shape>.from((json['shapes'] as List).map((e) => Shape.fromJson(e))),
    isEgglessAvailable: json['isEgglessAvailable'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'defaultVariant': defaultVariant.toJson(),
    'variants': variants.map((e) => e.toJson()).toList(),
    'shapes': shapes.map((e) => e.toJson()).toList(),
    'isEgglessAvailable': isEgglessAvailable,
  };
}
