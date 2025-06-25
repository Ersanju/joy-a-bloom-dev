import 'package:cloud_firestore/cloud_firestore.dart';
import 'review.dart';
import 'extra_attributes.dart';

class Product {
  final String id;
  final String name;
  final String categoryId;
  final List<String> subCategoryIds;
  final String productType;
  final List<String> imageUrls;
  final List<String> productDescription;
  final List<String> careInstruction;
  final List<String> deliveryInformation;
  final List<String> tags;
  final bool isAvailable;
  final int stockQuantity;
  final int popularityScore;
  final List<Review> reviews;
  final ExtraAttributes? extraAttributes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.subCategoryIds,
    required this.productType,
    required this.imageUrls,
    required this.productDescription,
    required this.careInstruction,
    required this.deliveryInformation,
    required this.tags,
    required this.isAvailable,
    required this.stockQuantity,
    required this.popularityScore,
    required this.reviews,
    this.extraAttributes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    categoryId: json['categoryId'],
    subCategoryIds: List<String>.from(json['subCategoryIds'] ?? []),
    productType: json['productType'] ?? '',
    imageUrls: List<String>.from(json['imageUrls'] ?? []),
    productDescription: List<String>.from(json['productDescription'] ?? []),
    careInstruction: List<String>.from(json['careInstruction'] ?? []),
    deliveryInformation: List<String>.from(json['deliveryInformation'] ?? []),
    tags: List<String>.from(json['tags'] ?? []),
    isAvailable: json['isAvailable'] ?? true,
    stockQuantity: json['stockQuantity'] ?? 0,
    popularityScore: json['popularityScore'] ?? 0,
    reviews: (json['reviews'] as List?)?.map((e) => Review.fromJson(e)).toList() ?? [],
    extraAttributes: json['extraAttributes'] != null
        ? ExtraAttributes.fromJson(json['extraAttributes'])
        : null,
    createdAt: (json['createdAt'] is Timestamp)
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
    updatedAt: (json['updatedAt'] is Timestamp)
        ? (json['updatedAt'] as Timestamp).toDate()
        : DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now(),
    createdBy: json['createdBy'] ?? '',

  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'subCategoryIds': subCategoryIds,
    'productType': productType,
    'imageUrls': imageUrls,
    'productDescription': productDescription,
    'careInstruction': careInstruction,
    'deliveryInformation': deliveryInformation,
    'tags': tags,
    'isAvailable': isAvailable,
    'stockQuantity': stockQuantity,
    'popularityScore': popularityScore,
    'reviews': reviews.map((e) => e.toJson()).toList(),
    'extraAttributes': extraAttributes?.toJson(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'createdBy': createdBy,
  };
}
