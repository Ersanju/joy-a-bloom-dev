import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/product.dart';

class ChocolateProductDetailPage extends StatefulWidget {
  final String productId;

  const ChocolateProductDetailPage({super.key, required this.productId});

  @override
  State<ChocolateProductDetailPage> createState() =>
      _ChocolateProductDetailPageState();
}

class _ChocolateProductDetailPageState
    extends State<ChocolateProductDetailPage> {
  Product? product;
  List<Product> similarProducts = [];
  int selectedPackIndex = 0;
  bool isLoading = true;
  bool isLoadingSimilar = true;

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  Future<void> fetchProduct() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(widget.productId)
              .get();

      if (doc.exists) {
        product = Product.fromJson(doc.data()!);
        setState(() => isLoading = false);
        fetchSimilarProducts(product!.categoryId);
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchSimilarProducts(String categoryId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('products')
            .where('categoryId', isEqualTo: categoryId)
            .get();

    final products =
        snapshot.docs
            .map((doc) => Product.fromJson(doc.data()))
            .where((p) => p.id != widget.productId)
            .toList();

    setState(() {
      similarProducts = products;
      isLoadingSimilar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (product == null) {
      return const Scaffold(body: Center(child: Text("Product not found")));
    }

    final variants = product!.extraAttributes?.chocolateAttribute?.variants;
    final selectedVariant = variants?[selectedPackIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: const [
          Icon(Icons.search, color: Colors.black),
          SizedBox(width: 16),
          Icon(Icons.share, color: Colors.black),
          SizedBox(width: 16),
        ],
      ),
      bottomNavigationBar:
          selectedVariant == null
              ? null
              : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey, width: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      "₹${selectedVariant.price.toStringAsFixed(0)}\n(Inclusive of all taxes)",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite_border),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text("Add"),
                      ),
                    ),
                  ],
                ),
              ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildProductHeader(product!),
            Image.network(
              product!.imageUrls.first,
              height: 240,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            buildPackSelector(product!, variants ?? []),
            const Divider(height: 32, thickness: 4),
            buildSection("About the Product", product!.productDescription),
            const Divider(thickness: 4),
            buildSection("Care Instructions", product!.careInstruction),
            const Divider(),
            buildSection("Delivery Information", product!.deliveryInformation),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Ratings & Reviews",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                "4.2 ★ (9884 ratings and 108 reviews)",
                style: TextStyle(color: Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            if (!isLoadingSimilar) buildSimilarProductsSection(similarProducts),
          ],
        ),
      ),
    );
  }

  Widget buildProductHeader(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                product.extraAttributes!.chocolateAttribute!.brand,
                style: const TextStyle(color: Colors.green),
              ),
              const Icon(
                Icons.arrow_right_outlined,
                size: 30,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, size: 11, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      "4.4",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "9884 ratings & 108 reviews",
                style: TextStyle(color: Colors.green, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPackSelector(Product product, List<dynamic> variants) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Pack sizes:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              Text(
                " ${variants[selectedPackIndex].weightInGrams.toInt()}g",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: variants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final v = variants[index];
                final isSelected = selectedPackIndex == index;
                final pricePerGram = v.price / v.weightInGrams;

                return GestureDetector(
                  onTap: () => setState(() => selectedPackIndex = index),
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.white70
                                      : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${v.weightInGrams.toInt()} g",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "₹${v.price}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              " (₹${pricePerGram.toStringAsFixed(2)}/g)",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSection(String title, List<String> lines) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text("• $line"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSimilarProductsSection(List<Product> similarProducts) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Similar Products",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: similarProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = similarProducts[index];
                final variant =
                    product.extraAttributes?.chocolateAttribute?.variants.first;
                final hasDiscount =
                    (variant?.oldPrice ?? 0) > (variant?.price ?? 0);
                final discountLabel =
                    hasDiscount
                        ? "${(((variant!.oldPrice! - variant.price) / variant.oldPrice!) * 100).toStringAsFixed(0)}% OFF"
                        : null;

                return GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ChocolateProductDetailPage(
                              productId: product.id,
                            ),
                      ),
                    );
                  },
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              child: Image.network(
                                product.imageUrls.first,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₹${variant?.price.toStringAsFixed(0) ?? "--"}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (variant?.oldPrice != null && hasDiscount)
                                    Text(
                                      "₹${variant!.oldPrice!.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (discountLabel != null)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                discountLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        const Positioned(
                          bottom: 8,
                          right: 8,
                          child: Icon(
                            Icons.add_circle_outline,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
