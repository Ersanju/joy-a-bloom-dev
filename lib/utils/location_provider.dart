import 'package:flutter/cupertino.dart';

class LocationProvider extends ChangeNotifier {
  String? _location;
  String? _pinCode;

  String? get location => _location;

  String? get pinCode => _pinCode;

  void update({required String location, required String pinCode}) {
    _location = location;
    _pinCode = pinCode;
    notifyListeners();
  }
}
