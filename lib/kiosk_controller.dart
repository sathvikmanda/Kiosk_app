import 'package:flutter/services.dart';

class KioskController {
  static const MethodChannel _channel = MethodChannel('kiosk_channel');

  static Future<void> enable() async {
    await _channel.invokeMethod('enableKiosk');
  }

  static Future<void> disable() async {
    await _channel.invokeMethod('disableKiosk');
  }
}