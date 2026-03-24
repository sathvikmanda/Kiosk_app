import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'drop_step5_locker_opening_screen.dart';

class DropStep4PaymentScreen extends StatefulWidget {
  const DropStep4PaymentScreen({
    super.key,
    required this.phone,
    required this.size,
    required this.hours,
    required this.ratePerHour,
    required this.dropCharge,
    required this.helpId,
  });
final String helpId;

  final String phone;
  final String size;
  final int hours;
  final int ratePerHour;
  final int dropCharge;

  @override
  State<DropStep4PaymentScreen> createState() =>
      _DropStep4PaymentScreenState();
}

class _DropStep4PaymentScreenState
    extends State<DropStep4PaymentScreen> {
  bool isLoading = false;

  // ================= DISPLAY CALC =================
  int get prepaid => widget.hours * widget.ratePerHour;
  int get subtotal => prepaid ;
  double get gst => subtotal * 0.18;
  int get total => (subtotal).round();

  // ================= UNLOCK =================

  Future<void> _unlockLocker() async {
    setState(() => isLoading = true);

    try {
      final result = await ApiService.personalDropoff(
        recipientPhone: widget.phone,
        deliveryPhone: widget.phone,
        size: widget.size.toLowerCase(),
        hours: widget.hours,
        helpId: widget.helpId,
        amount : total,

      );

      final accessCode = result['accessCode'];
      if (accessCode == null) {
        throw Exception('accessCode missing');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DropStep5LockerOpeningScreen(
            phoneNumber: widget.phone,
            recipientPhone: widget.phone,
            accessCode: accessCode,
            helpId: widget.helpId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to unlock locker'),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(48, 36, 48, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 20),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DROP PARCEL.', style: AppText.titleXL),
            SizedBox(height: 6),
            Text(
              'STEP 4 OF 4: CONFIRM & UNLOCK',
              style: AppText.muted,
            ),
          ],
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back),
          label: Text('BACK'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _content() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 28, 40, 24),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _row('Locker Size', widget.size),
          _row('Duration', '${widget.hours} hours'),
          _row('Rate', '₹${widget.ratePerHour} / hr'),

          const SizedBox(height: 20),
const Divider(),
const SizedBox(height: 20),

_row('TOTAL', '₹$total', highlight: true),

          const SizedBox(height: 12),

          // 🔔 SUBTLE NOTICE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.subtle),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Recipient will pay this amount at pickup.',
                    style: AppText.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 68,
            child: ElevatedButton(
              onPressed: isLoading ? null : _unlockLocker,
              child: isLoading
                  ? CircularProgressIndicator(color: AppColors.onSurface)
                  : Text(
                      'UNLOCK LOCKER',
                      style: AppText.titleM.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
Widget _row(String label, String value, {bool highlight = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12), // more spacing
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppText.body.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.inactive,
          ),
        ),
        Text(
          value,
          style: AppText.titleL.copyWith(
            fontSize: highlight ? 36 : 25,
            fontWeight: FontWeight.w700,
            color: highlight
                ? AppColors.primary
                : AppColors.onSurface,
          ),
        ),
      ],
    ),
  );
}


}
