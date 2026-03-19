import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'delivery_step1_otp_screen.dart';
import 'kiosk_home_screen.dart';

class DeliveryStep1RecipientPhoneScreen extends StatefulWidget {
  const DeliveryStep1RecipientPhoneScreen({super.key});

  @override
  State<DeliveryStep1RecipientPhoneScreen> createState() =>
      _DeliveryStep1RecipientPhoneScreenState();
}

class _DeliveryStep1RecipientPhoneScreenState
    extends State<DeliveryStep1RecipientPhoneScreen> {
  static const int phoneLength = 10;
  final List<String> _digits = [];

  String get phone => _digits.join();

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
    await ApiService.sendOtp(phone: phone);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryStep1OtpScreen(
          recipientPhone: phone,
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
        Text('DELIVERY DROPOFF', style: AppText.titleXL),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const KioskHomeScreen()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          label: Text('BACK'),
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
          Text('ENTER RECIPIENT PHONE', style: AppText.titleXL),
          const SizedBox(height: 28),
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
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                mainAxisExtent: 80,
              ),
              itemBuilder: (_, i) => _key(keys[i]),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 68,
            child: ElevatedButton(
              onPressed: phone.length == phoneLength ? _sendOtp : null,
              child: Text('SEND OTP'),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI PARTS =================

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
        ),
      ),
      child: Text(
        filled ? _digits[i] : '•',
        style: AppText.titleM.copyWith(
          color: filled ? AppColors.primary : Colors.white38,
        ),
      ),
    );
  }

  Widget _key(String v) => Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _onKey(v),
          child: Center(
            child: Text(
              v,
              style: AppText.titleM.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      );
}
