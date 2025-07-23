import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  User? get user => FirebaseAuth.instance.currentUser;

  CartProvider() {
    _loadCart(); // Auto-load on init
  }

  /// Accurate total price
  double get rawProductTotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.price * item.quantity);

  /// Rounded total price
  int get productPrice => rawProductTotal.toInt();

  /// Dynamic discount rules
  int get discount {
    if (productPrice > 1000) return 100;
    if (productPrice > 500) return 50;
    return 0;
  }

  /// Delivery charge logic
  int get deliveryCharge => productPrice > 500 ? 0 : 19;

  /// Convenience charge logic
  int get convenienceCharge => productPrice > 500 ? 0 : 39;

  /// Final subtotal after discount
  int get subtotal =>
      (productPrice - discount).clamp(0, double.infinity).toInt();

  /// Final payable amount
  int get total => subtotal + deliveryCharge + convenienceCharge;

  /// Get quantity for a specific variant
  int getQty(String variantId) {
    return _cartItems
        .firstWhere(
          (item) => item.variant == variantId,
          orElse: () => CartItem.empty(),
        )
        .quantity;
  }

  /// Add item to cart
  Future<void> addItem(
    String variantId, {
    required String productId,
    required String productName,
    required String productImage,
    required double price,
  }) async {
    if (user == null) return;

    final index = _cartItems.indexWhere((item) => item.variant == variantId);
    if (index >= 0) {
      _cartItems[index] = _cartItems[index].copyWith(
        quantity: _cartItems[index].quantity + 1,
      );
    } else {
      _cartItems.add(
        CartItem(
          productId: productId,
          productName: productName,
          productImage: productImage,
          quantity: 1,
          variant: variantId,
          price: price,
        ),
      );
    }

    await _saveCartToFirestore();
    notifyListeners();
  }

  /// Remove item from cart
  Future<void> removeItem(String variantId) async {
    if (user == null) return;

    final index = _cartItems.indexWhere((item) => item.variant == variantId);
    if (index == -1) return;

    final currentItem = _cartItems[index];

    if (currentItem.quantity <= 1) {
      // 🗑️ Actually remove it when quantity is 1
      _cartItems.removeAt(index);
    } else {
      // ➖ Just decrease
      _cartItems[index] = currentItem.copyWith(
        quantity: currentItem.quantity - 1,
      );
    }

    await _saveCartToFirestore();
    notifyListeners();
  }

  /// Clear all items
  Future<void> clearCart() async {
    _cartItems.clear();
    await _saveCartToFirestore();
    notifyListeners();
  }

  /// Load cart from Firestore
  Future<void> _loadCart() async {
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
      final data = doc.data();
      final items =
          (data?['cartItems'] as List<dynamic>? ?? [])
              .map((e) => CartItem.fromJson(e))
              .toList();

      _cartItems
        ..clear()
        ..addAll(items);
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load cart: $e");
    }
  }

  /// Save cart to Firestore
  Future<void> _saveCartToFirestore() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'cartItems': _cartItems.map((e) => e.toJson()).toList()});
    } catch (e) {
      debugPrint("Failed to save cart: $e");
    }
  }

  /// Replace entire cart
  void setCart(List<CartItem> items) {
    _cartItems
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  /// Set quantity directly
  void setQty(String variantId, int qty) {
    final index = _cartItems.indexWhere((item) => item.variant == variantId);
    if (index >= 0) {
      if (qty > 0) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: qty);
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }
}
