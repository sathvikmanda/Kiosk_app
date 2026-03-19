import 'dart:async';
import 'package:flutter/material.dart';

import 'kiosk_home_screen.dart';
import '../services/api_service.dart';

class SendStep2LinkSentScreen extends StatefulWidget {
  const SendStep2LinkSentScreen({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber; // 🔑 10-digit number only

  @override
  State<SendStep2LinkSentScreen> createState() =>
      _SendStep2LinkSentScreenState();
}

class _SendStep2LinkSentScreenState extends State<SendStep2LinkSentScreen> {
  Timer? _timer;
  bool _navigated = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();

    _sendWhatsappLink(); // ✅ API SERVICE CONNECTED
    _timer = Timer(const Duration(seconds: 10), _goHome);
  }

  Future<void> _sendWhatsappLink() async {
    if (_sent) return;
    _sent = true;

    try {
      await ApiService.sendParcelLinkWhatsapp(
        phone: widget.phoneNumber, // ✅ ONLY 10 digits
      );
    } catch (e) {
      // silent fail – kiosk-safe
      debugPrint('WhatsApp link send failed: $e');
    }
  }

  void _goHome() {
    if (_navigated) return;
    _navigated = true;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const KioskHomeScreen()),
      (_) => false,
    );
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
        backgroundColor: const Color(0xFF0B0B0B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 96, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                'LINK SENT',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'A secure link has been sent to',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 8),
              Text(
                '+91 ${widget.phoneNumber}', // UI only
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF7A00),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Please continue on WhatsApp\n to complete your drop.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 24),
              Text(
                'TAP ANYWHERE TO RETURN HOME',
                style: TextStyle(color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
