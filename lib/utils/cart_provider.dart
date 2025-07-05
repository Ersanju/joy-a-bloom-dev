import 'package:flutter/foundation.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, int> _cartItems = {}; // key = variantId

  Map<String, int> get cartItems => _cartItems;

  int getQuantity(String variantId) => _cartItems[variantId] ?? 0;

  void addItem(String variantId) {
    _cartItems[variantId] = getQuantity(variantId) + 1;
    notifyListeners();
  }

  void removeItem(String variantId) {
    final qty = getQuantity(variantId);
    if (qty > 1) {
      _cartItems[variantId] = qty - 1;
    } else {
      _cartItems.remove(variantId);
    }
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
