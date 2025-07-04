import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../pages/authentication/app_auth_provider.dart';
import '../../utils/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../product_detail_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Map<String, dynamic>> wishlistProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWishlistProducts();
  }

  Future<void> _fetchWishlistProducts() async {
    final userId = context.read<AppAuthProvider>().userId;

    if (userId.isEmpty) {
      setState(() {
        wishlistProducts = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final wishlistIds = List<String>.from(
      userDoc.data()?['wishlistProductIds'] ?? [],
    );

    if (wishlistIds.isEmpty) {
      setState(() {
        wishlistProducts = [];
        _isLoading = false;
      });
      return;
    }

    final query =
        await FirebaseFirestore.instance
            .collection('products')
            .where(FieldPath.documentId, whereIn: wishlistIds)
            .get();

    setState(() {
      wishlistProducts =
          query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _isLoading = false;
    });
  }

  Future<void> _removeFromWishlist(String productId) async {
    setState(() {
      wishlistProducts.removeWhere((p) => p['id'] == productId);
    });

    try {
      await context.read<WishlistProvider>().removeFromWishlist(productId);
    } catch (e) {
      // Optionally show an error message
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final userId = context.read<AppAuthProvider>().userId;
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    final cartItem = {
      'productId': product['id'],
      'quantity': 1,
      'sku':
          product['extraAttributes']?['cakeAttribute']?['defaultVariant'] ?? '',
    };

    await userRef.update({
      'cartItems': FieldValue.arrayUnion([cartItem]),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Added to Cart")));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();

    // Show login prompt if not logged in
    if (authProvider.userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Wishlist')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Login to view and manage your wishlist."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/login',
                  ); // Update your login route here
                },
                child: const Text("Login"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : wishlistProducts.isEmpty
              ? const Center(child: Text("Your wishlist is empty."))
              : GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: wishlistProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.55,
                ),
                itemBuilder: (_, index) {
                  final product = wishlistProducts[index];
                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // Center align all children
                    children: [
                      ProductCard(
                        productData: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      ProductDetailPage(productData: product),
                            ),
                          );
                        },
                        isWishlisted: true,
                        onWishlistToggle:
                            () => _removeFromWishlist(product['id']),
                      ),
                      const SizedBox(height: 4),

                      // Add to Cart button
                      SizedBox(
                        width: 135,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.shopping_cart, size: 16),
                          label: const Text(
                            "Add to Cart",
                            style: TextStyle(fontSize: 13),
                          ),
                          onPressed: () => _addToCart(product),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade400,
                            minimumSize: const Size.fromHeight(34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      // Remove button
                      SizedBox(
                        width: 135,
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          label: const Text(
                            "Remove",
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                          onPressed: () => _removeFromWishlist(product['id']),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
