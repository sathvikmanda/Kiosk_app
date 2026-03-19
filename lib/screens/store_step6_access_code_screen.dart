import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';

import 'kiosk_home_screen.dart';

class StoreStep6AccessCodeScreen extends StatefulWidget {
  const StoreStep6AccessCodeScreen({
    super.key,
    required this.phoneNumber,
    required this.accessCode,
     required this.helpId,
  });
final String helpId;

  final String phoneNumber;
  final String accessCode;

  @override
  State<StoreStep6AccessCodeScreen> createState() =>
      _StoreStep6AccessCodeScreenState();
}

class _StoreStep6AccessCodeScreenState
    extends State<StoreStep6AccessCodeScreen> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _resolveAndStart();
  }

  Future<void> _resolveAndStart() async {
    await ApiService.stopComplaint(widget.helpId);
    _timer = Timer(const Duration(seconds: 10), _goHome);
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;

    // ✅ DO NOT NUKE THE NAV STACK
    // ✅ Let Home reattach camera cleanly
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const KioskHomeScreen(),

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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _goHome,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Container(
            width: 560,
            padding: const EdgeInsets.fromLTRB(48, 56, 48, 56),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------- TITLE ----------
                Text(
                  'YOUR ACCESS CODE',
                  style: AppText.muted,
                ),

                const SizedBox(height: 20),

                // ---------- ACCESS CODE ----------
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    widget.accessCode,
                    style: AppText.code,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'USE THIS CODE TO OPEN YOUR LOCKER',
                  style: AppText.muted,
                ),

                const SizedBox(height: 36),

                // ---------- PHONE CONFIRMATION ----------
                Text(
                  'DETAILS SENT TO',
                  style: AppText.caption,
                ),
                const SizedBox(height: 8),
                Text(
                  '+91 ${widget.phoneNumber}',
                  style: AppText.titleM,
                ),

                const SizedBox(height: 40),

                Text(
                  'Tap anywhere to return home',
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
