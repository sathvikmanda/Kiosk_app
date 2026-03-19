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
  final List<String> _otp = [];

  bool _loading = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= RESEND =================

  Future<void> _resendOtp() async {
    try {
      await ApiService.sendOtp(phone: widget.recipientPhone);
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
    try {
      await ApiService.resendOtpWhatsapp(
        phone: widget.recipientPhone,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent on WhatsApp')),
      );
    } catch (_) {
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

  // ================= HEADER =================

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

          // 🔁 RESEND OTP (SMS)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _resendOtp,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary, width: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'RESEND OTP',
                style: AppText.titleM.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 💬 RESEND OTP WHATSAPP
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _resendOtpWhatsapp,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary, width: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'RESEND OTP ON WHATSAPP',
                style: AppText.titleM.copyWith(
                  color: AppColors.primary,
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
              onPressed:
                  _otp.length == otpLength && !_loading ? _verify : null,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('VERIFY OTP'),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI PARTS =================

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
          color: filled ? AppColors.primary : Colors.white12,
        ),
      ),
      child: Text(
        filled ? _otp[i] : '•',
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
              style: AppText.titleM.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      );
}