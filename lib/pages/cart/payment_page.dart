// payment_page.dart
import 'package:flutter/material.dart';
import 'package:joy_a_bloom_dev/pages/cart/step_indicator.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: const Center(
        child: Column(
          children: [
            StepIndicator(currentStep: 3), // only cart is green
            Text("💳 Payment Page", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
