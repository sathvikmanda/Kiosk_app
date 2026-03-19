import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'inactivity_controller.dart';
import '../main.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class InactivityRouteObserver extends NavigatorObserver {
  final _controller = InactivityController();
  OverlayEntry? _overlayEntry;
  Timer? _countdownTimer;
  int _countdown = 30;

  @override
  void didPush(Route route, Route? previousRoute) {
    debugPrint('[Inactivity] didPush: ${route.settings.name}');
    if (previousRoute != null) {
      debugPrint('[Inactivity] Left home → timer started');
      _controller.onShowWarning = _showWarning;
      _controller.onHideWarning = _hideWarning;
      _controller.onSoftReset = _resetToHome;
      _controller.userInteracted();
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    debugPrint('[Inactivity] didPop back to: ${previousRoute?.settings.name}');
    if (previousRoute != null && previousRoute.isFirst) {
      debugPrint('[Inactivity] Back on home → timer paused');
      _hideWarning();
      _controller.onShowWarning = null;
      _controller.onHideWarning = null;
      _controller.onSoftReset = null;
      _controller.dispose();
    }
  }

  void _showWarning() {
    debugPrint('[Inactivity] _showWarning called');
    _countdown = 30;
    _overlayEntry?.remove();
    _overlayEntry = null;

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      debugPrint('[Inactivity] No overlay found');
      return;
    }

    final warningWidget = _InactivityWarningOverlay(
      initialCountdown: _countdown,
      onStay: _onUserStay,
    );

    _overlayEntry = OverlayEntry(builder: (_) => warningWidget);
    overlay.insert(_overlayEntry!);

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _countdown--;
      debugPrint('[Inactivity] Countdown: $_countdown');
      warningWidget.updateCountdown(_countdown);
      if (_countdown <= 0) t.cancel();
    });
  }

  void _hideWarning() {
    _countdownTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _countdown = 30;
  }

  void _onUserStay() {
    debugPrint('[Inactivity] User stayed');
    _hideWarning();
    _controller.userInteracted();
  }

void _resetToHome() {
  debugPrint('[Inactivity] _resetToHome called');
  debugPrint('[Inactivity] activeHelpId = ${_controller.activeHelpId}');
  _hideWarning();

  final helpId = _controller.activeHelpId;
  if (helpId != null) {
    debugPrint('[Inactivity] Calling stopComplaint for: $helpId');
    ApiService.stopComplaint(helpId).catchError((e) {
      debugPrint('[Inactivity] stopComplaint error: $e');
    });
    _controller.activeHelpId = null;
  } else {
    debugPrint('[Inactivity] No helpId — skipping API');
  }

  navigatorKey.currentState?.popUntil((route) => route.isFirst);
}
}

final inactivityRouteObserver = InactivityRouteObserver();

// ── Warning Overlay Widget ────────────────────────────────────────

class _InactivityWarningOverlay extends StatefulWidget {
  final int initialCountdown;
  final VoidCallback onStay;

  _InactivityWarningOverlay({
    required this.initialCountdown,
    required this.onStay,
  });

  void updateCountdown(int value) {
    _stateRef?.setCountdown(value);
  }

  _InactivityWarningOverlayState? _stateRef;

  @override
  State<_InactivityWarningOverlay> createState() {
    final s = _InactivityWarningOverlayState();
    _stateRef = s;
    return s;
  }
}

class _InactivityWarningOverlayState extends State<_InactivityWarningOverlay>
    with SingleTickerProviderStateMixin {
  late int _countdown;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _countdown = widget.initialCountdown;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  void setCountdown(int value) {
    if (mounted) setState(() => _countdown = value);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _countdown / 30.0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          // Tap anywhere on the overlay to dismiss
          onTap: widget.onStay,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Blur + dark overlay ──
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: AppColors.background.withOpacity(0.80),
                ),
              ),

              // ── Subtle primary glow behind card ──
              Center(
                child: Container(
                  width: 520,
                  height: 520,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Card ──
              Center(
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 44),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.18),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 60,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.06),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Timer box ──
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 88,
                                height: 88,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 3,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.12),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                              Text(
                                '$_countdown',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  height: 1,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        Text(
                          'Still there?',
                          style: AppText.titleL.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontSize: 26,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'No activity detected.\nReturning to home screen soon.',
                          textAlign: TextAlign.center,
                          style: AppText.muted.copyWith(
                            height: 1.65,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── I'm Still Here button ──
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: widget.onStay,
                            child: Text(
                              "I'M HERE",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Hint text ──
                        Text(
                          'or touch anywhere to continue',
                          textAlign: TextAlign.center,
                          style: AppText.muted.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}