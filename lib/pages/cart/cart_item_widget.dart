import 'package:flutter/material.dart';

import '../../models/cart_item.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback? onCakeMessageTap;
  final String? cakeMessage;
  final VoidCallback? onCardMessageTap;
  final Map<String, dynamic>? cardMessageData;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    this.onCakeMessageTap,
    this.cakeMessage,
    this.onCardMessageTap,
    this.cardMessageData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.productImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                  ),
                ),
                const SizedBox(width: 12),

                // Product Info & Quantity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Decrease / Delete
                          IconButton(
                            icon: Icon(
                              item.quantity == 1
                                  ? Icons.delete_outline
                                  : Icons.remove,
                            ),
                            onPressed: onDecrease,
                          ),
                          Text(
                            item.quantity.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: onIncrease,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 🎂 Cake Message Tile
            if (onCakeMessageTap != null)
              buildMessageTile(
                icon: Icons.cake_outlined,
                title:
                    cakeMessage != null
                        ? "Edit Cake Message"
                        : "Message on Cake",
                subtitle: cakeMessage,
                onTap: onCakeMessageTap!,
              ),

            // 💌 Free Card Tile
            if (onCardMessageTap != null)
              buildMessageTile(
                icon: Icons.card_giftcard_outlined,
                title:
                    cardMessageData != null
                        ? "Edit Greeting Card"
                        : "Add Free Greeting Card",
                subtitle:
                    cardMessageData != null
                        ? "${cardMessageData!['occasion']}: ${cardMessageData!['message']}"
                        : null,
                onTap: onCardMessageTap!,
              ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green.shade700, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle.length > 50
                            ? "${subtitle.substring(0, 50)}..."
                            : subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
