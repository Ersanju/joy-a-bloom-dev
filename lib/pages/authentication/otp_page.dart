import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../home_page.dart';
import '../../models/cart_item.dart';
import '../../utils/cart_provider.dart';
import '../../utils/wishlist_provider.dart';

class OtpPage extends StatefulWidget {
  final String phone;
  final String email;
  final String? name;

  const OtpPage({required this.phone, required this.email, this.name});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  String? _verificationId;
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _showOtpSentMessage = true;

  @override
  void initState() {
    super.initState();
    _sendOtp();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showOtpSentMessage = false;
        });
      }
    });
  }

  void _sendOtp() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phone,
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        _goToHome();
      },
      verificationFailed: (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("OTP failed: ${e.message}")));
      },
      codeSent: (verificationId, _) {
        setState(() => _verificationId = verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  void _verifyOtp() async {
    final smsCode = _otpControllers.map((c) => c.text.trim()).join();

    if (_verificationId == null || smsCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter the full 6-digit OTP")),
      );
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCred.user!.uid)
              .get();

      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user!.uid)
            .set({
              'email': widget.email,
              'phone': widget.phone,
              'name': widget.name ?? '',
              'createdAt': DateTime.now().toIso8601String(),
            });
      }

      await _loadAndSyncWishlist();
      await _loadAndSyncCart();

      _goToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP or verification failed.")),
      );
    }
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  Future<void> _loadAndSyncWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final wishlistIds = List<String>.from(
      doc.data()?['wishlistProductIds'] ?? [],
    );

    if (mounted) {
      context.read<WishlistProvider>().setWishlist(wishlistIds);
    }
  }

  Future<void> _loadAndSyncCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final cartList = doc.data()?['cartItems'] as List<dynamic>? ?? [];

    final cartProvider = context.read<CartProvider>();
    await cartProvider.clearCart();

    for (final item in cartList) {
      final cartItem = CartItem.fromJson(item);
      cartProvider.setQty(cartItem.variant, cartItem.quantity);
    }
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8ED),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              "OTP sent to your mobile & email Id",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.phone_android),
                const SizedBox(width: 8),
                Text(widget.phone),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Navigator.pop(context); // Change number
                  },
                  child: const Text(
                    "Change",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.email),
                const SizedBox(width: 8),
                Text(widget.email),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 50,
                  child: RawKeyboardListener(
                    focusNode: FocusNode(),
                    onKey: (event) {
                      if (event.logicalKey == LogicalKeyboardKey.backspace &&
                          _otpControllers[index].text.isEmpty &&
                          index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _otpControllers[index].text = value;
                          _otpControllers[index]
                              .selection = TextSelection.collapsed(offset: 1);

                          if (index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else {
                            _focusNodes[index].unfocus();
                            _verifyOtp(); // Auto-verify
                          }
                        }
                      },
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Valid for 2 mins."),
                const Spacer(),
                InkWell(
                  onTap: _sendOtp,
                  child: const Text(
                    "Resend OTP",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (_showOtpSentMessage)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6EA),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_box, color: Colors.green),
                    SizedBox(width: 8),
                    Text("OTP sent to mobile & email ID."),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A8E3E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _verifyOtp,
                child: const Text(
                  "Confirm OTP",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
