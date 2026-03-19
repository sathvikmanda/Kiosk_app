import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'route_observer.dart';

class KioskCameraLayer extends StatefulWidget {
  final void Function(String) onScan;

  const KioskCameraLayer({
    super.key,
    required this.onScan,
  });

  @override
  State<KioskCameraLayer> createState() => _KioskCameraLayerState();
}

class _KioskCameraLayerState extends State<KioskCameraLayer>
    with RouteAware {
  late final MobileScannerController _controller;

  bool _scanLocked = false;
  bool _isActive = false;
  bool _subscribed = false;
  bool _starting = false; // guard against concurrent starts

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      facing: CameraFacing.front,
      detectionSpeed: DetectionSpeed.noDuplicates,
      torchEnabled: false,
    );
  }

  // ================= ROUTE AWARE =================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (!_subscribed && route is PageRoute) {
      routeObserver.subscribe(this, route);
      _subscribed = true;
    }
  }

  @override
  void dispose() {
    if (_subscribed) {
      routeObserver.unsubscribe(this);
    }
    _controller.dispose();
    super.dispose();
  }

  /// Screen first shown
  @override
  void didPush() {
    _startCamera();
  }

  /// Another screen pushed on top
  @override
  void didPushNext() {
    _stopCamera();
  }

  /// Coming back from another screen (including popUntil)
  /// Use a short delay so rapid consecutive didPopNext calls
  /// (from popUntil) settle before we start the camera
  @override
  void didPopNext() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _startCamera();
    });
  }

  // ================= CAMERA CONTROL =================

  void _startCamera() async {
    // Already active or in the middle of starting — skip
    if (_isActive || _starting) return;
    _starting = true;

    try {
      await _controller.start();
      _isActive = true;
      debugPrint("Camera started");
    } catch (e) {
      debugPrint("Camera start error: $e");
    } finally {
      _starting = false;
    }
  }

  void _stopCamera() async {
    if (!_isActive) return;

    try {
      await _controller.stop();
      _isActive = false;
      debugPrint("Camera stopped");
    } catch (e) {
      debugPrint("Camera stop error: $e");
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -1000,
      left: -1000,
      child: SizedBox(
        width: 1,
        height: 1,
        child: MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_scanLocked) return;
            if (capture.barcodes.isEmpty) return;

            final raw = capture.barcodes.first.rawValue;
            if (raw == null) return;

            _scanLocked = true;
            widget.onScan(raw);

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _scanLocked = false;
            });
          },
        ),
      ),
    );
  }
}
