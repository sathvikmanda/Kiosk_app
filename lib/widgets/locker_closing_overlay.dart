import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';

class LockerClosingOverlay extends StatefulWidget {
  const LockerClosingOverlay({super.key});

  @override
  State<LockerClosingOverlay> createState() => _LockerClosingOverlayState();
}

class _LockerClosingOverlayState extends State<LockerClosingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _doorRotation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    // Door rotates from OPEN (-105°) → CLOSED (0°)
    _doorRotation = Tween<double>(
      begin: -105 * pi / 180,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.92),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== 3D LOCKER =====
              SizedBox(
                width: 260,
                height: 200,
                child: AnimatedBuilder(
                  animation: _doorRotation,
                  builder: (_, __) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(-0.32)
                        ..rotateX(0.12),
                      child: Stack(
                        children: [
                          _panel(
                            offset: const Offset(0, 0),
                            depth: -40,
                          ),

                          // LEFT SIDE
                          _sidePanel(
                            alignment: Alignment.centerLeft,
                            rotationY: pi / 2,
                          ),

                          // RIGHT SIDE
                          _sidePanel(
                            alignment: Alignment.centerRight,
                            rotationY: -pi / 2,
                          ),

                          // TOP
                          _topBottomPanel(isTop: true),

                          // BOTTOM
                          _topBottomPanel(isTop: false),

                          // 🚪 DOOR
                          Transform(
                            alignment: Alignment.centerLeft,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(_doorRotation.value),
                            child: _door(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // 🔥 PRIMARY COMMAND
              Text(
                'CLOSE THE LOCKER',
                style: AppText.titleXL.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'WAITING FOR LOCKER',
                style: AppText.titleM.copyWith(
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 32),

              // ⏳ LOADING
              const CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== PANELS =====

  Widget _panel({required Offset offset, required double depth}) {
    return Transform.translate(
      offset: offset,
      child: Transform.translate(
        offset: Offset(0, depth),
        child: Container(
          width: 260,
          height: 180,
          decoration: _panelDecoration(),
        ),
      ),
    );
  }

  Widget _sidePanel({
    required Alignment alignment,
    required double rotationY,
  }) {
    return Align(
      alignment: alignment,
      child: Transform(
        alignment: alignment,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(rotationY),
        child: Container(
          width: 120,
          height: 180,
          decoration: _panelDecoration(),
        ),
      ),
    );
  }

  Widget _topBottomPanel({required bool isTop}) {
    return Align(
      alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
      child: Transform(
        alignment: isTop ? Alignment.bottomCenter : Alignment.topCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(isTop ? pi / 2 : -pi / 2),
        child: Container(
          width: 260,
          height: 120,
          decoration: _panelDecoration(),
        ),
      ),
    );
  }

  // ===== DOOR =====

  Widget _door() {
    return Container(
      width: 260,
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2B1A00),
            Color(0xFF1A0E00),
          ],
        ),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.6),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 80,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.8),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: const Color(0xFF1F1F1F),
      border: Border.all(color: AppColors.primary, width: 2),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.25),
          blurRadius: 12,
          inset: true,
        ),
      ],
    );
  }
}
