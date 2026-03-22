import 'package:flutter/material.dart';
import '../core/inactivity_controller.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'send_processing_order_screen.dart';

class SendSummaryScreen extends StatefulWidget {
  const SendSummaryScreen({
    super.key,
    required this.phoneNumber,
    required this.fromLocation,
    required this.toAddress,
    required this.courierName,
    required this.estimatedDays,
    required this.deliveryCost,
    required this.lockerCost,
    required this.parcelId,
  });

  final String phoneNumber;
  final String fromLocation;
  final String toAddress;
  final String courierName;
  final String estimatedDays;
  final int deliveryCost;
  final int lockerCost;
  final String parcelId;

  @override
  State<SendSummaryScreen> createState() => _SendSummaryScreenState();
}

class _SendSummaryScreenState extends State<SendSummaryScreen> {
  late Razorpay _razorpay;
  bool paying = false;
  bool _paymentLaunched = false;

  int get totalCost => widget.deliveryCost + widget.lockerCost;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ===============================
  // PAY FLOW
  // ===============================
Future<void> _payAndContinue() async {
  if (_paymentLaunched) return;
  _paymentLaunched = true;
  setState(() => paying = true);

  // 🔥 Convert rupees to paise
  final int totalInPaise =
      (widget.deliveryCost + widget.lockerCost) ;

  try {
    final order = await ApiService.createRazorpayOrder(
      parcelId: widget.parcelId,
      amount: totalInPaise,
    );

    InactivityController().pauseForPayment();
      _razorpay.open({
      'key': order['key'],
      'amount': order['amount'],
      'order_id': order['orderId'],
      'name': 'DropPoint',
      'description': 'Parcel Delivery',
      'prefill': {
        'contact': widget.phoneNumber,
      },
    });
  } catch (e) {
    setState(() => paying = false);
    _showError('Payment initiation failed');
  }
}

  // ===============================
  // PAYMENT SUCCESS
  // ===============================
  Future<void> _onSuccess(PaymentSuccessResponse res) async {
    InactivityController().resumeAfterPayment();
    try {
      await ApiService.verifyRazorpayPayment(
        parcelId: widget.parcelId,
        razorpayOrderId: res.orderId ?? '',
        razorpayPaymentId: res.paymentId ?? '',
        razorpaySignature: res.signature ?? '',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SendProcessingOrderScreen(
            parcelId: widget.parcelId,
          ),
        ),
      );
    } catch (e) {
      setState(() => paying = false);
      _showError('Payment verification failed');
    }
  }

  // ===============================
  // PAYMENT ERROR
  // ===============================
  void _onError(PaymentFailureResponse res) {
    InactivityController().resumeAfterPayment();
    _paymentLaunched = false;
    setState(() => paying = false);
    _showError('Payment failed');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SUMMARY', style: AppText.titleXL),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.onSurface,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'BACK',
                    style: TextStyle(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            _row('From', widget.fromLocation),
            _row('To', widget.toAddress),
            _row('Service', widget.courierName),
            _row('ETA', widget.estimatedDays),

            const Divider(height: 40),

            _row('Delivery', '₹${widget.deliveryCost}'),
            _row('Locker', '₹${widget.lockerCost}'),

            const Divider(height: 40),

            _row('TOTAL', '₹$totalCost', highlight: true),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 68,
              child: ElevatedButton(
                onPressed: (paying || _paymentLaunched) ? null : _payAndContinue,
                child: paying
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text('PAY & CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.muted),
          Text(
            value,
            style: highlight
                ? AppText.titleL.copyWith(color: AppColors.primary)
                : AppText.body,
          ),
        ],
      ),
    );
  }
}