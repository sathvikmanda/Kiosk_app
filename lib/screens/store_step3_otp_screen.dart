import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'store_step4_payment_screen.dart';
import '../services/audio_service.dart';

class StoreStep3OtpScreen extends StatefulWidget {
  const StoreStep3OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.size,
    required this.hours,
    required this.ratePerHour,


    required this.helpId,
  });
final String helpId;


  final String phoneNumber;
  final String size;
  final int hours;
  final int ratePerHour;


  @override
  State<StoreStep3OtpScreen> createState() => _StoreStep3OtpScreenState();
}

class _StoreStep3OtpScreenState extends State<StoreStep3OtpScreen> {
  static const int otpLength = 6;
  final List<String> _otp = [];

  bool isLoading = false;

  // ===== SMS RESEND TIMER (starts at 30, counts down) =====
  static const int _resendDuration = 30;
  int _smsSecondsLeft = _resendDuration;
  Timer? _smsTimer;

  // ===== WHATSAPP RESEND TIMER (starts at 0 = active, only counts after first send) =====
  int _waSecondsLeft = 0;
  Timer? _waTimer;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      AudioService.play(AudioEvent.enterotp);
    });
    _startSmsTimer();
  }

  @override
  void dispose() {
    _smsTimer?.cancel();
    _waTimer?.cancel();
    super.dispose();
  }

  void _startSmsTimer() {
    _smsTimer?.cancel();
    setState(() => _smsSecondsLeft = _resendDuration);
    _smsTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_smsSecondsLeft <= 1) {
        t.cancel();
        setState(() => _smsSecondsLeft = 0);
      } else {
        setState(() => _smsSecondsLeft--);
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

  void _onKeyPress(String value) {
    setState(() {
      if (value == 'Clear') {
        _otp.clear();
      } else if (value == '⌫') {
        if (_otp.isNotEmpty) _otp.removeLast();
      } else if (_otp.length < otpLength) {
        _otp.add(value);
      }
    });
  }

  String get otp => _otp.join();

  // ================= RESEND OTP (WHATSAPP) =================

  Future<void> _resendOtpWhatsapp() async {
    if (_waSecondsLeft > 0) return;
    try {
      await ApiService.resendOtpWhatsapp(phone: widget.phoneNumber);
      _startWaTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent on WhatsApp')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to resend OTP on WhatsApp')),
      );
    }
  }

  Future<void> _sendOtp() async {
    if (_smsSecondsLeft > 0) return;
    try {
      await ApiService.sendOtp(phone: widget.phoneNumber);
      _startSmsTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent on SMS')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to resend OTP on SMS')),
      );
    }
  }

  // ================= VERIFY =================

  Future<void> _verifyAndContinue() async {
    setState(() => isLoading = true);

    try {
      await ApiService.verifyOtp(
        phone: widget.phoneNumber,
        otp: otp,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StoreStep4PaymentScreen(
            phoneNumber: widget.phoneNumber,
            size: widget.size,
            hours: widget.hours,
            ratePerHour: widget.ratePerHour,


            helpId: widget.helpId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
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
                  Expanded(flex: 4, child: _otpPanel()),
                  const SizedBox(width: 32),
                  Expanded(flex: 5, child: _rightPanel(context)),
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
          children: [
            Text('STORING LUGGAGE.', style: AppText.titleXL),
            SizedBox(height: 6),
            Text('STEP 3 OF 4: VERIFY OTP', style: AppText.muted),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: Text('BACK'),
        ),
      ],
    );
  }

  // ================= LEFT PANEL =================

  Widget _otpPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ENTER OTP.', style: AppText.titleL),
          const SizedBox(height: 12),
          Text(
            'OTP SENT TO ${widget.phoneNumber}',
            style: AppText.muted,
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(otpLength, _otpBox),
          ),

          const SizedBox(height: 24),

          Center(
            child: GestureDetector(
              onTap: _smsSecondsLeft == 0 ? _sendOtp : null,
              child: Text(
                _smsSecondsLeft > 0
                    ? 'RESEND OTP IN ${_smsSecondsLeft}s'
                    : 'RESEND OTP',
                style: AppText.muted.copyWith(
                  color: _smsSecondsLeft == 0
                      ? AppColors.primary
                      : AppColors.placeholder,
                  decoration:
                      _smsSecondsLeft == 0 ? TextDecoration.underline : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🔥 WHATSAPP RESEND BUTTON — active immediately, disabled 30s after send
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _waSecondsLeft == 0 ? _resendOtpWhatsapp : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _waSecondsLeft == 0
                      ? AppColors.primary
                      : AppColors.subtle,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _waSecondsLeft > 0
                    ? 'WHATSAPP OTP IN ${_waSecondsLeft}s'
                    : 'RESEND OTP ON WHATSAPP',
                style: AppText.body.copyWith(
                  color: _waSecondsLeft == 0
                      ? AppColors.primary
                      : AppColors.placeholder,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBox(int index) {
    final filled = index < _otp.length;

    return Container(
      width: 50,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: filled ? AppColors.primary : AppColors.subtle,
          width: 1.6,
        ),
      ),
      child: Text(
        filled ? _otp[index] : '•',
        style: AppText.titleL.copyWith(
          fontSize: 26,
          color: filled ? AppColors.primary : AppColors.placeholder,
        ),
      ),
    );
  }

  // ================= RIGHT PANEL =================

  Widget _rightPanel(BuildContext context) {
    final keys = [
      '1','2','3',
      '4','5','6',
      '7','8','9',
      'Clear','0','⌫',
    ];

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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 72,
              ),
              itemBuilder: (_, i) => _key(keys[i]),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 68,
            child: ElevatedButton(
              onPressed: _otp.length == otpLength && !isLoading
                  ? _verifyAndContinue
                  : null,
              child: isLoading
                  ? const CircularProgressIndicator(color: AppColors.onPrimary)
                  : Text('VERIFY OTP'),
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
        onTap: () => _onKeyPress(label),
        child: Center(
          child: Text(
            label,
            style: AppText.titleL.copyWith(
              fontSize: isNumber ? 32 : 20,
              color: label == 'Clear'
                  ? AppColors.inactive
                  : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
