import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'send_locker_opening_screen.dart';

class SendProcessingOrderScreen extends StatefulWidget {
  const SendProcessingOrderScreen({
    super.key,
    required this.parcelId,
  });

  final String parcelId;

  @override
  State<SendProcessingOrderScreen> createState() =>
      _SendProcessingOrderScreenState();
}

class _SendProcessingOrderScreenState
    extends State<SendProcessingOrderScreen> {
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _processOrder();
  }

  Future<void> _processOrder() async {
    try {
      await ApiService.createShipment(widget.parcelId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SendLockerOpeningScreen(),
        ),
      );
    } catch (e) {
      setState(() => failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!failed) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 32),
              Text(
                'PROCESSING ORDER',
                style: AppText.titleL,
              ),
              const SizedBox(height: 12),
              Text(
                'Please wait. Do not close the screen.',
                style: AppText.muted,
              ),
            ] else ...[
              Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: AppText.titleL,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to process your order',
                style: AppText.muted,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() => failed = false);
                  _processOrder();
                },
                child: const Text('RETRY'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
