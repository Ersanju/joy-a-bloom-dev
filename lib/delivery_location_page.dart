import 'package:flutter/material.dart';

class DeliveryLocationPage extends StatelessWidget {
  const DeliveryLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Delivery Location",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_outlined),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Let's Personalize Your Experience!",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Find the perfect gifts for you or your loved ones - it's like magic!",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text("🇮🇳  India"),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: "271001,Gonda, Uttar Pradesh",
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: Icon(Icons.clear),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
