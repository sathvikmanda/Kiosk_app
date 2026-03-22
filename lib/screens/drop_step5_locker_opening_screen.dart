// DropStep5LockerOpeningScreen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import 'drop_step6_success_screen.dart';

class DropStep5LockerOpeningScreen extends StatefulWidget {
  const DropStep5LockerOpeningScreen({
    super.key,
    required this.phoneNumber,
    required this.accessCode,
    required this.helpId,
    this.recipientPhone,
  });
  final String helpId;

  final String phoneNumber;
  final String accessCode;
  final String? recipientPhone;

  @override
  State<DropStep5LockerOpeningScreen> createState() =>
      _DropStep5LockerOpeningScreenState();
}

class _DropStep5LockerOpeningScreenState
    extends State<DropStep5LockerOpeningScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DropStep6SuccessScreen(
            phoneNumber: widget.recipientPhone ?? widget.phoneNumber,
            accessCode: widget.accessCode,
            helpId: widget.helpId,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔒 ORANGE LOCK ICON
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.lock_open_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'OPENING LOCKER',
              style: AppText.titleXL,
            ),

            const SizedBox(height: 10),

            Text(
              'Please wait…',
              style: AppText.muted,
            ),
          ],
        ),
      ),
    );
  }
}
