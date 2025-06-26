import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> productData;
  final VoidCallback onTap;

  const ProductCard({Key? key, required this.productData, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultVariant =
        productData['extraAttributes']?['cakeAttribute']?['defaultVariant'];
    final price = defaultVariant?['price'] ?? 0;
    final oldPrice = defaultVariant?['oldPrice'] ?? 0;
    final discount =
        (oldPrice > price)
            ? (((oldPrice - price) / oldPrice) * 100).round()
            : 0;
    final imageUrl =
        (productData['imageUrls'] as List?)?.first ??
        "https://via.placeholder.com/150";
    final name = productData['name'] ?? '';
    final rating = productData['averageRating'] ?? 4.5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlays
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Product name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  // fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            // Price and discount
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text(
                    "₹$price",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (discount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "$discount% OFF",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  if (oldPrice > price)
                    Text(
                      "₹$oldPrice",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
