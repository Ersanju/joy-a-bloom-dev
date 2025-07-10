import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_address.dart';
import 'add_address_page.dart';

class SavedAddressesPage extends StatefulWidget {
  const SavedAddressesPage({super.key});

  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  final user = FirebaseAuth.instance.currentUser;

  void _addAddress(UserAddress addressData) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'addresses': FieldValue.arrayUnion([addressData.toJson()]),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save address: $e')));
    }
  }

  Future<List<UserAddress>> _getUserAddresses() async {
    if (user == null) return [];
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

    if (!doc.exists || doc.data() == null) return [];

    final data = doc.data()!;
    final List addresses = data['addresses'] ?? [];

    return addresses
        .map((addr) => UserAddress.fromJson(Map<String, dynamic>.from(addr)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saved Addresses")),
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => AddAddressPage(
                        onSave: (addressData) async {
                          _addAddress(addressData);
                          setState(() {}); // Refresh UI after adding
                        },
                      ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              color: Colors.green[100],
              child: const Row(
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text("Add Address"),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserAddress>>(
              future: _getUserAddresses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final addresses = snapshot.data ?? [];

                if (addresses.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 60, color: Colors.red),
                        SizedBox(height: 10),
                        Text("No saved addresses yet"),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final addr = addresses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(
                          addr.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          "${addr.area}, ${addr.street}, ${addr.landmark}\n"
                          "${addr.city}, ${addr.state}, ${addr.pinCode}\n"
                          "Phone: ${addr.phone}",
                        ),
                        trailing: Chip(
                          label: Text(addr.addressType.toUpperCase()),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
