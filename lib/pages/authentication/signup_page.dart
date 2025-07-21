import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joy_a_bloom_dev/pages/authentication/otp_page.dart';

import '../account_page/privacy_policy_page.dart';

class SignupPage extends StatefulWidget {
  final String prefilledEmail;

  const SignupPage({super.key, required this.prefilledEmail});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String countryCode = '+91';

  Future<Map<String, String>> fetchAssets() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('app_assets')
            .doc('login_assets')
            .get();

    final data = doc.data() ?? {};
    return {
      'bannerUrl': data['bannerUrl'] ?? '',
      'logoUrl': data['logoUrl'] ?? '',
      'googleLogoUrl': data['googleLogoUrl'] ?? '',
    };
  }

  void _continueToOtp() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter a valid name and 10-digit phone number"),
        ),
      );
      return;
    }

    final fullPhone = '+91$phone'; // Fixed country code

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => OtpPage(
              phone: fullPhone, // send complete number
              email: widget.prefilledEmail,
              name: name,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, String>>(
        future: fetchAssets(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bannerUrl = snapshot.data!['bannerUrl']!;
          final logoUrl = snapshot.data!['logoUrl']!;

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      child: Image.network(
                        bannerUrl,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                    Positioned.fill(
                      bottom: -45,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Material(
                          elevation: 8,
                          shape: const CircleBorder(),
                          shadowColor: Colors.black45,
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(logoUrl),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                const Text(
                  'Welcome To Joy-a-Bloom!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Happiness is just a click away',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        enabled: false,
                        controller: TextEditingController(
                          text: widget.prefilledEmail,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CountryCodePicker(
                            onChanged: (code) {
                              countryCode = code.dialCode ?? '+91';
                            },
                            initialSelection: 'IN',
                            favorite: ['+91', 'IN'],
                            showDropDownButton: false,
                            enabled: false, // disables interaction
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Enter 10-digit phone number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF808000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _continueToOtp,
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(
                              text:
                                  "By continuing you agree to Joy-a-Bloom’s\n",
                            ),
                            TextSpan(
                              text: "Terms & Conditions & Privacy Policy",
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const PrivacyPolicyPage(),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
