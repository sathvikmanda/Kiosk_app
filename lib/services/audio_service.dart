import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

enum AudioEvent {
  lockerOpen,
  lockerClose,
  nextStep,
  error,
  paymentsuccess,
  enterPhone,
  closelocker,
  enterotp,
  storeselect,
  knock,
  recipientPhone,
  lockerDirection,
  deliveryestimate,
  selectaddress,
  selectservice,
  selectdornewd
  
}

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static Timer? _spatialTimer;

  // Normal one-shot play
  static Future<void> play(AudioEvent event) async {
    String fileName = _getFileName(event);
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.release);
    await _player.setBalance(0.0);
    await _player.play(AssetSource('audio/$fileName'));
  }

  // One-shot play with balance control
  static Future<void> playWithBalance(AudioEvent event, double balance) async {
    String fileName = _getFileName(event);
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.release);
    await _player.setBalance(balance);
    await _player.play(AssetSource('audio/$fileName'));
  }

  // Loop continuously
  static Future<void> loop(AudioEvent event) async {
    String fileName = _getFileName(event);
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setBalance(0.0);
    await _player.play(AssetSource('audio/$fileName'));
  }

  // Loop with fixed balance (left or right dominant)
  static Future<void> loopWithBalance(AudioEvent event, double balance) async {
    String fileName = _getFileName(event);
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setBalance(balance);
    await _player.play(AssetSource('audio/$fileName'));
  }

  // Loop and bounce left to right (spatial ping-pong effect)
  static Future<void> loopSpatial(AudioEvent event) async {
    String fileName = _getFileName(event);
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('audio/$fileName'));

    bool goingRight = true;
    double balance = -1.0;

    _spatialTimer?.cancel();
    _spatialTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      await _player.setBalance(balance);
      if (goingRight) {
        balance += 0.2;
        if (balance >= 1.0) goingRight = false;
      } else {
        balance -= 0.2;
        if (balance <= -1.0) goingRight = true;
      }
    });
  }

  // Stop everything
  static Future<void> stop() async {
    _spatialTimer?.cancel();
    _spatialTimer = null;
    await _player.stop();
    await _player.setBalance(0.0);
    await _player.setReleaseMode(ReleaseMode.release);
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
      case AudioEvent.paymentsuccess:
        return 'payment_success.mp3';
      case AudioEvent.enterPhone:
        return 'enter_phone.mp3';
      case AudioEvent.closelocker:
        return 'close_locker.mp3';
      case AudioEvent.enterotp:
        return 'enter_otp.mp3';
      case AudioEvent.storeselect:
        return 'store_select.mp3';
      case AudioEvent.knock:
        return 'knock.mp3';
      case AudioEvent.recipientPhone:
        return 'rec_phone.mp3';
      case AudioEvent.lockerDirection:
        return 'locker_direction.mp3';
      case AudioEvent.deliveryestimate:
        return 'delivery_estimation.mp3';
      case AudioEvent.selectaddress:
        return 'select_address.mp3';
      case AudioEvent.selectservice:
        return 'select_service.mp3';
      case AudioEvent.selectdornewd:
        return 'selectdornewd.mp3';
    }
  }
}