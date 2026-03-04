import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../models/drop_mode.dart';
import '../services/api_service.dart';
import 'drop_step2_otp_screen.dart';
import '../services/audio_service.dart';

class DropStep1PhoneScreen extends StatefulWidget {
  const DropStep1PhoneScreen({
    super.key,
    required this.dropMode,
    required this.helpId,
  });
  final String helpId;


  final DropMode dropMode;

  @override
  State<DropStep1PhoneScreen> createState() => _DropStep1PhoneScreenState();
}

class _DropStep1PhoneScreenState extends State<DropStep1PhoneScreen> {
  
  static const int phoneLength = 10;
  final List<String> _phone = [];

  @override
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
        _phone.clear();
      } else if (v == '⌫') {
        if (_phone.isNotEmpty) _phone.removeLast();
      } else if (_phone.length < phoneLength) {
        _phone.add(v);
      }
    });
  }

  String get phoneNumber => _phone.join();

  @override
  Widget build(BuildContext context) {
    final keys = ['1','2','3','4','5','6','7','8','9','Clear','0','⌫'];

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
                  _leftPanel(),
                  const SizedBox(width: 32),
                  _rightPanel(keys),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LEFT =================

  Widget _leftPanel() {
    return Expanded(
      flex: 4,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.dropMode == DropMode.delivery
                  ? 'DELIVERY RECIPIENT PHONE'
                  : 'ENTER RECIPIENT PHONE',
              style: AppText.titleXL,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                phoneLength,
                (i) => _digit(i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= RIGHT =================

  Widget _rightPanel(List<String> keys) {
    return Expanded(
      flex: 5,
      child: Container(
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
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  mainAxisExtent: 90,
                ),
                itemBuilder: (_, i) => _key(keys[i]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _phone.length == phoneLength
                      ? AppColors.primary
                      : Colors.grey.shade800,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _phone.length == phoneLength
                    ? _sendOtp
                    : null,
                child: Text('CONTINUE', style: AppText.titleL),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ACTION =================

  Future<void> _sendOtp() async {
    try {
      await ApiService.sendOtp(phone: phoneNumber);

      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => DropStep2OtpScreen(
      recipientPhone: phoneNumber,
      dropMode: widget.dropMode,
      helpId: widget.helpId,
    ),
  ),
);

    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send OTP')),
      );
    }
  }

  // ================= UI PARTS =================

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('DROP PARCEL.', style: AppText.titleXL),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          label: const Text('BACK'),
        ),
      ],
    );
  }

  Widget _digit(int i) => Container(
        width: 44,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: i < _phone.length
                ? AppColors.primary
                : Colors.white12,
          ),
        ),
        child: Text(
          i < _phone.length ? _phone[i] : '•',
          style: AppText.titleM.copyWith(
            color: i < _phone.length
                ? AppColors.primary
                : Colors.white38,
          ),
        ),
      );

  Widget _key(String v) => Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _onKey(v),
          child: Center(
            child: Text(
  v,
  style: AppText.titleM.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.w900,
    fontSize: 32,
  ),
),

          ),
        ),
      );
}
