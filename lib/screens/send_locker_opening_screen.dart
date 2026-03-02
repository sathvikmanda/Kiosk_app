import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../utils/immersive_mode.dart';
import 'send_tracking_sent_screen.dart';

class SendLockerOpeningScreen extends StatefulWidget {
  const SendLockerOpeningScreen({super.key});

  @override
  State<SendLockerOpeningScreen> createState() =>
      _SendLockerOpeningScreenState();
}

class _SendLockerOpeningScreenState
    extends State<SendLockerOpeningScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // ✅ EXACT BEHAVIOR: immersive mode
    ImmersiveMode.enable();

    // ✅ SAME TIMING PATTERN
    _timer = Timer(const Duration(seconds: 4), _goNext);
  }

  void _goNext() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const SendTrackingSentScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: 520,
          padding: const EdgeInsets.fromLTRB(40, 48, 40, 48),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_open,
                size: 96,
                color: AppColors.primary,
              ),
              const SizedBox(height: 28),

              const Text(
                'OPENING LOCKER',
                style: AppText.titleL,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 14),

              const Text(
                'Please place your parcel\nand close the locker door.',
                textAlign: TextAlign.center,
                style: AppText.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
