// delivery_self_auth_otp_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'delivery_step2_dashboard_screen_auth.dart';
import 'delivery_self_auth_phone_screen.dart';
import '../services/audio_service.dart';

class DeliverySelfAuthOtpScreen extends StatefulWidget {
  const DeliverySelfAuthOtpScreen({
    super.key,
    required this.senderPhone,
    required this.recipientPhone,
  });

  final String senderPhone;
  final String recipientPhone;

  @override
  State<DeliverySelfAuthOtpScreen> createState() =>
      _DeliverySelfAuthOtpScreenState();
}

class _DeliverySelfAuthOtpScreenState
    extends State<DeliverySelfAuthOtpScreen> {
  static const int otpLength = 6;
  final List<String> _otp = [];

  // ===== RESEND TIMER =====
  static const int _resendDuration = 30;
  int _secondsLeft = _resendDuration;
  Timer? _timer;

  // WhatsApp timer: starts at 0 (active immediately), counts after first send
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
    setState(() => _secondsLeft = _resendDuration);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _startWaTimer() {
    _waTimer?.cancel();
    setState(() => _waSecondsLeft = _resendDuration);
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

  void _onKey(String v) {
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

  // ================= VERIFY =================

  Future<void> _verify() async {
    try {
      await ApiService.verifyOtp(
        phone: widget.senderPhone,
        otp: otp,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryStep2DashboardScreenAuth(
            recipientPhone: widget.recipientPhone,
            senderPhone: widget.senderPhone,
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    }
  }

  // ================= RESEND =================

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;

    try {
      await ApiService.sendOtp(phone: widget.senderPhone);
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
      await ApiService.resendOtpWhatsapp(phone: widget.senderPhone);
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
        Text('VERIFY OTP.', style: AppText.titleXL),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DeliverySelfAuthPhoneScreen(
                  recipientPhone: widget.recipientPhone,
                ),
              ),
            );
          },
          icon: const Icon(Icons.arrow_back),
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
          Text('ENTER OTP.', style: AppText.titleXL),
          const SizedBox(height: 12),
          Text(
            'Sent to +91 ${widget.senderPhone}',
            style: AppText.muted,
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              otpLength,
              (i) => _otpBox(i),
            ),
          ),

          const SizedBox(height: 24),

          // ⏱ TIMER / RESEND
          GestureDetector(
            onTap: _resendOtp,
            child: Text(
              _secondsLeft > 0
                  ? 'RESEND OTP IN ${_secondsLeft}s'
                  : 'RESEND OTP',
              style: AppText.muted.copyWith(
                color: _secondsLeft == 0
                    ? AppColors.primary
                    : AppText.muted.color,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 💬 WHATSAPP RESEND
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _waSecondsLeft == 0 ? _resendOtpWhatsapp : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary, width: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                _waSecondsLeft > 0
                    ? 'WHATSAPP OTP IN ${_waSecondsLeft}s'
                    : 'RESEND OTP ON WHATSAPP',
                style: AppText.titleM.copyWith(
                  color: _waSecondsLeft == 0 ? AppColors.primary : AppColors.placeholder,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                backgroundColor: _otp.length == otpLength
                    ? AppColors.primary
                    : AppColors.card,
                foregroundColor: Colors.black,
              ),
              onPressed: _otp.length == otpLength ? _verify : null,
              child: Text('VERIFY OTP'),
            ),
          ),
        ],
      ),
    );
  }

  // ================= COMPONENTS =================

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
          color: filled ? AppColors.primary : AppColors.subtle,
          width: 1.4,
        ),
      ),
      child: Text(
        filled ? _otp[i] : '•',
        style: AppText.titleL.copyWith(
          fontSize: 22,
          color: filled ? AppColors.primary : AppColors.placeholder,
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
                  ? AppColors.inactive
                  : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
