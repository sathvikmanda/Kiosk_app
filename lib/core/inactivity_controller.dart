import 'dart:async';
import 'package:flutter/foundation.dart';

class InactivityController {
  // Singleton
  static final InactivityController _instance =
      InactivityController._internal();

  factory InactivityController() => _instance;
  InactivityController._internal();

  Timer? _idleTimer;
  Timer? _resetTimer;

  /// Callbacks
  VoidCallback? onShowWarning;
  VoidCallback? onHideWarning;
  VoidCallback? onSoftReset;

  /// Camera lock (CRITICAL)
  bool _cameraLocked = false;

  /// Public API
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

    _idleTimer = Timer(const Duration(seconds: 10), () {
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
  }
}
