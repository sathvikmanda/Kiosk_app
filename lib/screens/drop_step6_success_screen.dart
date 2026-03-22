import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';

// Mask middle digits: 123456 → 12xxx56
String _maskCode(String code) {
  if (code.length < 6) return code;
  final start = code.substring(0, code.length - 5);
  final end = code.substring(code.length - 2);
  return '${start}xxx$end';
}

class DropStep6SuccessScreen extends StatefulWidget {
  const DropStep6SuccessScreen({
    super.key,
    required this.phoneNumber,
    required this.accessCode,
    required this.helpId,
  });
final String helpId;

  final String phoneNumber;
  final String accessCode;

  @override
  State<DropStep6SuccessScreen> createState() =>
      _DropStep6SuccessScreenState();
}

class _DropStep6SuccessScreenState extends State<DropStep6SuccessScreen> {
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 10), _goHome);
  }

  void _goHome() {
    if (_done || !mounted) return;
    _done = true;

    // ✅ CAMERA-SAFE NAVIGATION
    Navigator.popUntil(context, (route) => route.isFirst);
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DROP SUCCESSFUL',
                style: AppText.titleL,
              ),
              const SizedBox(height: 20),

              Text('ACCESS CODE', style: AppText.muted),
              const SizedBox(height: 10),

              Text(
                _maskCode(widget.accessCode),
                style: AppText.code.copyWith(
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Sent to receiver +91 ${widget.phoneNumber}',
                style: AppText.muted,
              ),

              const SizedBox(height: 12),

              Text(
                'Tap anywhere to return home',
                style: AppText.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
