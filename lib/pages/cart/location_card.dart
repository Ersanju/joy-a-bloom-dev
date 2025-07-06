import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/location_provider.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>().location;
    final pincode = context.watch<LocationProvider>().pinCode;

    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(
        location ?? 'No delivery location selected',
        style: const TextStyle(fontSize: 14),
      ),
      tileColor: Colors.grey.shade100,
      subtitle: Text(pincode!),
    );
  }
}
