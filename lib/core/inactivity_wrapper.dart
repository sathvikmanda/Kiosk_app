import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/kiosk_home_screen.dart';

class InactivityWrapper extends StatefulWidget {
  const InactivityWrapper({
    super.key,
    required this.child,
    this.timeout = const Duration(seconds: 30),
  });

  final Widget child;
  final Duration timeout;

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, _resetToHome);
  }

  void _resetToHome() {
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const KioskHomeScreen()),
      (_) => false,
    );
  }

  void _handleUserInteraction([_]) {
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      child: widget.child,
    );
  }
}
