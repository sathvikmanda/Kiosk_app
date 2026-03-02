import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';

class DeliveryStep4SuccessScreen extends StatefulWidget {
  const DeliveryStep4SuccessScreen({
    super.key,
    required this.recipientPhone,
  });

  final String recipientPhone;

  @override
  State<DeliveryStep4SuccessScreen> createState() =>
      _DeliveryStep4SuccessScreenState();
}

class _DeliveryStep4SuccessScreenState
    extends State<DeliveryStep4SuccessScreen> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // ⏱ Auto return after 6 seconds
    _timer = Timer(const Duration(seconds: 6), _goHome);
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;

    // ✅ DO NOT KILL HOME
    // ✅ POP BACK TO EXISTING HOME SCREEN
    Navigator.of(context).popUntil((route) => route.isFirst);
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
              Text('DELIVERY COMPLETE', style: AppText.titleXL),
              const SizedBox(height: 16),
              Text(
                'ACCESS CODE SENT TO',
                style: AppText.muted,
              ),
              const SizedBox(height: 8),
              Text(
                '+91 ${widget.recipientPhone}',
                style: AppText.titleL,
              ),
              const SizedBox(height: 24),
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
