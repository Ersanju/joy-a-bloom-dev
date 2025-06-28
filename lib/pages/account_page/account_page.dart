import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  File? _localImage;
  String? _firestoreImageUrl;
  String userId = 'ersanjay';

  String _name = 'Loading...';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _name = data['name'] ?? '';
        _email = data['email'] ?? '';
        _firestoreImageUrl = data['profileImageUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _localImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;
    if (_localImage != null) {
      imageProvider = FileImage(_localImage!);
    } else if (_firestoreImageUrl != null && _firestoreImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_firestoreImageUrl!);
    }

    return Scaffold(
      backgroundColor: const Color(0xfffafaf6),
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xfffafaf6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              leading: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: imageProvider,
                  child:
                      imageProvider == null
                          ? const Icon(
                            Icons.account_circle,
                            size: 48,
                            color: Colors.grey,
                          )
                          : null,
                ),
              ),
              title: Text(
                _name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_email),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                  _loadUserData(); // refresh after edit
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
