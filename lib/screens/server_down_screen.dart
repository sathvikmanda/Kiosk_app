import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/inactivity_controller.dart';
import '../services/locker_state_service.dart';
import '../hidden_admin_unlock.dart';

class ServerDownScreen extends StatefulWidget {
  const ServerDownScreen({super.key});

  @override
  State<ServerDownScreen> createState() => _ServerDownScreenState();
}

class _ServerDownScreenState extends State<ServerDownScreen> {
  int _adminTapCount = 0;
  Timer? _adminTapReset;
  StreamSubscription? _serverSubscription;

  @override
  void initState() {
    super.initState();
    // Pause inactivity while server is down
    InactivityController().pauseForPayment();

    // Auto-dismiss when server comes back
    _serverSubscription = LockerStateService().serverStream.listen((reachable) {
      if (reachable && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _serverSubscription?.cancel();
    _adminTapReset?.cancel();
    InactivityController().resumeAfterPayment();
    super.dispose();
  }

  void _handleAdminTap() {
    _adminTapCount++;
    _adminTapReset?.cancel();
    _adminTapReset = Timer(const Duration(seconds: 2), () {
      _adminTapCount = 0;
    });

    if (_adminTapCount >= 5) {
      _adminTapCount = 0;
      showDialog(
        context: context,
        builder: (_) => const AdminPinDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 80, color: Colors.redAccent),
                  const SizedBox(height: 28),
                  Text(
                    'SERVER UNAVAILABLE',
                    style: AppText.titleL.copyWith(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to reach the DropPoint server.\nPlease wait while we reconnect.',
                    style: AppText.muted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Retrying automatically...',
                    style: AppText.muted,
                  ),
                ],
              ),
            ),
          ),

          // Hidden tap zone — bottom-left corner
          Positioned(
            bottom: 0,
            left: 0,
            width: 100,
            height: 100,
            child: GestureDetector(
              onTap: _handleAdminTap,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
