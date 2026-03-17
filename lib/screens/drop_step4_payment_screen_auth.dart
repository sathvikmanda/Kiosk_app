import 'package:flutter/material.dart';
import '../core/inactivity_controller.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'drop_step5_locker_opening_screen.dart';

class DropStep4PaymentScreenAuth extends StatefulWidget {
  const DropStep4PaymentScreenAuth({
    super.key,
    required this.senderPhone,
    required this.recipientPhone,
    required this.size,
    required this.hours,
    required this.ratePerHour,
    required this.dropCharge,
    required this.helpId,
  });
  final String helpId;


  final String senderPhone;
  final String recipientPhone;
  final String size;
  final int hours;
  final int ratePerHour;
  final int dropCharge;

  @override
  State<DropStep4PaymentScreenAuth> createState() =>
      _DropStep4PaymentScreenAuthState();
}

class _DropStep4PaymentScreenAuthState
    extends State<DropStep4PaymentScreenAuth> {
  late Razorpay _razorpay;
  bool loading = false;
  String? parcelId;

  static const double gstPercent = 18;

  int get prepaid => widget.hours * widget.ratePerHour;
  int get subtotal => prepaid + widget.dropCharge;
  double get gst => subtotal * gstPercent / 100;
  int get total => (subtotal).round();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ================= START PAYMENT =================

  Future<void> _startPayment() async {
    setState(() => loading = true);

    try {
      final data = await ApiService.createDropoffOrderAuth(
        senderPhone: widget.senderPhone,
        recipientPhone: widget.recipientPhone,
        size: widget.size,
        hours: widget.hours,
      );

      parcelId = data['parcelId'];

      InactivityController().pauseForPayment();
      _razorpay.open({
        'key': data['razorpayKeyId'],
        'order_id': data['orderId'],
        'amount': data['amount'],
        'currency': 'INR',
        'name': 'DropPoint',
        'description': 'Locker Drop',
        'prefill': {
          'contact': widget.senderPhone,
        },
        'theme': {'color': '#FF7A00'},
      });
    } catch (_) {
      _error('Payment initialization failed');
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= PAYMENT CALLBACK =================

  Future<void> _onPaymentSuccess(PaymentSuccessResponse res) async {
    InactivityController().resumeAfterPayment();
    if (parcelId == null) {
      _error('Invalid payment state');
      return;
    }

    try {
      final result = await ApiService.verifyDropPayment(
        orderId: res.orderId!,
        paymentId: res.paymentId!,
        signature: res.signature!,
        parcelId: parcelId!,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DropStep5LockerOpeningScreen(
            phoneNumber: widget.senderPhone,
            accessCode: result['accessCode'],
            helpId: widget.helpId,
          ),
        ),
      );
    } catch (_) {
      _error('Payment verification failed');
    }
  }

  void _onPaymentError(PaymentFailureResponse res) {
    InactivityController().resumeAfterPayment();
    _error('Payment cancelled');
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false, // ✅ ONLY FIX
      body: Padding(
        padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 12),
            Text(
              'PAYING FROM +91 ${widget.senderPhone}',
              style: AppText.muted,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Locker Size', widget.size),
                    _row('Duration', '${widget.hours} hrs'),
                    _row('Rate', '₹${widget.ratePerHour} / hr'),
                    const Divider(height: 32),
                    _row('Prepaid', '₹$prepaid'),
                    _row('Drop Charge', '₹${widget.dropCharge}'),
                    const Divider(height: 32),
                    _row('TOTAL', '₹$total', highlight: true),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 68,
                      child: ElevatedButton(
                        onPressed: loading ? null : _startPayment,
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text('PAY & CONTINUE',
                                style: AppText.titleL),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('DROP PAYMENT.', style: AppText.titleXL),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('BACK'),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6), // slightly tighter
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppText.muted.copyWith(
            fontSize: 16, // ⬇️ smaller label
          ),
        ),
        Text(
          value,
          style: AppText.titleL.copyWith(
            fontSize: highlight ? 30 : 18, // ⬇️ smaller values
            color: highlight ? AppColors.primary : Colors.white,
          ),
        ),
      ],
    ),
  );
}

}
