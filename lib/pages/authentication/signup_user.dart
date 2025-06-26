import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';

import 'opt_verification_page.dart';

class SignupUser extends StatefulWidget {
  @override
  _SignupUserState createState() => _SignupUserState();
}

class _SignupUserState extends State<SignupUser> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String countryCode = '+91';

  Future<Map<String, String>> fetchAssets() async {
    final doc = await FirebaseFirestore.instance
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
          final googleLogoUrl = snapshot.data!['googleLogoUrl']!;

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
                        height: 200,
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
                const SizedBox(height: 50),
                const Text(
                  'Welcome To Joy-a-More!',
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
                        controller: nameController,
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
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
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
                            onChanged: (code) =>
                            countryCode = code.dialCode ?? '+91',
                            initialSelection: 'IN',
                            favorite: ['+91', 'IN'],
                          ),
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: 'Enter mobile number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OtpVerificationPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("or Login with"),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          icon: Image.network(
                            googleLogoUrl,
                            height: 24,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error),
                          ),
                          label: const Text("Login with Google"),
                          onPressed: () {
                            // Firebase Auth
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'By continuing you agree to Joy-a-More’s\nTerms & Conditions & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
