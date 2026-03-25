import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/kiosk_camera_layer.dart';
import '../core/inactivity_controller.dart';

import '../services/locker_state_service.dart';
import 'locker_open_guard_overlay.dart';

import '../models/drop_mode.dart';

import 'help_screen.dart';
import '../hidden_admin_unlock.dart';
import '../kiosk_controller.dart';
import 'store_step1_screen.dart';
import 'send_step3_delivery_estimate_screen.dart';
import 'locker_opened_screen.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import 'server_down_screen.dart';
import 'delivery_step1_recipient_phone_screen.dart';
import 'drop_step1_phone_screen.dart';
import 'overstay_payment_screen.dart';
import 'server_down_screen.dart';


class KioskHomeScreen extends StatefulWidget {
  const KioskHomeScreen({super.key});

  @override
  State<KioskHomeScreen> createState() => _KioskHomeScreenState();
}

class _KioskHomeScreenState extends State<KioskHomeScreen>
    with SingleTickerProviderStateMixin {
  static const int codeLength = 6;
  final List<String> _code = [];

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  bool _loading = false;
  bool _scanInProgress = false;
  bool _recordingStartInProgress = false;
  String? _errorText;

  // 👇 ADD THESE
  bool _showAudioTester = false;
  double _testBalance = 0.0;
  AudioEvent _selectedEvent = AudioEvent.closelocker;

  final LockerStateService _lockerState = LockerStateService();
  bool _showInactivityWarning = false;
  bool _serverDownShowing = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulse = Tween(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    final inactivity = InactivityController();

    inactivity.onShowWarning = () {
      if (!mounted) return;
      setState(() => _showInactivityWarning = true);
    };

    inactivity.onHideWarning = () {
      if (!mounted) return;
      setState(() => _showInactivityWarning = false);
    };

    inactivity.userInteracted();
    KioskController.enable();
    _lockerState.start();

    // Listen to server reachability — show server down screen when backend is off
    _lockerState.serverStream.listen((reachable) {
      if (!mounted) return;
      if (!reachable && !_serverDownShowing) {
        _serverDownShowing = true;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ServerDownScreen()),
        ).then((_) => _serverDownShowing = false);
      }
    });
  }

  Future<void> _checkServerHealth() async {
    try {
      await ApiService.getAllLocked().timeout(const Duration(seconds: 5));
    } catch (_) {
      if (!mounted) return;
      if (!_serverDownShowing) {
        _serverDownShowing = true;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ServerDownScreen()),
        ).then((_) => _serverDownShowing = false);
      }
    }
  }

  @override
  void dispose() {
    InactivityController().dispose();
    _lockerState.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _softReset() {
    setState(() {
      _code.clear();
      _errorText = null;
      _loading = false;
      _scanInProgress = false;
      _recordingStartInProgress = false;
      _showInactivityWarning = false;
      _showAudioTester = false; // 👈 ADD
    });
  }

  // ================= QR SCAN =================

  Future<void> _handleScan(String raw) async {
    if (_scanInProgress) return;
    _scanInProgress = true;

    try {
      final response = await ApiService.unlockWithCode(raw);
      if (!mounted) return;

      if (response['paymentRequired'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OverstayPaymentScreen(
              parcelId: response['parcelId'],
              amount: response['amount'],
              usageSummary: Map<String, dynamic>.from(response['usageSummary']),
              parcelRaw: Map<String, dynamic>.from(response),
            ),
          ),
        );
        return;
      }

      if (response['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LockerOpenedScreen(accessCode: raw),
          ),
        );
        return;
      }

      throw Exception(response['message'] ?? 'Invalid QR');
    } catch (e) {
      debugPrint('QR UNLOCK ERROR => $e');
    } finally {
      _scanInProgress = false;
    }
  }

  // ================= KEYPAD =================

  void _onKeyPress(String value) {
    InactivityController().userInteracted();
    if (_loading) return;

    setState(() {
      _errorText = null;

      if (value == 'Clear') {
        _code.clear();
      } else if (value == '⌫') {
        if (_code.isNotEmpty) _code.removeLast();
      } else if (_code.length < codeLength) {
        _code.add(value);
      }
    });
  }

  Future<void> _submitCode() async {
    final accessCode = _code.join();

    setState(() {
      _loading = true;
      _errorText = null;
    });

    bool navigated = false;

    try {
      final response = await ApiService.unlockWithCode(accessCode);
      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _loading = false;
          _code.clear();
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LockerOpenedScreen(accessCode: accessCode),
          ),
        );
        return;
      }

      if (response['paymentRequired'] == true) {
        setState(() {
          _loading = false;
          _code.clear();
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OverstayPaymentScreen(
              parcelId: response['parcelId'],
              amount: response['amount'],
              usageSummary: Map<String, dynamic>.from(response['usageSummary']),
              parcelRaw: Map<String, dynamic>.from(response),
            ),
          ),
        );
        return;
      }

      throw Exception(response['message'] ?? 'Unknown error');
    } catch (e) {
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted || navigated) return;
      setState(() {
        _loading = false;
        _code.clear();
      });
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return HiddenAdminUnlock(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Row(
              children: [
                _leftPanel(context),
                _rightPanel(context),
              ],
            ),

            Positioned(
              top: 18,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Icon(Icons.qr_code_scanner, size: 48, color: AppColors.primary),
                  const SizedBox(height: 6),
                  Text(
                    'SCAN QR HERE',
                    style: AppText.muted.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            KioskCameraLayer(onScan: _handleScan),

            StreamBuilder<bool>(
              stream: _lockerState.stream,
              initialData: _lockerState.current,
              builder: (context, snapshot) {
                final allLocked = snapshot.data ?? false;
                if (!allLocked) {
                  return const LockerOpenGuardOverlay();
                }
                return const SizedBox.shrink();
              },
            ),

            // 👇 AUDIO TESTER PANEL
            if (_showAudioTester) _buildAudioTesterPanel(),

            if (_showInactivityWarning)
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0)),
              ),
          ],
        ),
      ),
    );
  }

  // ================= AUDIO TESTER PANEL =================

  Widget _buildAudioTesterPanel() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🎛️  Audio Tester',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    AudioService.stop();
                    setState(() => _showAudioTester = false);
                  },
                  child: const Icon(Icons.close, color: Colors.white54, size: 22),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sound selector
            Text('Sound', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AudioEvent.values.map((event) {
                  final selected = _selectedEvent == event;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEvent = event),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.primary : Colors.white24,
                        ),
                      ),
                      child: Text(
                        event.name,
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Balance slider
            Row(
              children: [
                Text('🔈 L', style: TextStyle(color: Colors.white54, fontSize: 13)),
                Expanded(
                  child: Slider(
                    value: _testBalance,
                    min: -1.0,
                    max: 1.0,
                    divisions: 20,
                    activeColor: AppColors.primary,
                    inactiveColor: Colors.white12,
                    onChanged: (val) => setState(() => _testBalance = val),
                  ),
                ),
                Text('R 🔉', style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),

            // Balance value display
            Center(
              child: Text(
                'Balance: ${_testBalance.toStringAsFixed(2)}  '
                '(${_testBalance < -0.1 ? "Left dominant" : _testBalance > 0.1 ? "Right dominant" : "Center"})',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Play Once
                Expanded(
                  child: _testerButton(
                    label: '▶ Play Once',
                    color: Colors.white10,
                    onTap: () => AudioService.playWithBalance(_selectedEvent, _testBalance),
                  ),
                ),
                const SizedBox(width: 10),
                // Loop
                Expanded(
                  child: _testerButton(
                    label: '🔁 Loop',
                    color: Colors.white10,
                    onTap: () => AudioService.loopWithBalance(_selectedEvent, _testBalance),
                  ),
                ),
                const SizedBox(width: 10),
                // Spatial
                Expanded(
                  child: _testerButton(
                    label: '↔ Spatial',
                    color: Colors.white10,
                    onTap: () => AudioService.loopSpatial(_selectedEvent),
                  ),
                ),
                const SizedBox(width: 10),
                // Stop
                Expanded(
                  child: _testerButton(
                    label: '⏹ Stop',
                    color: Colors.red.withOpacity(0.3),
                    onTap: () => AudioService.stop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _testerButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ================= LEFT PANEL =================

  Widget _leftPanel(BuildContext context) {
    return Expanded(
      flex: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(48, 56, 48, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 👇 LONG PRESS "DropPoint" to open audio tester
            GestureDetector(
              onLongPress: () {
                setState(() => _showAudioTester = !_showAudioTester);
              },
              child: Text(
                'DropPoint',
                style: AppText.titleXL.copyWith(
                  color: AppColors.primary,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text('What would you like to do?', style: AppText.muted),
            const SizedBox(height: 40),

            Expanded(
              child: Column(
                children: [
                   Expanded(
                    child: _actionButton(
                      icon: Icons.archive_outlined,
                      title: 'Store',
                      subtitle: 'Keep items temporarily',
                      onTap: () async {
                        if (_recordingStartInProgress) return;
                        _recordingStartInProgress = true;
                        try {
                          ApiService.trackLockerClick(service: 'store');
                          final helpId = await ApiService.startComplaintIfNeeded();
                          if (helpId == null) return;
                          InactivityController().activeHelpId = helpId;
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoreStep1Screen(helpId: helpId),
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _recordingStartInProgress = false);
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Expanded(
                    child: _actionButton(
                      icon: Icons.move_to_inbox_outlined,
                      title: 'Drop',
                      subtitle: 'Leave item for someone else',
                      onTap: () async {
                        if (_recordingStartInProgress) return;
                        _recordingStartInProgress = true;
                        try {
                          ApiService.trackLockerClick(service: 'drop');
                          final helpId = await ApiService.startComplaintIfNeeded();
                          if (helpId == null) return;
                          InactivityController().activeHelpId = helpId;
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DropStep1PhoneScreen(
                                dropMode: DropMode.personal,
                                helpId: helpId,
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _recordingStartInProgress = false);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _actionButton(
                      icon: Icons.local_shipping_rounded,
                      title: 'Send',
                      subtitle: 'Courier pickup from locker',
                      onTap: () async {
                        if (_recordingStartInProgress) return;
                        _recordingStartInProgress = true;
                        try {
                          ApiService.trackLockerClick(service: 'send');
                          final helpId = await ApiService.startComplaintIfNeeded();
                          if (helpId == null) return;
                          InactivityController().activeHelpId = helpId;
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SendStep3DeliveryEstimateScreen(),
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _recordingStartInProgress = false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= RIGHT PANEL =================

  Widget _rightPanel(BuildContext context) {
    final keys = ['1','2','3','4','5','6','7','8','9','Clear','0','⌫'];

    return Expanded(
      flex: 4,
      child: Container(
        color: AppColors.panel,
        padding: const EdgeInsets.fromLTRB(40, 56, 40, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup / Drop Code',
                      style: AppText.titleL.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text('Enter code to open locker', style: AppText.muted),
                  ],
                ),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.help_outline, color: AppColors.card, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "HELP",
                            style: TextStyle(
                              color: AppColors.card,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                codeLength,
                (i) => _codeBox(i < _code.length ? _code[i] : ''),
              ),
            ),

            const SizedBox(height: 20),

            if (_errorText != null)
              Center(
                child: Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: keys.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 72,
                ),
                itemBuilder: (_, i) => _key(keys[i]),
              ),
            ),

            const SizedBox(height: 20),

            ScaleTransition(
              scale: _code.length == codeLength
                  ? _pulse
                  : const AlwaysStoppedAnimation(1),
              child: SizedBox(
                width: double.infinity,
                height: 76,
                child: ElevatedButton(
                  onPressed: (_code.length == codeLength && !_loading) ? _submitCode : null,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'SUBMIT',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= COMPONENTS =================

  Widget _actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Row(
            children: [
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Icon(icon, size: 48, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppText.titleL.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: AppText.muted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _codeBox(String value) {
    final filled = value.isNotEmpty;
    return Container(
      width: 46,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: filled ? AppColors.primary : Colors.white12),
      ),
      child: Text(
        filled ? value : '•',
        style: TextStyle(
          color: filled ? AppColors.primary : Colors.white38,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _key(String label) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _onKeyPress(label),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _deliveryDropoff() {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DeliveryStep1RecipientPhoneScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Center(
            child: Text(
              'DELIVERY DROPOFF',
              style: AppText.titleL.copyWith(
                color: AppColors.primary,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}