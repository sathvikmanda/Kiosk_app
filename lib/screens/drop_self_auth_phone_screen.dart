import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../models/drop_mode.dart';
import '../services/api_service.dart';
import 'drop_self_auth_otp_screen.dart';

class DropSelfAuthPhoneScreen extends StatefulWidget {
  const DropSelfAuthPhoneScreen({
    super.key,
    required this.dropMode,
    required this.recipientPhone,
    required this.helpId,
  });
final String helpId;

  final DropMode dropMode;
  final String recipientPhone;

  @override
  State<DropSelfAuthPhoneScreen> createState() =>
      _DropSelfAuthPhoneScreenState();
}

class _DropSelfAuthPhoneScreenState
    extends State<DropSelfAuthPhoneScreen> {
  static const int phoneLength = 10;
  final List<String> _digits = [];

  String get senderPhone => _digits.join();

  void _onKey(String v) {
    setState(() {
      if (v == 'Clear') {
        _digits.clear();
      } else if (v == '⌫') {
        if (_digits.isNotEmpty) _digits.removeLast();
      } else if (_digits.length < phoneLength) {
        _digits.add(v);
      }
    });
  }

  Future<void> _sendOtp() async {
    await ApiService.sendOtp(phone: senderPhone);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DropSelfAuthOtpScreen(
          senderPhone: senderPhone,
          recipientPhone: widget.recipientPhone,
          dropMode: widget.dropMode,
          helpId: widget.helpId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1','2','3',
      '4','5','6',
      '7','8','9',
      'Clear','0','⌫',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 4, child: _leftPanel()),
                  const SizedBox(width: 32),
                  Expanded(flex: 5, child: _rightPanel(keys)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('VERIFY SELF.', style: AppText.titleXL),
            SizedBox(height: 6),
            Text('ENTER YOUR PHONE NUMBER', style: AppText.muted),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('BACK'),
        ),
      ],
    );
  }

  // ================= LEFT PANEL =================

  Widget _leftPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENTER YOUR PHONE NUMBER.',
            style: AppText.titleL,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              phoneLength,
              (i) => _digitBox(i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _digitBox(int i) {
    final filled = i < _digits.length;

    return Container(
      width: 44,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? AppColors.primary : Colors.white12,
          width: 1.4,
        ),
      ),
      child: Text(
        filled ? _digits[i] : '•',
        style: AppText.titleL.copyWith(
          fontSize: 22,
          color: filled ? AppColors.primary : Colors.white38,
        ),
      ),
    );
  }

  // ================= RIGHT PANEL =================

  Widget _rightPanel(List<String> keys) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: keys.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                mainAxisExtent: 90,
              ),
              itemBuilder: (_, i) => _key(keys[i]),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 68,
            child: ElevatedButton(
              onPressed:
                  senderPhone.length == phoneLength ? _sendOtp : null,
              child: const Text(
  'SEND OTP',
  style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 30,
    letterSpacing: 1.1,
  ),
),

            ),
          ),
        ],
      ),
    );
  }

  Widget _key(String label) {
    final isNumber = label.length == 1;

    return Material(
      color: AppColors.card,
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onKey(label),
        child: Center(
          child: Text(
            label,
           style: AppText.titleL.copyWith(
  fontSize: isNumber ? 34 : 20,
  fontWeight: isNumber ? FontWeight.w900 : FontWeight.w600,
  color: label == 'Clear'
      ? Colors.white70
      : AppColors.primary,
),

          ),
        ),
      ),
    );
  }
}
