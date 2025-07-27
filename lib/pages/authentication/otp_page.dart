import 'dart:async';

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
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  String? _verificationId;
  Timer? _resendTimer;
  int _cooldownSeconds = 60;
  bool _canResend = false;
  bool _showOtpSentMessage = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _sendOtp();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showOtpSentMessage = false);
    });
  }

  Future<void> _sendOtp() async {
    if (!_canResend && _verificationId != null) {
      _showSnackBar("Please wait before resending OTP.");
      return;
    }

    setState(() => _canResend = false);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phone,
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _postLoginTasks();
          _navigateToHome();
        },
        verificationFailed: (e) => _showSnackBar("OTP failed: ${e.message}"),
        codeSent:
            (id, _) => setState(() {
              _verificationId = id;
              _startCooldown();
            }),
        codeAutoRetrievalTimeout: (_) {},
      );
    } on FirebaseAuthException catch (e) {
      final msg =
          e.code == 'too-many-requests'
              ? "Too many attempts. Try again later."
              : "OTP error: ${e.message}";
      _showSnackBar(msg);
    }
  }

  void _startCooldown() {
    _cooldownSeconds = 60;
    _resendTimer?.cancel();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _verifyOtp() async {
    final smsCode = _otpControllers.map((c) => c.text).join();
    if (smsCode.length < 6 || _verificationId == null) {
      _showSnackBar("Enter full 6-digit OTP");
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      await _postLoginTasks(userCred.user?.uid);
      _navigateToHome();
    } on FirebaseAuthException {
      _showSnackBar("Invalid OTP or verification failed.");
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _postLoginTasks([String? uid]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid ?? user.uid)
            .get();
    if (!doc.exists) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': widget.email,
        'phone': widget.phone,
        'name': widget.name ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    await _syncWishlist();
    await _syncCart();
  }

  Future<void> _syncWishlist() async {
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
    context.read<WishlistProvider>().setWishlist(wishlistIds);
  }

  Future<void> _syncCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartList =
        (await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get())
                .data()?['cartItems']
            as List<dynamic>? ??
        [];

    final cartProvider = context.read<CartProvider>();
    await cartProvider.clearCart();
    for (final item in cartList) {
      cartProvider.setQty(
        CartItem.fromJson(item).variant,
        CartItem.fromJson(item).quantity,
      );
    }
  }

  void _handleFullOtpInput(String value) {
    if (value.length == 6) {
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = value[i];
      }
      _focusNodes[5].requestFocus();
      _verifyOtp();
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  void _showSnackBar(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpControllers.forEach((c) => c.dispose());
    _focusNodes.forEach((f) => f.dispose());
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  onTap: () => Navigator.pop(context),
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
            Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.0,
                    child: TextField(
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      onChanged: _handleFullOtpInput,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 45,
                      height: 50,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          final code =
                              _otpControllers.map((c) => c.text).join();
                          if (code.length == 6) _verifyOtp();
                        },
                        onSubmitted: (_) {
                          if (index == 5) _verifyOtp();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Valid for 2 mins."),
                const Spacer(),
                InkWell(
                  onTap: _canResend ? _sendOtp : null,
                  child: Text(
                    _canResend
                        ? "Resend OTP"
                        : "Resend in $_cooldownSeconds sec",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: _canResend ? Colors.blue : Colors.grey,
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
                onPressed: _isVerifying ? null : _verifyOtp,
                child:
                    _isVerifying
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
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
