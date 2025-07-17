import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joy_a_bloom_dev/pages/cart/step_indicator.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final double fnpCashBalance = 150;
  final double totalAmount = 963;
  bool useFnpCash = false;
  int? _expandedIndex;
  int? _selectedUpiApp;
  bool _saveUpi = false;
  bool _saveCard = false;
  final TextEditingController _upiController = TextEditingController();
  bool _isUpiVerified = false;
  bool _showVerifyButton = false;
  final TextEditingController _expiryController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> upiApps = [
    {"name": "CRED", "image": "cred-app-icon.png"},
    {"name": "GPay", "image": "gpay-logo.png"},
    {"name": "Axis Mobile", "image": "axis-logo.png"},
    {"name": "iMobile", "image": "i-mobile.png"},
    {"name": "PhonePe", "image": "phonepay.png"},
    {"name": "Amazon", "image": "amazon-logo.png"},
  ];

  @override
  void initState() {
    super.initState();

    _upiController.addListener(() {
      setState(() {
        _showVerifyButton = _upiController.text.isNotEmpty;
        _isUpiVerified = false;
      });
    });

    _expiryController.addListener(() {
      final oldText = _expiryController.text;
      final oldSelection = _expiryController.selection;

      final digitsOnly = oldText.replaceAll(RegExp(r'[^0-9]'), '');
      String formatted = '';
      int offset = oldSelection.baseOffset;

      if (digitsOnly.length >= 3) {
        formatted =
            '${digitsOnly.substring(0, 2)}/${digitsOnly.substring(2, digitsOnly.length.clamp(2, 4))}';
      } else if (digitsOnly.length == 2) {
        formatted = '${digitsOnly.substring(0, 2)}/';
      } else {
        formatted = digitsOnly;
      }

      if (oldText != formatted) {
        int newOffset = offset;

        // When adding the slash
        if (digitsOnly.length == 2 &&
            oldText.length < formatted.length &&
            offset == 2) {
          newOffset++;
        }

        // When deleting the slash
        if (oldText.length > formatted.length &&
            offset == 3 &&
            oldText.contains('/')) {
          newOffset--;
        }

        _expiryController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(
            offset: newOffset.clamp(0, formatted.length),
          ),
        );
      }
    });
  }

  bool _canPay() {
    final usingUpiApp = _selectedUpiApp != null;
    final usingUpiId = _upiController.text.isNotEmpty && _isUpiVerified;

    return usingUpiApp ||
        usingUpiId ||
        (_expandedIndex != null && _expandedIndex != 0);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              StepIndicator(currentStep: 3),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildPaymentSection(),
                      const SizedBox(height: 60),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildSecureNote(),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildPayButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            "Payment Options",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(),
        _buildPaymentOption(
          index: 0,
          title: "GooglePay/ BHIM/ PhonePe/ UPI",
          icon: Icons.account_balance_wallet,
          child: Column(
            children: [
              ...upiApps.asMap().entries.map((entry) {
                final index = entry.key;
                final app = entry.value;
                return RadioListTile<int>(
                  value: index,
                  groupValue: _selectedUpiApp,
                  onChanged: (val) => setState(() => _selectedUpiApp = val),
                  title: Text(app["name"] ?? ""),
                  secondary: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: AssetImage(
                      'assets/payment/${app["image"]}',
                    ),
                  ),
                );
              }),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "OR",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _upiController,
                        onTap: _scrollToBottom,
                        decoration: const InputDecoration(
                          hintText: "Enter UPI ID: (Ex. 9988776655@icici)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                    ),

                    if (_showVerifyButton) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isUpiVerified = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("UPI ID Verified ✅")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // Adjust radius as needed
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ), // Optional for better spacing
                        ),
                        child: const Text("Verify"),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isUpiVerified)
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "UPI ID verified ✅",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100, width: 0.6),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _saveUpi,
                      onChanged:
                          (value) => setState(() => _saveUpi = value ?? false),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Expanded(
                      child: Text(
                        "Save UPI ID for faster payments",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildPaymentOption(
          index: 1,
          title: "Credit/Debit Card",
          icon: Icons.credit_card,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Card Number - digits only, max 19 (16 + spaces)
                _styledTextField(
                  "Card Number",
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                ),
                const SizedBox(height: 12),

                // Name on Card - only alphabets and spaces
                _styledTextField(
                  "Name on card",
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    // Expiry - MM/YY format, restrict to 5 characters
                    Expanded(
                      flex: 2,
                      child: _styledTextField(
                        "Expiry Date (MM/YY)",
                        controller: _expiryController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                          LengthLimitingTextInputFormatter(5),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // CVV - 3 or 4 digits
                    Expanded(
                      flex: 1,
                      child: _styledTextField(
                        "CVV",
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Checkbox(
                      value: _saveCard,
                      onChanged:
                          (value) => setState(() => _saveCard = value ?? false),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text("Save card for fast Checkout"),
                    const Spacer(),
                    const Text(
                      "RBI Guidelines",
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        _buildPaymentOption(
          index: 2,
          title: "Net Banking",
          icon: Icons.account_balance,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...[
                  "Axis Bank",
                  "State Bank of India",
                  "HDFC Bank",
                  "ICICI Bank",
                  "Kotak Bank",
                  "Yes Bank",
                ].asMap().entries.map(
                  (entry) => RadioListTile<int>(
                    value: entry.key,
                    groupValue: _selectedUpiApp,
                    onChanged: (val) => setState(() => _selectedUpiApp = val),
                    title: Text(entry.value),
                    secondary: Image.asset(
                      'assets/payment/${entry.value.toLowerCase().replaceAll(" ", "_")}.png',
                      width: 60,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(Icons.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildPaymentOption(
          index: 3,
          title: "Wallet",
          icon: Icons.account_balance_wallet_outlined,
          subtitle: "2 Offers",
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Choose a wallet to pay from."),
          ),
        ),
      ],
    );
  }

  Widget _styledTextField(
    String hintText, {
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        counterText: "", // hides counter when maxLength is set
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required String title,
    required IconData icon,
    Widget? child,
    String? subtitle,
  }) {
    final isExpanded = _expandedIndex == index;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle:
              subtitle != null
                  ? Text(subtitle, style: const TextStyle(color: Colors.green))
                  : null,
          trailing: Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          ),
          onTap:
              () => setState(() => _expandedIndex = isExpanded ? null : index),
        ),
        if (isExpanded) child ?? const SizedBox.shrink(),
        const Divider(),
      ],
    );
  }

  Widget _buildSecureNote() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user, color: Colors.green),
          const SizedBox(height: 8),
          const Text("100% Safe & Secure Payments"),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _logoImage('assets/payment/verified_by_visa.png'),
              _logoImage('assets/payment/mastercard_secure.png'),
              _logoImage('assets/payment/rupay.png'),
              _logoImage('assets/payment/american_express.png'),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _logoImage(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Image.asset(assetPath, width: 50, height: 30, fit: BoxFit.contain),
    );
  }

  Widget _buildPayButton(BuildContext context) {
    final amount = useFnpCash ? totalAmount - fnpCashBalance : totalAmount;
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: ElevatedButton(
        onPressed: _canPay() ? () {} : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade800,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Text(
          "Pay ₹ $amount",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
