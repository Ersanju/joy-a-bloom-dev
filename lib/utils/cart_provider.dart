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

  /// Get quantity by variant ID
  int getQty(String variantId) {
    return _cartItems
        .firstWhere(
          (item) => item.variant == variantId,
          orElse: () => CartItem.empty(),
        )
        .quantity;
  }

  /// Add item
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

  /// Remove item
  Future<void> removeItem(String variantId) async {
    if (user == null) return;

    final index = _cartItems.indexWhere((item) => item.variant == variantId);
    if (index >= 0) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index] = _cartItems[index].copyWith(
          quantity: _cartItems[index].quantity - 1,
        );
      } else {
        _cartItems.removeAt(index);
      }

      await _saveCartToFirestore();
      notifyListeners();
    }
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

  /// Clear cart
  Future<void> clearCart() async {
    _cartItems.clear();
    await _saveCartToFirestore();
    notifyListeners();
  }

  /// External cart set
  void setCart(List<CartItem> items) {
    _cartItems
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  /// Directly set quantity
  void setQty(String variantId, int qty) {
    final index = _cartItems.indexWhere((item) => item.variant == variantId);
    if (index >= 0) {
      if (qty > 0) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: qty);
      } else {
        _cartItems.removeAt(index);
      }
    } else {
      // Optionally handle adding here if needed
    }
    notifyListeners();
  }
}
