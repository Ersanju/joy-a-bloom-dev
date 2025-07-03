import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:joy_a_bloom_dev/pages/authentication/signup_page.dart';

import 'otp_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();

  Future<Map<String, String>> fetchLoginAssets() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('app_assets')
            .doc('login_assets')
            .get();

    final data = doc.data();
    return {
      'bannerUrl':
          data?['bannerUrl'] ??
          'https://via.placeholder.com/600x400.png?text=Banner',
      'logoUrl':
          data?['logoUrl'] ??
          'https://via.placeholder.com/100x100.png?text=Logo',
      'googleLogoUrl':
          data?['googleLogoUrl'] ??
          'https://via.placeholder.com/100x100.png?text=Logo',
    };
  }

  Future<void> _handleContinue() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid email")));
      return;
    }

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final user = snapshot.docs.first.data();
      final phone = user['phone'];

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpPage(phone: phone, email: email)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SignupPage(prefilledEmail: email)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: FutureBuilder<Map<String, String>>(
        future: fetchLoginAssets(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bannerUrl = snapshot.data!['bannerUrl']!;
          final logoUrl = snapshot.data!['logoUrl']!;
          final googleLogoUrl = snapshot.data!['googleLogoUrl']!;

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Banner with logo overlay
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Image.network(
                        bannerUrl,
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.45,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: -45,
                        left: MediaQuery.of(context).size.width / 2 - 45,
                        child: Material(
                          elevation: 8,
                          shape: const CircleBorder(),
                          shadowColor: Colors.black45,
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: Image.network(
                                logoUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  const Text(
                    "Sign Up / Login to Joy-a-Bloom!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "For a personalized experience & faster checkout",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined),
                        hintText: "Enter Email Address",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF88803D),
                        ),
                        onPressed: _handleContinue,
                        child: const Text("Continue"),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Row(
                    children: [
                      Expanded(
                        child: Divider(thickness: 1, indent: 24, endIndent: 10),
                      ),
                      Text("or Login with"),
                      Expanded(
                        child: Divider(thickness: 1, indent: 10, endIndent: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: Image.network(
                          googleLogoUrl, // <- this should be fetched from Firestore
                          height: 24,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.error, size: 24),
                        ),
                        label: const Text("Login with Google"),
                        onPressed: () {
                          // Hook up Firebase Auth Google login
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text.rich(
                      TextSpan(
                        text: 'By continuing, you agree to Joy-a-More’s\n',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(color: Colors.blue),
                          ),
                          TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
