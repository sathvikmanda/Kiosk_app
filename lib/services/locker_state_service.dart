import 'dart:async';
import 'api_service.dart';

class LockerStateService {
  static final LockerStateService _instance =
      LockerStateService._internal();

  factory LockerStateService() => _instance;
  LockerStateService._internal();

  final StreamController<bool> _allLockedController =
      StreamController<bool>.broadcast();

  bool _allLocked = true;
  Timer? _timer;

  // 🔥 Stability counters
  int _lockedConfirmations = 0;
  int _unlockedConfirmations = 0;
  int _failureCount = 0;

  Stream<bool> get stream => _allLockedController.stream;
  bool get current => _allLocked;

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final res = await ApiService.getAllLocked();

        if (res['success'] == true) {
          _failureCount = 0;

          final bool backendLocked = res['allLocked'] == true;

          if (backendLocked) {
            _lockedConfirmations++;
            _unlockedConfirmations = 0;

            // 🔥 Require 2 confirmations before switching to LOCKED
            if (_lockedConfirmations >= 2 && _allLocked != true) {
              _allLocked = true;
              _allLockedController.add(true);
            }
          } else {
            _unlockedConfirmations++;
            _lockedConfirmations = 0;

            // 🔥 Require 2 confirmations before switching to UNLOCKED
            if (_unlockedConfirmations >= 2 && _allLocked != false) {
              _allLocked = false;
              _allLockedController.add(false);
            }
          }
        } else {
          _handleFailure();
        }
      } catch (_) {
        _handleFailure();
      }
    });
  }

  void _handleFailure() {
    _failureCount++;

    // 🔥 Only mark unsafe after 3 consecutive failures
    if (_failureCount >= 3) {
      if (_allLocked != false) {
        _allLocked = false;
        _allLockedController.add(false);
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}