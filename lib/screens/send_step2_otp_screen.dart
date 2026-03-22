import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'send_address_dashboard_screen.dart';
import '../services/audio_service.dart';

class SendStep2OtpScreen extends StatefulWidget {
  const SendStep2OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.fromLocation,
    required this.toPincode,
    required this.courierName,
    required this.estimatedDays,
    required this.deliveryCost,
    required this.lockerCost,
    required this.lockerSize,
  });

  final String phoneNumber;
  final String fromLocation;
  final String toPincode;
  final String courierName;
  final String estimatedDays;
  final int deliveryCost;
  final int lockerCost;
  final String lockerSize;

  @override
  State<SendStep2OtpScreen> createState() => _SendStep2OtpScreenState();
}

class _SendStep2OtpScreenState extends State<SendStep2OtpScreen> {
  static const int otpLength = 6;
  static const int resendDuration = 30;

  final List<String> _otp = [];
  bool _loading = false;
  int _secondsLeft = resendDuration;
  Timer? _timer;

  // WhatsApp timer: active immediately, 30s cooldown after send
  int _waSecondsLeft = 0;
  Timer? _waTimer;

  @override
  void initState() {
    super.initState();
      Future.delayed(const Duration(milliseconds: 300), () {
    AudioService.play(AudioEvent.enterotp);
  });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = resendDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _startWaTimer() {
    _waTimer?.cancel();
    setState(() => _waSecondsLeft = resendDuration);
    _waTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_waSecondsLeft <= 1) {
        t.cancel();
        setState(() => _waSecondsLeft = 0);
      } else {
        setState(() => _waSecondsLeft--);
      }
    });
  }

  void _onKeyPress(String v) {
    if (_loading) return;

    setState(() {
      if (v == 'Clear') {
        _otp.clear();
      } else if (v == '⌫') {
        if (_otp.isNotEmpty) _otp.removeLast();
      } else if (_otp.length < otpLength) {
        _otp.add(v);
      }
    });
  }

  String get otp => _otp.join();

  // ================= VERIFY OTP =================

  Future<void> _verifyOtp() async {
    setState(() => _loading = true);

    try {
      await ApiService.verifyOtp(
        phone: widget.phoneNumber,
        otp: otp,
      );

      await ApiService.fetchSavedReceivers(
        senderPhone: widget.phoneNumber,
      );

      if (!mounted) return;

     Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => SendAddressDashboardScreen(
      phoneNumber: widget.phoneNumber,
      fromLocation: widget.fromLocation,
      lockerCost: widget.lockerCost,
      lockerSize: widget.lockerSize,
    ),
  ),
);

    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= RESEND =================

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;

    try {
      await ApiService.sendOtp(phone: widget.phoneNumber);
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to resend OTP')),
      );
    }
  }

  Future<void> _resendOtpWhatsapp() async {
    if (_waSecondsLeft > 0) return;
    try {
      await ApiService.resendOtpWhatsapp(phone: widget.phoneNumber);
      _startWaTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent on WhatsApp')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to resend OTP on WhatsApp')),
      );
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
            _header(context),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 5, child: _leftSummaryPanel()),
                  const SizedBox(width: 32),
                  Expanded(flex: 4, child: _rightOtpPanel(keys)),
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
        Text('VERIFY SENDER.', style: AppText.titleXL),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: Text('BACK'),
        ),
      ],
    );
  }

  // ================= LEFT PANEL =================

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

          Text('Didn’t receive OTP?', style: AppText.muted),
          const SizedBox(height: 12),

          // 🔥 SIDE-BY-SIDE RESEND
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _resendOtp,
                child: Text(
                  _secondsLeft == 0
                      ? 'RESEND OTP'
                      : 'RESEND OTP IN ${_secondsLeft}s',
                  style: AppText.muted.copyWith(
                    color: _secondsLeft == 0
                        ? AppColors.primary
                        : AppColors.placeholder,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _waSecondsLeft == 0 ? _resendOtpWhatsapp : null,
                child: Text(
                  _waSecondsLeft > 0
                      ? 'WHATSAPP OTP IN ${_waSecondsLeft}s'
                      : 'RESEND ON WHATSAPP',
                  style: AppText.muted.copyWith(
                    color: _waSecondsLeft == 0 ? AppColors.primary : AppColors.placeholder,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  // ================= RIGHT OTP PANEL =================

  Widget _rightOtpPanel(List<String> keys) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ENTER OTP', style: AppText.titleL),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(otpLength, _otpBox),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: keys.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
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
                  (_otp.length == otpLength && !_loading)
                      ? _verifyOtp
                      : null,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text('VERIFY OTP'),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SMALL UI =================

  Widget _otpBox(int i) {
    final filled = i < _otp.length;
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
        filled ? _otp[i] : '•',
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
        child: Center(child: Text(label, style: AppText.titleM)),
      ),
    );
  }
}
