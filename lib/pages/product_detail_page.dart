import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/cart_provider.dart';
import '../widgets/delivery_location_section.dart';
import 'cart/cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Map<String, dynamic>> _productDataFuture;
  int _selectedVariantIndex = 0;
  int _selectedImage = 0;
  Timer? _autoScrollTimer;
  late PageController _pageController;
  int? _expandedTileIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _productDataFuture = _fetchProductData();
  }

  Future<Map<String, dynamic>> _fetchProductData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .get();
    if (doc.exists) {
      _startAutoScroll();
      return doc.data()!;
    } else {
      throw Exception("Product not found");
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_pageController.hasClients) return;
      final totalPages = 5; // Set a fallback
      final nextPage = (_selectedImage + 1) % totalPages;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _selectedImage = nextPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _productDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text("Failed to load product")),
          );
        }

        final productData = snapshot.data!;
        final imageUrls = List<String>.from(productData['imageUrls'] ?? []);
        final variants = List<Map<String, dynamic>>.from(
          productData['extraAttributes']?['cakeAttribute']?['variants'] ?? [],
        );
        final selectedVariant = variants[_selectedVariantIndex];
        final double price = (selectedVariant['price'] as num).toDouble();
        final double? oldPrice =
            selectedVariant['oldPrice'] != null
                ? (selectedVariant['oldPrice'] as num).toDouble()
                : null;

        return Scaffold(
          appBar: AppBar(title: const Text("Product description")),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildImageCarousel(imageUrls),
                  const SizedBox(height: 20),
                  buildProductPriceRow(
                    name: productData['name'] ?? 'Unnamed',
                    price: price,
                    oldPrice: oldPrice,
                  ),
                  const SizedBox(height: 10),
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
                  const DeliveryLocationSection(),
                  const SizedBox(height: 20),
                  buildAboutExpandableTilesSection(productData),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          bottomNavigationBar: buildBottomAddToCartButton(
            context,
            productData,
            selectedVariant,
          ),
        );
      },
    );
  }

  Widget buildImageCarousel(List<String> imageUrls) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 300,
            width: double.infinity,
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
      ],
    );
  }

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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (oldPrice != null)
              Text(
                "₹$oldPrice",
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
            if (discountPercent > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  "$discountPercent% OFF",
                  style: const TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ],
    );
  }

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
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
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
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          variant['image'] ?? imageUrls.first,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Icon(Icons.broken_image),
                        ),
                      ),
                      const SizedBox(height: 6),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "About the product",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(dynamicTiles.length, (index) {
          final tile = dynamicTiles[index];
          final isExpanded = _expandedTileIndex == index;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(tile["icon"]),
                  title: Text(tile["title"]),
                  trailing: Icon(isExpanded ? Icons.remove : Icons.add),
                  onTap: () {
                    setState(() {
                      _expandedTileIndex = isExpanded ? null : index;
                    });
                  },
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          (tile["content"] as List<String>).map((line) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("• "),
                                  Expanded(child: Text(line)),
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
    );
  }

  Widget buildBottomAddToCartButton(
    BuildContext context,
    Map<String, dynamic> product,
    Map<String, dynamic> selectedVariant,
  ) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final productId = product['id'];
    final productName = product['name'];
    final imageUrl = (product['imageUrls'] as List).first;
    final price = (selectedVariant['price'] as num).toDouble();
    final sku = selectedVariant['sku'];
    final variantId = "${productId}_$sku";
    final isInCart = cartProvider.getQty(variantId) > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isInCart ? Colors.orange : Colors.green.shade700,
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Added to cart")));
            setState(() {});
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
