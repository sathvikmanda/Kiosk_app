import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';

import 'send_step2_otp_screen.dart';
import '../services/audio_service.dart';

class SendStep1PhoneScreen extends StatefulWidget {
  const SendStep1PhoneScreen({
    super.key,
    required this.lockerSize,

    // 🔥 DELIVERY DATA FROM ESTIMATE SCREEN
    required this.fromLocation,
    required this.toPincode,
    required this.courierName,
    required this.estimatedDays,
    required this.deliveryCost,
    required this.lockerCost,
  });
final String lockerSize;
  final String fromLocation;
  final String toPincode;
  final String courierName;
  final String estimatedDays;
  final int deliveryCost;
  final int lockerCost;

  @override
  State<SendStep1PhoneScreen> createState() => _SendStep1PhoneScreenState();
}

class _SendStep1PhoneScreenState extends State<SendStep1PhoneScreen> {
  static const int phoneLength = 10;
  final List<String> _phone = [];

  bool _loading = false;
  void initState() {
  super.initState();

  // Delay slightly so audio doesn't clash with navigation
  Future.delayed(const Duration(milliseconds: 300), () {
    AudioService.play(AudioEvent.enterPhone);
  });
}

  void _onKeyPress(String value) {
    if (_loading) return;

    setState(() {
      if (value == 'Clear') {
        _phone.clear();
      } else if (value == '⌫') {
        if (_phone.isNotEmpty) _phone.removeLast();
      } else if (_phone.length < phoneLength) {
        _phone.add(value);
      }
    });
  }

  String get phoneNumber => _phone.join();

  // ================= API =================

Future<void> _sendOtp() async {
  setState(() => _loading = true);

  try {
    await ApiService.sendOtp(phone: phoneNumber);

    if (!mounted) return;

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => SendStep2OtpScreen(
      phoneNumber: phoneNumber,
      fromLocation: widget.fromLocation,
      toPincode: widget.toPincode,
      courierName: widget.courierName,
      estimatedDays: widget.estimatedDays,
      deliveryCost: widget.deliveryCost,
      lockerCost: widget.lockerCost,
      lockerSize: widget.lockerSize,
    ),
  ),
);


  } catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to send OTP')),
    );
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}


  // ================= BUILD =================

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
          children: [
            _header(),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 5, child: _leftSummaryPanel()),
                  const SizedBox(width: 32),
                  Expanded(flex: 4, child: _rightInputPanel(keys)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('SEND PARCEL.', style: AppText.titleXL),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context), // ✅ FIXED
          icon: const Icon(Icons.arrow_back),
          label: const Text('BACK'),
        ),
      ],
    );
  }

  // ================= LEFT SUMMARY =================

  Widget _leftSummaryPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DELIVERY DETAILS.', style: AppText.titleL),
          const SizedBox(height: 24),

          _row('From', widget.fromLocation),
          _row('To', widget.toPincode),
          _row('Service', widget.courierName),
          _row('ETA', widget.estimatedDays),

          const Divider(height: 36),

          _row('Delivery', '₹${widget.deliveryCost}'),
          _row('Locker', '₹${widget.lockerCost}'),

          const Divider(height: 36),

          _row(
            'TOTAL',
            '₹${widget.deliveryCost + widget.lockerCost}',
            highlight: true,
          ),

          const Spacer(),

          Text(
            'Enter your phone number to receive destination address form.',
            style: AppText.muted,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.muted),
          Text(
            value,
            style: highlight
                ? AppText.titleL.copyWith(color: AppColors.primary)
                : AppText.body,
          ),
        ],
      ),
    );
  }

  // ================= RIGHT INPUT =================

  Widget _rightInputPanel(List<String> keys) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text('ENTER YOUR PHONE NUMBER', style: AppText.titleL),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              phoneLength,
              (i) => _digitBox(
                filled: i < _phone.length,
                value: i < _phone.length ? _phone[i] : '',
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: keys.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                mainAxisExtent: 62,
              ),
              itemBuilder: (_, i) => _key(keys[i]),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 68,
            child: ElevatedButton(
              onPressed:
                  (_phone.length == phoneLength && !_loading)
                      ? _sendOtp
                      : null,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('RECEIVE OTP'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _digitBox({required bool filled, required String value}) {
    return Container(
      width: 44,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? AppColors.primary : AppColors.border,
          width: 1.4,
        ),
      ),
      child: Text(
        filled ? value : '•',
        style: filled ? AppText.titleM : AppText.muted,
      ),
    );
  }

  Widget _key(String label) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _onKeyPress(label),
        child: Center(
  child: Text(
    label,
    style: AppText.titleM.copyWith(
      color: RegExp(r'^[0-9]$').hasMatch(label)
          ? AppColors.primary   // 🔥 ORANGE NUMBERS
          : AppText.titleM.color, // Clear / ⌫ unchanged
    ),
  ),
),

      ),
    );
  }
}
