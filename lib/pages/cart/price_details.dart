import 'package:flutter/material.dart';

class PriceDetails extends StatelessWidget {
  final int productPrice;
  final int discount;
  final int deliveryCharge;
  final int convenienceCharge;

  const PriceDetails({
    super.key,
    required this.productPrice,
    required this.discount,
    required this.deliveryCharge,
    required this.convenienceCharge,
  });

  @override
  Widget build(BuildContext context) {
    int subtotal = productPrice - discount;
    int finalAmount =
        (subtotal > 0 ? subtotal : 0) + deliveryCharge + convenienceCharge;

    return Card(
      margin: const EdgeInsets.all(10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _priceRow("Total Product Price", "₹$productPrice"),
            _priceRow("Discount On MRP", "-₹$discount", color: Colors.green),
            _priceRow("Delivery Charges", "₹$deliveryCharge"),
            _priceRow("Convenience Charge", "₹$convenienceCharge"),
            const Divider(),
            _priceRow("Total Amount", "₹$finalAmount", isBold: true),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.green.shade50,
              child: Text(
                discount > 0
                    ? "🎉 You are saving ₹$discount on this order"
                    : productPrice < 500
                    ? "🛍️ Add more items worth ₹${500 - productPrice} to unlock discounts & free delivery"
                    : "✅ You are eligible for free delivery, add more for additional discounts!",
                style: TextStyle(
                  color: discount > 0 ? Colors.green : Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
    String title,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.black,
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
