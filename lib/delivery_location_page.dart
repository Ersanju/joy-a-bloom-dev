import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryLocationPage extends StatefulWidget {
  const DeliveryLocationPage({super.key});

  @override
  State<DeliveryLocationPage> createState() => _DeliveryLocationPageState();
}

class _DeliveryLocationPageState extends State<DeliveryLocationPage> {
  final _pinController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isPinValid = false;
  String? _errorMessage;

  // Sample list of serviceable pincodes
  final List<String> serviceablePins = [
    '110001',
    '271001',
    '400001',
    '560001',
    '122001',
  ];

  final String _selectedCountry = 'India';

  void _validatePin() {
    String enteredPin = _pinController.text.trim();

    if (enteredPin.length != 6) {
      setState(() {
        _isPinValid = false;
        _errorMessage = "Please enter a valid 6-digit pin code.";
      });
      return;
    }

    if (serviceablePins.contains(enteredPin)) {
      setState(() {
        _isPinValid = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isPinValid = false;
        _errorMessage = "Sorry! We don't deliver to this pin code yet.";
      });
    }
  }

  void _saveLocation() {
    String pin = _pinController.text.trim();
    String location = _locationController.text.trim();

    if (pin.isNotEmpty && location.isNotEmpty) {
      Navigator.pop(context, {'pin': pin, 'location': location});
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _locationController.dispose();
    super.dispose();
  }

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
      body: SingleChildScrollView(
        // <-- This allows scrolling when keyboard opens
        child: Padding(
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
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  items: [
                    DropdownMenuItem(
                      value: 'India',
                      child: Row(
                        children: const [
                          Text('🇮🇳  '),
                          SizedBox(width: 4),
                          Text('India'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {},
                  decoration: InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text("Use Current Location"),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: "Enter Pin Code",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: "",
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _validatePin,
                    child: const Text("Check Availability"),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (_isPinValid) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: "Enter your location (City/Area)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveLocation,
                    child: const Text("Save Location"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission permanently denied")),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;

      String fetchedPin = place.postalCode ?? '';
      String fetchedLocation = "${place.locality}, ${place.administrativeArea}";

      // Directly return to HomePage with this data
      Navigator.pop(context, {'pin': fetchedPin, 'location': fetchedLocation});
    }
  }

}
