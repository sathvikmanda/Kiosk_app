import 'package:audioplayers/audioplayers.dart';

enum AudioEvent {
  lockerOpen,
  lockerClose,
  nextStep,
  error,
  success,
  enterPhone,
  closeDoor,
}

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play(AudioEvent event) async {
    String fileName = _getFileName(event);

    await _player.stop(); // Prevent overlap
    await _player.play(AssetSource('audio/$fileName'));
  }

  static String _getFileName(AudioEvent event) {
    switch (event) {
      case AudioEvent.lockerOpen:
        return 'locker_open.mp3';
      case AudioEvent.lockerClose:
        return 'locker_close.mp3';
      case AudioEvent.nextStep:
        return 'next_step.mp3';
      case AudioEvent.error:
        return 'error.mp3';
      case AudioEvent.success:
        return 'success.mp3';
      case AudioEvent.enterPhone:
        return 'enter_phone.mp3';
      case AudioEvent.closeDoor:
        return 'close_door.mp3';
    }
  }
}