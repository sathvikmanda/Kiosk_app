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

  void userInteracted() {
    _idleTimer?.cancel();
    _resetTimer?.cancel();
    onHideWarning?.call();

    _idleTimer = Timer(const Duration(seconds: 30), () {
      onShowWarning?.call();
      _resetTimer = Timer(const Duration(seconds: 10), () {
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
  }
}