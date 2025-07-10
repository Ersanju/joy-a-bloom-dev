import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<
    ({String location, String pinCode, double latitude, double longitude})
  >
  getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services are disabled.");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied.");
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) throw Exception("Location not found");

    final place = placemarks.first;
    return (
      location: '${place.locality}, ${place.administrativeArea}',
      pinCode: place.postalCode ?? '',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
