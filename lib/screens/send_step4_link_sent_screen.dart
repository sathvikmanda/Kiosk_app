import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'kiosk_home_screen.dart';

class SendStep4LinkSentScreen extends StatefulWidget {
  const SendStep4LinkSentScreen({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  State<SendStep4LinkSentScreen> createState() =>
      _SendStep4LinkSentScreenState();
}

class _SendStep4LinkSentScreenState extends State<SendStep4LinkSentScreen> {
  static const int autoHomeSeconds = 20;
  static const int tapEnableAfter = 6;

  Timer? _timer;
  int _secondsLeft = autoHomeSeconds;
  bool _tapEnabled = false;

  @override
  void initState() {
    super.initState();

    // 📤 Fire-and-forget WhatsApp link send
    _sendWhatsappLink();

    // ⏱️ Countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();

      setState(() {
        _secondsLeft--;

        if (_secondsLeft <= autoHomeSeconds - tapEnableAfter) {
          _tapEnabled = true;
        }
      });

      if (_secondsLeft <= 0) {
        t.cancel();
        _goHome();
      }
    });
  }

  Future<void> _sendWhatsappLink() async {
    try {
      await ApiService.sendParcelLinkWhatsapp(
        phoneNumber: widget.phoneNumber,
      );
    } catch (e) {
      debugPrint('WhatsApp link send failed: $e');
    }
  }

  void _goHome() {
    _timer?.cancel();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const KioskHomeScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tapEnabled ? _goHome : null,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Container(
            width: 720,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                  size: 96,
                ),
                const SizedBox(height: 28),

                Text(
                  'LINK SENT',
                  style: AppText.titleXL,
                ),
                const SizedBox(height: 18),

                Text(
                  'A secure delivery address form link has been sent to the mobile number below.',
                  textAlign: TextAlign.center,
                  style: AppText.muted,
                ),
                const SizedBox(height: 16),

                Text(
                  '+91 ${widget.phoneNumber}',
                  style: AppText.titleL.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'Open the link,\n'
                  'Enter the delivery address, and complete the next steps.',
                  textAlign: TextAlign.center,
                  style: AppText.body,
                ),

                const SizedBox(height: 36),

                // ⏱️ VISIBLE COUNTDOWN
                Text(
                  'Returning to home in $_secondsLeft seconds',
                  style: AppText.caption.copyWith(
                    color: _tapEnabled
                        ? AppColors.primary
                        : AppColors.placeholder,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _tapEnabled
                      ? 'Tap anywhere to return now'
                      : 'Please wait…',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
