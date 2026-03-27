import 'dart:async';
import 'api_service.dart';
import 'audio_service.dart';

class LockerStateService {
  static final LockerStateService _instance =
      LockerStateService._internal();
  factory LockerStateService() => _instance;
  LockerStateService._internal();

  final StreamController<bool> _allLockedController =
      StreamController<bool>.broadcast();

  // Separate stream for server up/down — does NOT affect locker state
  final StreamController<bool> _serverReachableController =
      StreamController<bool>.broadcast();

  bool _allLocked = true;
  bool _serverReachable = true;
  Timer? _timer;

  int _lockedConfirmations = 0;
  int _unlockedConfirmations = 0;
  int _failureCount = 0;
  bool _isPlayingAudio = false;

  Stream<bool> get stream => _allLockedController.stream;
  Stream<bool> get serverStream => _serverReachableController.stream;
  bool get current => _allLocked;
  bool get isServerReachable => _serverReachable;

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final res = await ApiService.getAllLocked()
            .timeout(const Duration(seconds: 4));

        if (res['success'] == true) {
          _failureCount = 0;

          // Server is back up
          if (!_serverReachable) {
            _serverReachable = true;
            _serverReachableController.add(true);
          }

          final bool backendLocked = res['allLocked'] == true;
          if (backendLocked) {
            _lockedConfirmations++;
            _unlockedConfirmations = 0;
            // 2 confirmations × 2s = 4 seconds to confirm closed
            if (_lockedConfirmations >= 2 && _allLocked != true) {
              _allLocked = true;
              _allLockedController.add(true);
              if (_isPlayingAudio) {
                AudioService.stop();
                _isPlayingAudio = false;
              }
            }
          } else {
            _unlockedConfirmations++;
            _lockedConfirmations = 0;
            // 2 confirmations × 2s = 4 seconds to show locker open
            if (_unlockedConfirmations >= 2 && _allLocked != false) {
              _allLocked = false;
              _allLockedController.add(false);
              if (!_isPlayingAudio) {
                AudioService.loop(AudioEvent.closelocker);
                _isPlayingAudio = true;
              }
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

    // 5 failures at 2s each = 10 seconds before declaring server down
    // Prevents false positives from brief network blips
    if (_failureCount >= 5 && _serverReachable) {
      _serverReachable = false;
      _serverReachableController.add(false);
      if (_isPlayingAudio) {
        AudioService.stop();
        _isPlayingAudio = false;
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    if (_isPlayingAudio) {
      AudioService.stop();
      _isPlayingAudio = false;
    }
  }
}