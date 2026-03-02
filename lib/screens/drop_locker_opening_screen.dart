import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import 'kiosk_home_screen.dart';

class DropLockerOpeningScreen extends StatefulWidget {
  const DropLockerOpeningScreen({super.key});

  @override
  State<DropLockerOpeningScreen> createState() =>
      _DropLockerOpeningScreenState();
}

class _DropLockerOpeningScreenState extends State<DropLockerOpeningScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // 🔁 HARD RESET TO HOME AFTER 10 SECONDS
    _timer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const KioskHomeScreen(),
        ),
        (_) => false, // 🔥 CLEAR ENTIRE STACK
      );
    });
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_open_rounded,
              size: 120,
              color: AppColors.success,
            ),
            const SizedBox(height: 32),
            Text(
              'LOCKER OPENING',
              style: AppText.titleL,
            ),
            const SizedBox(height: 12),
            Text(
              'Courier can place the parcel now',
              style: AppText.muted.copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
