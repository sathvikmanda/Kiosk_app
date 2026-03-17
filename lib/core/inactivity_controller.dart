import 'dart:async';
import 'package:flutter/foundation.dart';

class InactivityController {
  static final InactivityController _instance =
      InactivityController._internal();
  factory InactivityController() => _instance;
  InactivityController._internal();

  Timer? _idleTimer;
  Timer? _resetTimer;

  VoidCallback? onShowWarning;
  VoidCallback? onHideWarning;
  VoidCallback? onSoftReset;

  bool _cameraLocked = false;
  bool _paused = false;

  // ── Active session helpId ─────────────────────────────────────
  String? activeHelpId;

  void lockCamera() {
    _cameraLocked = true;
    debugPrint('[Inactivity] Camera locked');
  }

  void unlockCamera() {
    _cameraLocked = false;
    debugPrint('[Inactivity] Camera unlocked');
  }

  // Call when Razorpay (or any native overlay) opens
  void pauseForPayment() {
    _paused = true;
    _idleTimer?.cancel();
    _resetTimer?.cancel();
    onHideWarning?.call();
    debugPrint('[Inactivity] Paused for payment');
  }

  // Call when Razorpay closes (success, error, or cancel)
  void resumeAfterPayment() {
    _paused = false;
    debugPrint('[Inactivity] Resumed after payment');
    userInteracted(); // restart the idle timer fresh
  }

  void userInteracted() {
    if (_paused) return;
    _idleTimer?.cancel();
    _resetTimer?.cancel();
    onHideWarning?.call();

    _idleTimer = Timer(const Duration(seconds: 60), () {
      onShowWarning?.call();
      _resetTimer = Timer(const Duration(seconds: 30), () {
        if (_cameraLocked) {
          debugPrint('[Inactivity] Reset blocked (camera active)');
          return;
        }
        debugPrint('[Inactivity] Soft reset triggered');
        onSoftReset?.call();
      });
    });
  }

  void dispose() {
    _idleTimer?.cancel();
    _resetTimer?.cancel();
    _cameraLocked = false;
    _paused = false;
  }
}
