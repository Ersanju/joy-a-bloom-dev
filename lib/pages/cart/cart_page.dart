import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/cart_provider.dart';
import 'cart_bottom_bar.dart';
import 'cart_item_widget.dart';
import 'delivery_info.dart';
import 'location_card.dart';
import 'price_details.dart';
import 'step_indicator.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.cartItems;
    final isEmpty = cartItems.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart'), leading: const BackButton()),
      body:
          isEmpty
              ? const Center(
                child: Text(
                  "🛒 Your cart is empty",
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const StepIndicator(),
                          const LocationCard(),
                          ListView.builder(
                            itemCount: cartItems.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              return CartItemWidget(
                                item: item,
                                onIncrease:
                                    () => cartProvider.addItem(
                                      item.variant,
                                      productId: item.productId,
                                      productName: item.productName,
                                      productImage: item.productImage,
                                      price: item.price,
                                    ),
                                onDecrease:
                                    () => cartProvider.removeItem(item.variant),
                              );
                            },
                          ),
                          const DeliveryInfo(),
                          PriceDetails(
                            productPrice: cartProvider.productPrice,
                            discount: cartProvider.discount,
                            deliveryCharge: cartProvider.deliveryCharge,
                            convenienceCharge: cartProvider.convenienceCharge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  CartBottomBar(total: cartProvider.total),
                ],
              ),
    );
  }
}
