import 'dart:async';
import 'package:flutter/material.dart';
import 'kiosk_controller.dart';

class HiddenAdminUnlock extends StatefulWidget {
  final Widget child;

  const HiddenAdminUnlock({super.key, required this.child});

  @override
  State<HiddenAdminUnlock> createState() => _HiddenAdminUnlockState();
}

class _HiddenAdminUnlockState extends State<HiddenAdminUnlock> {
  int tapCount = 0;
  Timer? resetTimer;

  void _handleTap() {
    tapCount++;

    resetTimer?.cancel();
    resetTimer = Timer(const Duration(seconds: 2), () {
      tapCount = 0;
    });

    if (tapCount >= 5) {
      tapCount = 0;
      _showAdminDialog();
    }
  }

  void _showAdminDialog() {
    showDialog(
      context: context,
      builder: (_) => const _AdminPinDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          right: 0,
          width: 120,
          height: 120,
          child: GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.translucent,
            child: Container(),
          ),
        ),
      ],
    );
  }
}

class _AdminPinDialog extends StatefulWidget {
  const _AdminPinDialog();

  @override
  State<_AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<_AdminPinDialog> {
  final TextEditingController _controller = TextEditingController();
  final String adminPin = "5259";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Admin Access"),
      content: TextField(
        controller: _controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: "Enter PIN"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_controller.text == adminPin) {
              await KioskController.disable();
              Navigator.pop(context);
            }
          },
          child: const Text("Unlock"),
        ),
      ],
    );
  }
}