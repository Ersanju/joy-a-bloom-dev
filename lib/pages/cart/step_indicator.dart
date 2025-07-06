import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Icon(Icons.shopping_cart, color: Colors.green),
          Container(height: 4, width: 64, color: Colors.grey.shade300),
          const Icon(Icons.local_shipping_outlined, color: Colors.grey),
          Container(height: 4, width: 64, color: Colors.grey.shade300),
          const Icon(Icons.currency_rupee, color: Colors.grey),
        ],
      ),
    );
  }
}
