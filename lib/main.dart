import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_theme.dart';
import 'core/route_observer.dart';
import 'core/inactivity_controller.dart';

import 'screens/kiosk_home_screen.dart';
import 'utils/immersive_mode.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  ImmersiveMode.enable();

  runApp(const DropPointApp());
}

class DropPointApp extends StatelessWidget {
  const DropPointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        InactivityController().userInteracted();
      },
      child: MaterialApp(
        navigatorObservers: [routeObserver],
        debugShowCheckedModeBanner: false,
        title: 'Drop Point Kiosk',
        theme: AppTheme.theme,
        home: const KioskHomeScreen(),
      ),
    );
  }
}
