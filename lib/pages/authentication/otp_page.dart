import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../home_page.dart';

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
  final _otpController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

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
        _goToHome(); // ✅ This method is already defined below
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

      // If user already existed, go to home
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCred.user!.uid)
              .get();

      if (doc.exists) {
        _goToHome();
      } else {
        // Save new user data
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user!.uid)
            .set({
              'email': widget.email,
              'phone': widget.phone,
              'name': widget.name ?? '',
              'createdAt': DateTime.now().toIso8601String(),
            });

        _goToHome();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid OTP or verification failed.")),
      );
    }
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
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
                    // Handle change number
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
                Icon(Icons.email),
                SizedBox(width: 8),
                Text(widget.email),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 45,
                  child: TextField(
                    controller: _otpControllers[index],
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
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
                  onTap: () {
                    // Handle resend OTP
                  },
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
            _showOtpSentMessage
                ? Container(
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
                )
                : const SizedBox.shrink(),
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
