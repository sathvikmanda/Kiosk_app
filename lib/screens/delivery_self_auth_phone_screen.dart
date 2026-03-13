// delivery_self_auth_phone_screen.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'delivery_self_auth_otp_screen.dart';
import '../services/audio_service.dart';

class DeliverySelfAuthPhoneScreen extends StatefulWidget {
  const DeliverySelfAuthPhoneScreen({
    super.key,
    required this.recipientPhone,
  });

  final String recipientPhone;

  @override
  State<DeliverySelfAuthPhoneScreen> createState() =>
      _DeliverySelfAuthPhoneScreenState();
}

class _DeliverySelfAuthPhoneScreenState
    extends State<DeliverySelfAuthPhoneScreen> {
  static const int phoneLength = 10;
  final List<String> _digits = [];

  String get senderPhone => _digits.join();
void initState() {
  super.initState();

  // Delay slightly so audio doesn't clash with navigation
  Future.delayed(const Duration(milliseconds: 300), () {
    AudioService.play(AudioEvent.enterPhone);
  });
}

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
        builder: (_) => DeliverySelfAuthOtpScreen(
          senderPhone: senderPhone,
          recipientPhone: widget.recipientPhone,
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
        Text('VERIFY DELIVERY AGENT.', style: AppText.titleXL),
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
          Text('ENTER AGENT PHONE.', style: AppText.titleXL),
          const SizedBox(height: 12),
          Text(
            'SELF AUTHENTICATION',
            style: AppText.muted,
          ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: senderPhone.length == phoneLength
                    ? AppColors.primary
                    : Colors.grey.shade800,
                foregroundColor: Colors.black,
              ),
              onPressed:
                  senderPhone.length == phoneLength ? _sendOtp : null,
              child: const Text('SEND OTP'),
            ),
          ),
        ],
      ),
    );
  }

  // ================= COMPONENTS =================

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

  Widget _key(String v) {
    final isNumber = v.length == 1;

    return Material(
      color: AppColors.card,
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onKey(v),
        child: Center(
          child: Text(
            v,
            style: AppText.titleL.copyWith(
              fontSize: isNumber ? 32 : 20,
              color: v == 'Clear'
                  ? Colors.white70
                  : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
