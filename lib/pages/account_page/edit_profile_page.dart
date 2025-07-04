import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/app_util.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: EditProfileForm(),
      ),
    );
  }
}

class EditProfileForm extends StatefulWidget {
  const EditProfileForm({super.key});

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(); // read-only
  final _phoneController = TextEditingController();
  late final String userId;
  late final User _currentUser; // ✅ For Firebase Auth
  File? _localImage; // ✅ For storing compressed image locally

  File? _profileImage;
  String? _firestoreImageUrl;

  String _title = 'Mr.';
  String _gender = 'Male';
  DateTime? _dob;
  DateTime? _anniversary;
  String _maritalStatus = 'Unmarried';

  final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.grey),
  );

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUser = user;
      userId = user.uid;
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        final fullPhone = data['phone'] ?? '';
        _phoneController.text = fullPhone.replaceFirst(RegExp(r'^\+91'), '');
        _gender = data['gender'] ?? 'Male';
        _firestoreImageUrl = data['profileImageUrl'];
        _dob = data['dob'] != null ? DateTime.tryParse(data['dob']) : null;
        _anniversary =
            data['anniversary'] != null
                ? DateTime.tryParse(data['anniversary'])
                : null;
      });
    }
  }

  Future<void> _pickDate(BuildContext context, bool isDOB) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => isDOB ? _dob = picked : _anniversary = picked);
    }
  }

  Future<void> _pickImage() async {
    final url = await AppUtil.pickAndUploadProfileImage(
      context: context,
      user: _currentUser,
    );

    if (url != null) {
      setState(() {
        _firestoreImageUrl = url;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedData = {
      'name': _nameController.text.trim(),
      'gender': _gender,
      'dob': _dob?.toIso8601String(),
      'anniversary': _anniversary?.toIso8601String(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update(updatedData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_profileImage != null) {
      imageProvider = FileImage(_profileImage!);
    } else if (_firestoreImageUrl != null && _firestoreImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_firestoreImageUrl!);
    } else {
      imageProvider = const AssetImage('assets/profile_placeholder.png');
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(radius: 50, backgroundImage: imageProvider),
              Positioned(
                right: 4,
                bottom: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 16),
                    onPressed: _pickImage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _nameController,
            validator:
                (val) =>
                    val == null || val.trim().isEmpty ? "Enter name" : null,
            decoration: InputDecoration(
              labelText: 'Name',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _title,
                    items:
                        ['Mr.', 'Ms.', 'Mrs.']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => _title = val!),
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
              border: _border,
              focusedBorder: _border,
              enabledBorder: _border,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              border: _border,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            enabled: false,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Enter phone number';
              if (val.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(val)) {
                return 'Enter valid 10-digit number';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Mobile',
              prefix: const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Text(
                  '🇮🇳 +91',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              border: _border,
              focusedBorder: _border,
              enabledBorder: _border,
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _gender,
            items:
                ['Male', 'Female', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: (val) => setState(() => _gender = val!),
            decoration: InputDecoration(labelText: 'Gender', border: _border),
          ),
          const SizedBox(height: 16),

          _buildDateField(
            label: 'Date of Birth',
            date: _dob,
            onTap: () => _pickDate(context, true),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _maritalStatus,
            items:
                ['Unmarried', 'Married']
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
            onChanged: (val) => setState(() => _maritalStatus = val!),
            decoration: InputDecoration(
              labelText: 'Marital Status',
              border: _border,
              focusedBorder: _border,
              enabledBorder: _border,
            ),
          ),
          const SizedBox(height: 16),

          if (_maritalStatus == 'Married') ...[
            _buildDateField(
              label: 'Date of Anniversary',
              date: _anniversary,
              onTap: () => _pickDate(context, false),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D8C52),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save & Continue',
                style: TextStyle(color: Colors.deepPurple, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            hintText: 'DD/MM/YYYY',
            suffixIcon: const Icon(Icons.calendar_today),
            border: _border,
          ),
          controller: TextEditingController(
            text: date == null ? '' : '${date.day}/${date.month}/${date.year}',
          ),
        ),
      ),
    );
  }
}
