import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'kiosk_controller.dart';
import 'core/theme_notifier.dart';
import 'main.dart';

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
    resetTimer = Timer(const Duration(seconds: 2), () => tapCount = 0);
    if (tapCount >= 5) {
      tapCount = 0;
      _showAdminDialog();
    }
  }

  void _showAdminDialog() {
    showDialog(
      context: context,
      builder: (_) => const AdminPinDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
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

class AdminPinDialog extends StatefulWidget {
  const AdminPinDialog();

  @override
  State<AdminPinDialog> createState() => AdminPinDialogState();
}

class AdminPinDialogState extends State<AdminPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  final String adminPin = "5259";
  bool _unlocked = false;
  bool _kioskEnabled = true;
  final _themeNotifier = ThemeNotifier();

  static const _platform = MethodChannel('kiosk_channel');

  Future<void> _launchApp(String package) async {
    try {
      await _platform.invokeMethod('launchApp', {'package': package});
    } catch (_) {}
  }

  void _toggleTheme(bool isDark) {
    _themeNotifier.setDark(isDark);
    setState(() {});
    Navigator.pop(context);
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) {
      return AlertDialog(
        title: const Text("Admin Panel"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Kiosk Mode ──
            ListTile(
              leading: Icon(
                _kioskEnabled ? Icons.lock : Icons.lock_open,
                color: _kioskEnabled ? Colors.green : Colors.orange,
              ),
              title: Text(_kioskEnabled ? "Kiosk Mode: ON" : "Kiosk Mode: OFF"),
              trailing: Switch(
                value: _kioskEnabled,
                activeColor: Colors.green,
                onChanged: (val) async {
                  if (val) {
                    await KioskController.enable();
                  } else {
                    await KioskController.disable();
                  }
                  setState(() => _kioskEnabled = val);
                },
              ),
            ),

            const Divider(),

            // ── Theme ──
            ListTile(
              leading: Icon(
                _themeNotifier.isDark ? Icons.dark_mode : Icons.light_mode,
                color: _themeNotifier.isDark ? Colors.indigo : Colors.amber,
              ),
              title: Text(_themeNotifier.isDark ? "Theme: Dark" : "Theme: Light"),
              trailing: Switch(
                value: _themeNotifier.isDark,
                activeColor: Colors.indigo,
                inactiveThumbColor: Colors.amber,
                inactiveTrackColor: Colors.amber.withOpacity(0.4),
                onChanged: _toggleTheme,
              ),
            ),

            const Divider(),

            // ── Quick Launch ──
            const Text("Quick Launch", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.terminal, size: 18),
                  label: const Text("Termux"),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _launchApp("com.termux");
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text("Settings"),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _launchApp("com.android.settings");
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      );
    }

    // ── PIN entry ──
    return AlertDialog(
      title: const Text("Admin Access"),
      content: TextField(
        controller: _pinController,
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
          onPressed: () {
            if (_pinController.text == adminPin) {
              setState(() => _unlocked = true);
            }
          },
          child: const Text("Unlock"),
        ),
      ],
    );
  }
}
