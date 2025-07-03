import 'package:flutter/material.dart';

class ChocolateProductCard extends StatelessWidget {
  final Map<String, dynamic> productData;
  final VoidCallback onTap;
  final int cartQty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onVariantTap;

  const ChocolateProductCard({
    super.key,
    required this.productData,
    required this.onTap,
    required this.cartQty,
    required this.onAdd,
    required this.onRemove,
    required this.onVariantTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        (productData['imageUrls'] as List?)?.first ??
        "https://via.placeholder.com/150";
    final name = productData['name'] ?? '';

    final chocolateAttr = productData['extraAttributes']?['chocolateAttribute'];
    final variant = (chocolateAttr?['variants'] as List?)?.first;

    if (variant == null) return const SizedBox.shrink();

    final price = variant['price'] ?? 0;
    final oldPrice = variant['oldPrice'];
    final weightInGrams = variant['weightInGrams']?.toInt() ?? 0;

    String? discountLabel;
    if (oldPrice != null && oldPrice > price) {
      final discountPercent = ((oldPrice - price) / oldPrice) * 100;
      discountLabel =
          discountPercent >= 10
              ? "${discountPercent.toStringAsFixed(0)}% OFF"
              : "₹${(oldPrice - price).toStringAsFixed(0)} OFF";
    }

    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(128, 128, 128, 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onTap,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        imageUrl,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
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
                              topLeft: Radius.circular(12),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            discountLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "₹${price.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (oldPrice != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              "₹${oldPrice.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onVariantTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Text(
                        "${weightInGrams}g",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.green,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
          Positioned(
            top: 95,
            right: 1,
            child:
                cartQty == 0
                    ? GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.green, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 24,
                          color: Colors.green,
                        ),
                      ),
                    )
                    : Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.green, width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: onRemove,
                            child: const Icon(
                              Icons.remove,
                              size: 20,
                              color: Colors.green,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '$cartQty',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onAdd,
                            child: const Icon(
                              Icons.add,
                              size: 20,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
