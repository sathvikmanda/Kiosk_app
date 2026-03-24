import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/inactivity_controller.dart';

class LockerOpenGuardOverlay extends StatefulWidget {
  const LockerOpenGuardOverlay({super.key});

  @override
  State<LockerOpenGuardOverlay> createState() => _LockerOpenGuardOverlayState();
}

class _LockerOpenGuardOverlayState extends State<LockerOpenGuardOverlay> {
  @override
  void initState() {
    super.initState();
    InactivityController().pauseForPayment();
  }

  @override
  void dispose() {
    InactivityController().resumeAfterPayment();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.88),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_open_rounded,
                size: 88,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'LOCKER OPEN',
                style: AppText.titleXL.copyWith(
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please close the locker to continue',
                style: AppText.muted.copyWith(
                  color: Colors.white70,
                  fontSize: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
