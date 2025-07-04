import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../utils/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../product_detail_page.dart'; // Update path as needed

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
    final wishlistProvider = Provider.of<WishlistProvider>(context);
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
                childAspectRatio: 0.85,
              ),
              itemBuilder: (_, index) {
                final product = products[index];
                return ProductCard(
                  productData: product.toJson(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ProductDetailPage(
                              productData: product.toJson(),
                            ),
                      ),
                    );
                  },
                  isWishlisted: wishlistProvider.isWishlisted(product.id),
                  onWishlistToggle:
                      () => wishlistProvider.toggleWishlist(product.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<List<Product>> fetchProductsByTopCategory(String categoryId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('products')
            .where('categoryId', isEqualTo: categoryId)
            .where('available', isEqualTo: true)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Product.fromJson(data..['id'] = doc.id); // Ensure `id` is set
    }).toList();
  }
}
