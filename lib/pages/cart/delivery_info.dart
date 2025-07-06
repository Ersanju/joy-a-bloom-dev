import 'package:flutter/material.dart';

class DeliveryInfo extends StatelessWidget {
  const DeliveryInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.calendar_today_outlined),
      title: const Text('11th Jul, 09:00 am - 09:00 pm'),
      subtitle: const Text('Courier ₹19'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }
}
