import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../utils/immersive_mode.dart';

import '../services/api_service.dart';
import 'store_step6_access_code_screen.dart';
import '../services/audio_service.dart';

class StoreStep5LockerOpeningScreen extends StatefulWidget {
  const StoreStep5LockerOpeningScreen({
    super.key,
    required this.phoneNumber,
    required this.accessCode,
     required this.helpId,
     this.compartmentId,
  });
final String helpId;

  final String phoneNumber;
  final String accessCode;
  final int? compartmentId;

  @override
  State<StoreStep5LockerOpeningScreen> createState() =>
      _StoreStep5LockerOpeningScreenState();
}

class _StoreStep5LockerOpeningScreenState
    extends State<StoreStep5LockerOpeningScreen> {
  Timer? _timer;
  bool _navigatedForward = false;

  @override
  void initState() {
    super.initState();
    ImmersiveMode.enable();
      Future.delayed(const Duration(milliseconds: 300), () {
    if (widget.compartmentId != null) {
      // Maps compartmentId 1→-1.0 (full left), 5→+1.0 (full right)
      final double balance = ((widget.compartmentId! ) / 4.0) * 2.0 - 1.0;
      AudioService.playWithBalance(AudioEvent.lockerDirection, balance);
    }
  });
    _timer = Timer(const Duration(seconds: 4), _goToAccessCode);
  }

  

  void _goToAccessCode() {
    if (!mounted) return;

    _navigatedForward = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StoreStep6AccessCodeScreen(
          phoneNumber: widget.phoneNumber,
          accessCode: widget.accessCode,
          helpId: widget.helpId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    // 🔴 SAFETY NET:
    // If this screen is disposed WITHOUT successful navigation,
    // resolve the complaint to avoid orphan recordings.
    if (!_navigatedForward) {
      ApiService.resolveComplaintIfAny();
    }

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
                'Please place your luggage\nand close the locker door.',
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
