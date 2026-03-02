import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import 'delivery_step4_success_screen.dart';

class DeliveryStep3LockerOpeningScreen extends StatefulWidget {
  const DeliveryStep3LockerOpeningScreen({
    super.key,
    required this.recipientPhone,
  });

  final String recipientPhone;

  @override
  State<DeliveryStep3LockerOpeningScreen> createState() =>
      _DeliveryStep3LockerOpeningScreenState();
}

class _DeliveryStep3LockerOpeningScreenState
    extends State<DeliveryStep3LockerOpeningScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Simulate locker opening delay
    _timer = Timer(const Duration(seconds: 4), _goToSuccess);
  }

  void _goToSuccess() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryStep4SuccessScreen(
          recipientPhone: widget.recipientPhone,
        ),
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
                'Please place the parcel inside\nand close the locker door.',
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
