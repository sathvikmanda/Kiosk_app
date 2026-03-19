import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_theme.dart';
import 'core/theme_notifier.dart';
import 'core/route_observer.dart';
import 'core/inactivity_wrapper.dart';
import 'screens/kiosk_home_screen.dart';
import 'utils/immersive_mode.dart';
import 'core/inactivity_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  ImmersiveMode.enable();
  runApp(const DropPointApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// InheritedWidget so any descendant can listen to theme changes
class AppThemeData extends InheritedWidget {
  final bool isDark;
  const AppThemeData({super.key, required this.isDark, required super.child});

  static AppThemeData? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeData>();

  @override
  bool updateShouldNotify(AppThemeData old) => old.isDark != isDark;
}

class DropPointApp extends StatefulWidget {
  const DropPointApp({super.key});

  @override
  State<DropPointApp> createState() => _DropPointAppState();
}

class _DropPointAppState extends State<DropPointApp> {
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    _themeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() => setState(() {});

  @override
  void dispose() {
    _themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeData(
      isDark: _themeNotifier.isDark,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => InactivityController().userInteracted(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [routeObserver, inactivityRouteObserver],
          debugShowCheckedModeBanner: false,
          title: 'Drop Point Kiosk',
          theme: _themeNotifier.isDark ? AppTheme.dark : AppTheme.light,
          home: InactivityWrapper(
            child: const KioskHomeScreen(),
          ),
        ),
      ),
    );
  }
}

// Helper widget — any screen can use this to rebuild on theme change
class ThemeBuilder extends StatelessWidget {
  final Widget Function(bool isDark) builder;
  const ThemeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeData.of(context)?.isDark ?? true;
    return builder(isDark);
  }
}
