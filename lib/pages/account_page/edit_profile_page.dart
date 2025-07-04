import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_util.dart';
import '../authentication/app_auth_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _title = 'Mr.';
  String _gender = 'Male';
  String _maritalStatus = 'Unmarried';
  DateTime? _dob;
  DateTime? _anniversary;
  String? _profileImageUrl;

  final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.grey),
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = context.read<AppAuthProvider>().userId;
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
        _profileImageUrl = data['profileImageUrl'];
        _dob = data['dob'] != null ? DateTime.tryParse(data['dob']) : null;
        _anniversary =
            data['anniversary'] != null
                ? DateTime.tryParse(data['anniversary'])
                : null;
      });
    }
  }

  Future<void> _pickImage() async {
    final user = context.read<AppAuthProvider>().user!;
    final url = await AppUtil.pickAndUploadProfileImage(
      context: context,
      user: user,
    );

    if (url != null) {
      setState(() => _profileImageUrl = url);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AppAuthProvider>().userId;

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

  Future<void> _pickDate({required bool isDOB}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        isDOB ? _dob = picked : _anniversary = picked;
      });
    }
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
            text: date == null ? '' : DateFormat('dd/MM/yyyy').format(date),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget profileImageWidget =
        _profileImageUrl != null && _profileImageUrl!.isNotEmpty
            ? CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(_profileImageUrl!),
            )
            : const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  profileImageWidget,
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

              // Name + Title
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
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => _title = val!),
                      ),
                    ),
                  ),
                  border: _border,
                ),
              ),
              const SizedBox(height: 16),

              // Email
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

              // Phone
              TextFormField(
                controller: _phoneController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Mobile',
                  prefix: const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Text(
                      '🇮🇳 +91',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  border: _border,
                ),
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                value: _gender,
                items:
                    ['Male', 'Female', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (val) => setState(() => _gender = val!),
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: _border,
                ),
              ),
              const SizedBox(height: 16),

              // DOB
              _buildDateField(
                label: 'Date of Birth',
                date: _dob,
                onTap: () => _pickDate(isDOB: true),
              ),
              const SizedBox(height: 16),

              // Marital Status
              DropdownButtonFormField<String>(
                value: _maritalStatus,
                items:
                    ['Unmarried', 'Married']
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _maritalStatus = val!),
                decoration: InputDecoration(
                  labelText: 'Marital Status',
                  border: _border,
                ),
              ),
              const SizedBox(height: 16),

              if (_maritalStatus == 'Married') ...[
                _buildDateField(
                  label: 'Date of Anniversary',
                  date: _anniversary,
                  onTap: () => _pickDate(isDOB: false),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),

              // Save Button
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
        ),
      ),
    );
  }
}
