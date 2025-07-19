import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BecomePartnerPage extends StatefulWidget {
  const BecomePartnerPage({super.key});

  @override
  State<BecomePartnerPage> createState() => _BecomePartnerPageState();
}

class _BecomePartnerPageState extends State<BecomePartnerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _selectedCategory = 'Flowers';

  final List<Map<String, String>> _categories = [
    {'title': 'Flowers', 'image': 'assets/flowers.png'},
    {'title': 'Cakes', 'image': 'assets/cakes.png'},
    {'title': 'Chocolates', 'image': 'assets/explosion_box.png'},
    {'title': 'Balloon\nDecorations', 'image': 'assets/kids.png'},
  ];

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final String mobile = _mobileController.text.trim();

      final Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
        'mobile': mobile,
        'email': _emailController.text.trim(),
        'city': _cityController.text.trim(),
        'area': _areaController.text.trim(),
        'category': _selectedCategory,
        'comments': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      try {
        final docRef = FirebaseFirestore.instance
            .collection('partners')
            .doc(mobile);
        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          // Ask for confirmation to update
          final bool? shouldUpdate = await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Partner Already Exists'),
                  content: const Text(
                    'A partner with this mobile number already exists.\nDo you want to update the existing details?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Update'),
                    ),
                  ],
                ),
          );

          if (shouldUpdate != true) return; // Don't proceed if canceled
        }

        // Save or update the document
        await docRef.set(data);

        // Show success dialog
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Text(
                  '🎉 Greetings!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  'Thank you for submitting your details.\n\nOur partner support team will reach out to you shortly.',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );

        _formKey.currentState!.reset();
        setState(() {}); // Reset form state
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become A Partner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Become a Joy-a-Bloom Planters Partner today!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'At Joy-a-Bloom, we believe in delivering joy every day. From delicious cakes and thoughtful gifts to adorable toys, vibrant plants, elegant planters, beautiful décor, and curated event services — we bring celebrations to life with love and care. '
              'Our diverse collection is crafted to make birthdays, anniversaries, festivals, and every special moment more memorable. We work closely with trusted partners, ensuring quality, creativity, and timely delivery through regular checks and high service standards. '
              'Joy-a-Bloom isn’t just about products — it’s about experiences that bloom with happiness.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Divider(),
            const Text(
              'Benefits to FNP Partner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: const [
                _BenefitIcon(icon: Icons.verified, label: 'Use of brand name'),
                _BenefitIcon(
                  icon: Icons.support_agent,
                  label: 'FNP Website Support',
                ),
                _BenefitIcon(icon: Icons.build, label: 'Partner Support Team'),
                _BenefitIcon(
                  icon: Icons.currency_rupee,
                  label: 'Timely Payments',
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Product Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3 / 2,
              ),
              itemBuilder: (context, index) {
                final item = _categories[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(item['image']!, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            item['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Divider(),
            const Text(
              'GET IN TOUCH WITH US',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Enter your details and our partner support team will call you right back',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFormSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '* Contact Name'),
            validator: (value) => value!.isEmpty ? 'Enter contact name' : null,
            textCapitalization: TextCapitalization.words,
          ),
          TextFormField(
            controller: _mobileController,
            decoration: const InputDecoration(labelText: '* Mobile Number'),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator:
                (value) =>
                    value == null || value.length != 10
                        ? 'Enter valid 10-digit mobile number'
                        : null,
          ),

          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: '* Enter Email ID'),
            keyboardType: TextInputType.emailAddress,
            validator:
                (value) => value!.contains('@') ? null : 'Enter valid email',
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items:
                _categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat['title'],
                        child: Text(cat['title']!),
                      ),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value!),
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: '* Enter City'),
                  validator: (value) => value!.isEmpty ? 'Enter city' : null,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _areaController,
                  decoration: const InputDecoration(labelText: '* Enter Area'),
                  validator: (value) => value!.isEmpty ? 'Enter area' : null,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          TextFormField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: 'Comments'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _submitForm,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: const Text(
                    'Request a Callback',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.deepPurple),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
