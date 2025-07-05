import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../utils/wishlist_provider.dart';
import '../../widgets/chocolate_product_card.dart';
import '../../widgets/product_card.dart';
import '../product_detail_page.dart';

class ProductsByCategoryGridPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ProductsByCategoryGridPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ProductsByCategoryGridPage> createState() =>
      _ProductsByCategoryGridPageState();
}

class _ProductsByCategoryGridPageState
    extends State<ProductsByCategoryGridPage> {
  Future<List<Product>>? _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = fetchProductsByTopCategory(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body:
          _futureProducts == null
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<List<Product>>(
                future: _futureProducts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    debugPrint('Product load error: ${snapshot.error}');
                    return const Center(child: Text("Failed to load products"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No products found"));
                  }

                  final products = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      itemCount: products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemBuilder: (_, index) {
                        final product = products[index];
                        final productMap = product.toJson();

                        if (widget.categoryId == 'cat_chocolate') {
                          return ChocolateProductCard(
                            productData: productMap,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ProductDetailPage(
                                          productData: productMap,
                                        ),
                                  ),
                                ),
                            cartQty: 0,
                            onAdd: () {},
                            onRemove: () {},
                            onVariantTap: () {},
                          );
                        } else {
                          return ProductCard(
                            productData: productMap,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ProductDetailPage(
                                          productData: productMap,
                                        ),
                                  ),
                                ),
                            isWishlisted: wishlistProvider.isWishlisted(
                              product.id,
                            ),
                            onWishlistToggle: () {
                              setState(() {
                                wishlistProvider.toggleWishlist(product.id);
                              });
                            },
                          );
                        }
                      },
                    ),
                  );
                },
              ),
    );
  }

  Future<List<Product>> fetchProductsByTopCategory(String categoryId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .where('categoryId', isEqualTo: categoryId)
              .get();

      List<Product> allProducts =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Product.fromJson(data);
          }).toList();

      allProducts.shuffle();
      return allProducts.take(30).toList();
    } catch (e) {
      debugPrint("Error fetching products: $e");
      return [];
    }
  }
}
