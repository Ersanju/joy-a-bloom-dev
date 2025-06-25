import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/cake_attribute.dart';
import '../../models/extra_attributes.dart';
import '../../models/product.dart';
import '../../models/shape.dart';
import '../../models/variant.dart'; // Ensure this contains all sub-models properly

class ProductsByCategoryGridPage extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const ProductsByCategoryGridPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: FutureBuilder<List<Product>>(
        future: fetchProductsByTopCategory(categoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Failed to load products"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No products found"));
          }

          final products = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (_, index) {
                final product = products[index];
                return _buildProductCard(product);
              },
            ),
          );
        },
      ),
    );
  }

  Future<List<Product>> fetchProductsByTopCategory(String categoryId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .where('isAvailable', isEqualTo: true)
        .get();

    print("Fetched ${snapshot.docs.length} products for $categoryId");

    return snapshot.docs.map((doc) {
      final data = doc.data();
      print("Product found: ${data['name']}");

      return Product(
        id: doc.id,
        name: data['name'],
        categoryId: data['categoryId'],
        subCategoryIds: List<String>.from(data['subCategoryIds']),
        productType: data['productType'],
        imageUrls: List<String>.from(data['imageUrls']),
        productDescription: List<String>.from(data['productDescription']),
        careInstruction: List<String>.from(data['careInstruction']),
        deliveryInformation: List<String>.from(data['deliveryInformation']),
        tags: List<String>.from(data['tags']),
        isAvailable: data['isAvailable'],
        stockQuantity: data['stockQuantity'],
        popularityScore: data['popularityScore'],
        reviews: [],
        extraAttributes: null,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: data['createdBy'] ?? '',
      );
    }).toList();
  }

  Widget _buildProductCard(Product product) {
    double? price;

    if (product.productType.contains("cake") &&
        product.extraAttributes?.cakeAttribute?.defaultVariant.price != null) {
      price = product.extraAttributes!.cakeAttribute!.defaultVariant.price;
    }

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to product detail page
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                product.imageUrls.isNotEmpty
                    ? product.imageUrls.first
                    : 'https://via.placeholder.com/150',
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                price != null ? '₹${price.toStringAsFixed(0)}' : 'Price not available',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
