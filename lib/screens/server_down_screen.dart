import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/inactivity_controller.dart';
import '../services/api_service.dart';
import '../kiosk_controller.dart';

class ServerDownScreen extends StatefulWidget {
  const ServerDownScreen({super.key});

  @override
  State<ServerDownScreen> createState() => _ServerDownScreenState();
}

class _ServerDownScreenState extends State<ServerDownScreen> {
  Timer? _retryTimer;
  int _countdown = 10;
  bool _checking = false;

  // Hidden admin - 5 taps on bottom-left corner
  int _adminTapCount = 0;
  Timer? _adminTapReset;

  static const _platform = MethodChannel('kiosk_channel');

  @override
  void initState() {
    super.initState();
    InactivityController().pauseForPayment();
    _startRetryLoop();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _adminTapReset?.cancel();
    InactivityController().resumeAfterPayment();
    super.dispose();
  }

  void _startRetryLoop() {
    _retryTimer?.cancel();
    setState(() => _countdown = 10);

    _retryTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return t.cancel();
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        await _checkServer();
      }
    });
  }

  Future<void> _checkServer() async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      await ApiService.getAllLocked().timeout(const Duration(seconds: 5));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
      _startRetryLoop();
    }
  }

  // 5 taps on hidden corner zone → PIN dialog
  void _handleAdminTap() {
    _adminTapCount++;
    _adminTapReset?.cancel();
    _adminTapReset = Timer(const Duration(seconds: 2), () {
      _adminTapCount = 0;
    });

    if (_adminTapCount >= 5) {
      _adminTapCount = 0;
      _showPinDialog();
    }
  }

  void _showPinDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Admin Access"),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Enter PIN"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text == "5259") {
                Navigator.pop(context);
                _showAdminOptions();
              }
            },
            child: const Text("Unlock"),
          ),
        ],
      ),
    );
  }

  void _showAdminOptions() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Admin Options"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.terminal),
              label: const Text("Open Termux"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                Navigator.pop(context);
                // Don't disable kiosk — Termux is whitelisted in lock task
                await _platform.invokeMethod('launchApp',
                    {'package': 'com.termux'});
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Retry Now"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.pop(context);
                _retryTimer?.cancel();
                _checkServer();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content
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
                  // Non-tappable icon
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: Colors.redAccent,
                  ),
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
                  if (_checking)
                    const CircularProgressIndicator(color: Colors.redAccent)
                  else ...[
                    CircularProgressIndicator(
                      value: _countdown / 10.0,
                      color: Colors.redAccent,
                      backgroundColor: Colors.white12,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Retrying in $_countdown seconds...',
                      style: AppText.muted,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('RETRY NOW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () {
                        _retryTimer?.cancel();
                        _checkServer();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Hidden tap zone — bottom-left corner, invisible
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
