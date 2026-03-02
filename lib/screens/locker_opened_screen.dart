import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';

class LockerOpenedScreen extends StatefulWidget {
  const LockerOpenedScreen({
    super.key,
    required this.accessCode,
  });

  final String accessCode;

  @override
  State<LockerOpenedScreen> createState() => _LockerOpenedScreenState();
}

class _LockerOpenedScreenState extends State<LockerOpenedScreen> {
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 6), _goHome);
  }

  void _goHome() {
    if (_done || !mounted) return;
    _done = true;

    // ✅ DO NOT RESET NAV STACK
    // ✅ CAMERA STAYS ALIVE
    Navigator.of(context).pop();
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
      onTap: _goHome,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_open,
                color: AppColors.primary,
                size: 96,
              ),
              const SizedBox(height: 24),
              Text(
                'LOCKER OPENED',
                style: AppText.titleXL.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PLEASE COLLECT/DROP YOUR LUGGAGE',
                style: AppText.muted.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 24),
              Text(
                'TAP ANYWHERE TO RETURN HOME',
                style: AppText.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
