import 'package:flutter/material.dart';

import '../../home_page.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers =
  List.generate(4, (index) => TextEditingController());

  bool _showOtpSentMessage = true;

  @override
  void initState() {
    super.initState();
    // Hide OTP message after 2 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showOtpSentMessage = false;
        });
      }
    });
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
                const Text("9559555598"),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    // Handle change number
                  },
                  child: const Text("Change",
                      style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.email),
                SizedBox(width: 8),
                Text("hshgdhdhjzk@gmail.com"),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
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
                      if (value.isNotEmpty && index < 3) {
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
                  child: const Text("Resend OTP",
                      style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.blue)),
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
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => HomePage()));
                },
                child: const Text("Confirm OTP",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
