import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/inactivity_controller.dart';
import '../services/api_service.dart';
import 'kiosk_home_screen.dart';

class SendTrackingSentScreen extends StatefulWidget {
  const SendTrackingSentScreen({super.key});

  @override
  State<SendTrackingSentScreen> createState() =>
      _SendTrackingSentScreenState();
}

class _SendTrackingSentScreenState extends State<SendTrackingSentScreen> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _resolveAndStart();
  }

  Future<void> _resolveAndStart() async {
    final helpId = InactivityController().activeHelpId;
    if (helpId != null) {
      await ApiService.stopComplaint(helpId);
      InactivityController().activeHelpId = null;
    }
    _timer = Timer(const Duration(seconds: 6), _goHome);
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
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
                Icon(
                  Icons.check_circle,
                  size: 96,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 28),
                const Text(
                  'TRACKING DETAILS SENT',
                  style: AppText.titleL,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tracking information has been\nsent to your phone.',
                  textAlign: TextAlign.center,
                  style: AppText.muted,
                ),
                const SizedBox(height: 36),
                const Text(
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
