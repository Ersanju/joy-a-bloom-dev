import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryCheckPage extends StatefulWidget {
  const DeliveryCheckPage({super.key});

  @override
  State<DeliveryCheckPage> createState() => _DeliveryCheckPageState();
}

class _DeliveryCheckPageState extends State<DeliveryCheckPage> {
  static const double storeLat = 27.1234;
  static const double storeLng = 82.5678;

  String? _message;
  bool _isLoading = false;

  Future<void> _checkWithCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distanceInMeters = Geolocator.distanceBetween(
        storeLat,
        storeLng,
        position.latitude,
        position.longitude,
      );

      double distanceInKm = distanceInMeters / 1000;

      if (distanceInKm <= 10) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        Placemark place = placemarks.first;

        final location = '${place.locality}, ${place.administrativeArea}';
        final pin = '${place.postalCode}';

        Navigator.pop(context, {'location': location, 'pin': pin});
      } else {
        setState(
          () => _message = "Sorry! Delivery is only available within 10 km.",
        );
      }
    } catch (e) {
      setState(() => _message = "Failed to get location: ${e.toString()}");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Check Delivery Availability")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkWithCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text("Use Current Location"),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color:
                      _message!.startsWith("Sorry") ? Colors.red : Colors.green,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
