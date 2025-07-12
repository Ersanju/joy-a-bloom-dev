import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/review.dart';
import '../utils/cart_provider.dart';
import '../utils/wishlist_provider.dart';
import '../widgets/delivery_location_section.dart';
import '../widgets/product_card.dart';
import 'cart/cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailPage({super.key, required this.productData});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedImage = 0;
  late PageController _pageController;
  int _selectedVariantIndex = 0;
  Timer? _autoScrollTimer;
  int? _expandedTileIndex;
  late Future<List<Review>> _reviewsFuture;
  late Future<List<Product>> _similarProductsFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
    _reviewsFuture = fetchProductReviews(widget.productData['id']);
    _similarProductsFuture = fetchSimilarProductsByTags(
      currentProductId: widget.productData['id'],
      tags: List<String>.from(widget.productData['tags'] ?? []),
    ).then((products) {
      products.shuffle(); // Shuffle once, here
      return products;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = List<String>.from(widget.productData['imageUrls'] ?? []);
    final name = widget.productData['name'] ?? 'Unnamed';
    final variants = List<Map<String, dynamic>>.from(
      widget.productData['extraAttributes']?['cakeAttribute']?['variants'] ??
          [],
    );
    final selectedVariant = variants[_selectedVariantIndex];
    final double price = (selectedVariant['price'] as num).toDouble();
    final double? oldPrice =
        selectedVariant['oldPrice'] != null
            ? (selectedVariant['oldPrice'] as num).toDouble()
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Product description'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildImageCarousel(imageUrls),
              const SizedBox(height: 20),
              buildProductPriceRow(
                name: name,
                price: price,
                oldPrice: oldPrice,
              ),

              //  Price inclusive
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () {
                  showPriceDetailsBottomSheet(
                    context: context,
                    price: price,
                    oldPrice: oldPrice,
                  );
                },
                child: const Text(
                  "Price inclusive of all taxes >",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),

              // Available options
              const Text(
                "Available Options",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              buildVariantSelector(
                variants: variants,
                selectedIndex: _selectedVariantIndex,
                onVariantSelected: (index) {
                  setState(() {
                    _selectedVariantIndex = index;
                  });
                },
                imageUrls: imageUrls,
              ),
              const SizedBox(height: 20),

              // Delivery Location
              DeliveryLocationSection(),
              const SizedBox(height: 20),

              // About the product
              buildAboutExpandableTilesSection(widget.productData),

              Padding(
                padding: const EdgeInsets.all(1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Customer Reviews",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Review>>(
                      future: _reviewsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Text("Failed to load reviews");
                        }
                        return buildReviewSlider(snapshot.data ?? []);
                      },
                    ),
                  ],
                ),
              ),

              // You may also like section
              buildSimilarProductsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildBottomAddToCartButton(context, selectedVariant),
    );
  }

  // Image Carousel
  Widget buildImageCarousel(List<String> imageUrls) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 320,
            width: 340,
            child: PageView.builder(
              controller: _pageController,
              itemCount: imageUrls.length,
              onPageChanged: (index) => setState(() => _selectedImage = index),
              itemBuilder: (context, index) {
                return Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder:
                      (_, __, ___) => const Icon(Icons.broken_image, size: 200),
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imageUrls.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      _selectedImage == index ? Colors.white : Colors.white54,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;

      final int totalPages = widget.productData['imageUrls']?.length ?? 1;
      final int nextPage = (_selectedImage + 1) % totalPages;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      setState(() {
        _selectedImage = nextPage;
      });
    });
  }

  // Name, Price
  Widget buildProductPriceRow({
    required String name,
    required double price,
    double? oldPrice,
  }) {
    final int discountPercent =
        (oldPrice != null && oldPrice > 0)
            ? (((oldPrice - price) / oldPrice) * 100).round()
            : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              "₹$price",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            if (oldPrice != null)
              Text(
                "₹$oldPrice",
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            const SizedBox(width: 10),
            if (oldPrice != null)
              Text(
                '$discountPercent% OFF',
                style: const TextStyle(color: Colors.green, fontSize: 14),
              ),
          ],
        ),
      ],
    );
  }

  void showPriceDetailsBottomSheet({
    required BuildContext context,
    required double price,
    double? oldPrice,
  }) {
    final int savings = (oldPrice != null) ? (oldPrice - price).round() : 0;
    final int discountPercent =
        oldPrice != null && oldPrice > 0
            ? ((savings / oldPrice) * 100).round()
            : 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.remove, size: 32, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                "Price Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                title: const Text("Maximum Retail Price"),
                subtitle: const Text("(Inclusive of all taxes)"),
                trailing: Text(
                  "₹${oldPrice?.toInt() ?? price.toInt()}",
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              ListTile(
                title: const Text("Selling Price"),
                trailing: Text(
                  "₹${price.toInt()}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              if (oldPrice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    "You save ₹$savings ($discountPercent%) on this product",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Product variants
  Widget buildVariantSelector({
    required List<Map<String, dynamic>> variants,
    required int selectedIndex,
    required void Function(int) onVariantSelected,
    required List<String> imageUrls,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            variants.asMap().entries.map((entry) {
              final int index = entry.key;
              final variant = entry.value;
              final bool isSelected = index == selectedIndex;

              return GestureDetector(
                onTap: () => onVariantSelected(index),
                child: Container(
                  width: 100,
                  height: 150,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.red : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected ? Colors.red.shade50 : Colors.white,
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          variant['image'] ?? imageUrls.first,
                          height: 90,
                          width: 90,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Icon(Icons.broken_image),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text('${variant['weight']}'),
                      Text(
                        '₹${variant['price']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget buildAboutExpandableTilesSection(Map<String, dynamic> product) {
    // Safely extract list fields or fallback to an empty list
    final List<String> productDescription = List<String>.from(
      product['productDescription'] ?? [],
    );
    final List<String> careInstruction = List<String>.from(
      product['careInstruction'] ?? [],
    );
    final List<String> deliveryInformation = List<String>.from(
      product['deliveryInformation'] ?? [],
    );

    final List<Map<String, dynamic>> dynamicTiles = [
      {
        "title": "Product Description",
        "icon": Icons.assignment,
        "content": productDescription,
      },
      {
        "title": "Care Instructions",
        "icon": Icons.insert_chart,
        "content": careInstruction,
      },
      {
        "title": "Delivery Information",
        "icon": Icons.local_shipping,
        "content": deliveryInformation,
      },
    ];

    return Container(
      color: const Color(0xFFF9F9F4),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "About the product",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...List.generate(dynamicTiles.length, (index) {
            final tile = dynamicTiles[index];
            final isExpanded = _expandedTileIndex == index;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Icon(tile["icon"], color: Colors.green.shade800),
                    title: Text(
                      tile["title"],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Icon(isExpanded ? Icons.close : Icons.add),
                    onTap: () {
                      _expandedTileIndex = isExpanded ? null : index;
                      // Use StatefulBuilder or make expandedTileIndex a State variable
                      (this as dynamic).setState(() {});
                    },
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            (tile["content"] as List<String>).map((line) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "• ",
                                      style: TextStyle(height: 1.5),
                                    ),
                                    Expanded(
                                      child: Text(
                                        line,
                                        style: const TextStyle(height: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildReviewSlider(List<Review> reviews) {
    if (reviews.isEmpty) {
      return const Text("No reviews yet.");
    }

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reviews.length,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final review = reviews[index];
          return Container(
            width: 240,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ReviewUserInfo(review: review),
                    const SizedBox(width: 8),
                    Text(
                      "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating.round()
                          ? Icons.star
                          : Icons.star_border,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  review.comment,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    if (review.occasion.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          review.occasion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    if (review.place.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          border: Border.all(color: Colors.teal),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          review.place,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Review>> fetchProductReviews(String productId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

    if (!doc.exists) return [];

    final data = doc.data();
    if (data == null || data['reviews'] == null) return [];

    final List<dynamic> reviewList = data['reviews'];

    return reviewList
        .map((item) => Review.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // sort newest first
  }

  Widget buildSimilarProductsSection() {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, _) {
        return FutureBuilder<List<Product>>(
          future: _similarProductsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text("No similar products found");
            }

            final products = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "You May Also Like",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isWishlisted = wishlistProvider.isWishlisted(
                        product.id,
                      );

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
                        isWishlisted: isWishlisted,
                        onWishlistToggle: () {
                          wishlistProvider.toggleWishlist(product.id);
                          // Also optionally update Firestore here if needed
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Product>> fetchSimilarProductsByTags({
    required String currentProductId,
    required List<String> tags,
    int limit = 12,
  }) async {
    if (tags.isEmpty) {
      debugPrint("No tags provided");
      return [];
    }

    debugPrint("Fetching products with tags: $tags");

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('products')
            .where('tags', arrayContainsAny: tags)
            .limit(limit)
            .get();

    debugPrint("Fetched ${querySnapshot.docs.length} similar products");

    final similarProducts =
        querySnapshot.docs
            .where((doc) => doc.id != currentProductId)
            .map((doc) {
              try {
                return Product.fromJson(doc.data());
              } catch (e) {
                debugPrint("Error parsing product with id ${doc.id}: $e");
                return null;
              }
            })
            .whereType<Product>() // removes nulls
            .toList();

    debugPrint("Parsed ${similarProducts.length} valid similar products");

    return similarProducts;
  }

  Widget buildBottomAddToCartButton(
    BuildContext context,
    Map<String, dynamic> selectedVariant,
  ) {
    final cartProvider = Provider.of<CartProvider>(context);
    final product = widget.productData;
    final productId = product['id'];
    final productName = product['name'];
    final imageUrl = (product['imageUrls'] as List).first;
    final price = (selectedVariant['price'] as num).toDouble();
    final sku = selectedVariant['sku'];
    final variantId = "${productId}_$sku";

    final isInCart = cartProvider.getQty(variantId) > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isInCart ? Colors.orange.shade600 : Colors.green.shade600,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () {
          if (isInCart) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            );
          } else {
            cartProvider.addItem(
              variantId,
              productId: productId,
              productName: productName,
              productImage: imageUrl,
              price: price,
            );
            setState(() {}); // refresh the button
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Added to cart")));
          }
        },
        child: Text(
          isInCart ? "Go to Cart" : "Add to Cart",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class ReviewUserInfo extends StatelessWidget {
  final Review review;

  const ReviewUserInfo({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Colors.green,
          radius: 14,
          child: Icon(Icons.person, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 6),
        Text(
          review.userName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
