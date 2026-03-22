import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'delivery_step2_dashboard_screen.dart';
import 'delivery_step1_recipient_phone_screen.dart';
import 'delivery_self_auth_phone_screen.dart';

class DeliveryStep1OtpScreen extends StatefulWidget {
  const DeliveryStep1OtpScreen({
    super.key,
    required this.recipientPhone,
  });

  final String recipientPhone;

  @override
  State<DeliveryStep1OtpScreen> createState() =>
      _DeliveryStep1OtpScreenState();
}

class _DeliveryStep1OtpScreenState extends State<DeliveryStep1OtpScreen> {
  static const int otpLength = 6;
  static const int _resendDuration = 30;

  final List<String> _otp = [];
  bool _loading = false;

  // SMS timer: 30s cooldown
  int _smsSecondsLeft = _resendDuration;
  Timer? _smsTimer;

  // WhatsApp timer: active immediately, 30s cooldown after send
  int _waSecondsLeft = 0;
  Timer? _waTimer;

  @override
  void initState() {
    super.initState();
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

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      await ApiService.verifyOtp(
        phone: widget.recipientPhone,
        otp: _otp.join(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryStep2DashboardScreen(
            recipientPhone: widget.recipientPhone,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_smsSecondsLeft > 0) return;
    try {
      await ApiService.sendOtp(phone: widget.recipientPhone);
      _startSmsTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent')),
      );
    } catch (_) {
      if (!mounted) return;
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
        const SnackBar(content: Text('Failed to send WhatsApp OTP')),
      );
    }
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

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('VERIFY RECIPIENT', style: AppText.titleXL),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const DeliveryStep1RecipientPhoneScreen(),
              ),
              (_) => false,
            );
          },
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          label: Text('BACK'),
        ),
      ],
    );
  }

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
          Text('ENTER OTP', style: AppText.titleXL),
          const SizedBox(height: 8),
          Text(
            'Sent to +91 ${widget.recipientPhone}',
            style: AppText.muted,
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(otpLength, _otpBox),
          ),

          const SizedBox(height: 24),

          // 🔁 RESEND OTP (SMS) — 30s cooldown
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _smsSecondsLeft == 0 ? _resendOtp : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary, width: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                _smsSecondsLeft > 0
                    ? 'RESEND OTP IN ${_smsSecondsLeft}s'
                    : 'RESEND OTP',
                style: AppText.titleM.copyWith(
                  color: _smsSecondsLeft == 0 ? AppColors.primary : AppColors.placeholder,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 💬 RESEND OTP WHATSAPP — active immediately, 30s after send
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
                ),
              ),
            ),
          ),

          const Spacer(),

          // 🚨 RECIPIENT UNREACHABLE
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary, width: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(vertical: 28),
            ),
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
            child: Center(
              child: Text(
                'RECIPIENT UNREACHABLE?',
                style: AppText.titleM.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              onPressed:
                  _otp.length == otpLength && !_loading ? _verify : null,
              child: _loading
                  ? const CircularProgressIndicator(color: AppColors.onPrimary)
                  : Text('VERIFY OTP'),
            ),
          ),
        ],
      ),
    );
  }

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
        ),
      ),
      child: Text(
        filled ? _otp[i] : '•',
        style: AppText.titleM.copyWith(
          color: filled ? AppColors.primary : AppColors.placeholder,
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
              style: AppText.titleM.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      );
}
