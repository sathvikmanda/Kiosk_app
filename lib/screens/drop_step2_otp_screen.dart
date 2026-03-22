import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../models/drop_mode.dart';
import '../services/api_service.dart';
import 'drop_step3_dashboard_screen.dart';
import 'drop_self_auth_phone_screen.dart';
import '../services/audio_service.dart';

class DropStep2OtpScreen extends StatefulWidget {
  const DropStep2OtpScreen({
    super.key,
    required this.recipientPhone,
    required this.dropMode,
    required this.helpId,
  });
final String helpId;

  final String recipientPhone;
  final DropMode dropMode;

  @override
  State<DropStep2OtpScreen> createState() => _DropStep2OtpScreenState();
}

class _DropStep2OtpScreenState extends State<DropStep2OtpScreen> {
  static const int otpLength = 6;
  final List<String> _otp = [];

  static const int _resendDuration = 30;
  int _secondsLeft = _resendDuration;
  Timer? _timer;

  // WhatsApp: active immediately, counts after first send
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

  Future<void> _verifyOtp() async {
    try {
      await ApiService.verifyOtp(
        phone: widget.recipientPhone,
        otp: otp,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DropStep3DashboardScreen(
            phone: widget.recipientPhone,
            helpId: widget.helpId,
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
      await ApiService.sendOtp(phone: widget.recipientPhone);
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
      await ApiService.resendOtpWhatsapp(phone: widget.recipientPhone);
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

  // ================= LEFT PANEL =================

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
            Text('ENTER OTP.', style: AppText.titleXL),
            const SizedBox(height: 12),
            Text(
              'Sent to ${widget.recipientPhone}',
              style: AppText.muted,
            ),
            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                otpLength,
                (i) => _digit(i),
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

            const Spacer(),

            // 🚨 RECIPIENT UNREACHABLE
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DropSelfAuthPhoneScreen(
                      dropMode: widget.dropMode,
                      recipientPhone: widget.recipientPhone,
                      helpId: widget.helpId,
                      
                    ),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.card.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.6),
                    width: 2.6,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      color: AppColors.primary.withOpacity(0.9),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'RECIPIENT UNREACHABLE?',
                      style: AppText.titleM.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= RIGHT PANEL =================

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
              height: 68,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _otp.length == otpLength
                      ? AppColors.primary
                      : AppColors.card,
                ),
                onPressed: _otp.length == otpLength
                    ? _verifyOtp
                    : null,
                child: Text('VERIFY OTP', style: AppText.titleL),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI PARTS =================

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('VERIFY THE RECIPIENT.', style: AppText.titleXL),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: Text('BACK'),
        ),
      ],
    );
  }

  Widget _digit(int i) => Container(
        width: 50,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: i < _otp.length
                ? AppColors.primary
                : AppColors.subtle,
          ),
        ),
        child: Text(
          i < _otp.length ? _otp[i] : '•',
          style: AppText.titleM.copyWith(
            color: i < _otp.length
                ? AppColors.primary
                : AppColors.placeholder,
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
