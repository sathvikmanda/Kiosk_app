import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../utils/immersive_mode.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/complaint_session.dart';
import '../services/api_service.dart';

import 'store_step2_phone_screen.dart';
import 'store_step5_locker_opening_screen.dart';

class StoreStep4PaymentScreen extends StatefulWidget {
  const StoreStep4PaymentScreen({
    super.key,
    required this.phoneNumber,
    required this.size,
    required this.hours,
    required this.ratePerHour,
required this.sessionId,

    required this.helpId,
  });

  final String phoneNumber;
  final String size;
  final int hours;
  final int ratePerHour;
final String sessionId;

final String helpId;


  @override
  State<StoreStep4PaymentScreen> createState() =>
      _StoreStep4PaymentScreenState();
}

class _StoreStep4PaymentScreenState
    extends State<StoreStep4PaymentScreen> {
  late Razorpay _razorpay;

  bool isLoading = false;

  String? parcelId;
  int? backendAmountPaise;
  int? backendAmountRupees;

  // ================= DISPLAY ONLY =================
  int get prepaid => widget.hours * widget.ratePerHour;
  int get subtotal => prepaid ;
  int get total => subtotal;

  String? get helpId => ComplaintSession.helpId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(
        Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(
        Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ================= START PAYMENT =================

  Future<void> _startPayment() async {
    // 🔥 Make Razorpay feel fullscreen
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    if (widget.hours <= 0) {
    _showError('Invalid duration selected');
    return;
  }

  if (widget.hours > 168) {
    _showError('Maximum storage duration exceeded');
    return;
  }

    setState(() => isLoading = true);

    try {
      final data = await ApiService.createDropoffOrder(
        phone: widget.phoneNumber,
        size: widget.size,
        hours: widget.hours,
        helpId: widget.helpId,
        sessionId: widget.sessionId,
      );

      final orderId = data['orderId'];
      final amount = data['amount'];
      final key = data['razorpayKeyId'];

      if (orderId == null || amount == null || key == null) {
        _showError('Payment order creation failed');
        return;
      }

      parcelId = data['parcelId'];
      backendAmountPaise = amount;
      backendAmountRupees = (amount / 100).round();

      _razorpay.open({
        'key': key,
        'order_id': orderId,
        'amount': amount,
        'currency': 'INR',
        'name': 'DropPoint',
        'description': 'Locker Storage',
        'prefill': {
          'contact': widget.phoneNumber,
          'email': 'support@droppoint.in',
        },
        'theme': {
          'color': '#FF7A00',
        },
        // ✅ Optional: kiosk-friendly
        'method': {
          'upi': true,
          'card': false,
          'netbanking': false,
          'wallet': false,
        },
      });
    } catch (_) {
      _showError('Payment initialization failed');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ================= PAYMENT CALLBACK =================

  Future<void> _onPaymentSuccess(
      PaymentSuccessResponse res) async {
    // 🔥 Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    if (res.orderId == null ||
        res.signature == null ||
        parcelId == null) {
      _showError('Payment verification failed');
      return;
    }

    try {
      final result = await ApiService.verifyPayment(
        orderId: res.orderId!,
        paymentId: res.paymentId!,
        signature: res.signature!,
        parcelId: parcelId!,
         helpId: helpId,
      );
      ImmersiveMode.enable();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StoreStep5LockerOpeningScreen(
            phoneNumber: widget.phoneNumber,
            accessCode: result['accessCode'],
            helpId: widget.helpId,
          ),
        ),
      );
    } catch (_) {
      _showError('Payment verification failed');
    }
  }

  void _onPaymentError(PaymentFailureResponse res) {
    ImmersiveMode.enable();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    _showError('Payment cancelled');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 🔥 FIX OVERFLOW
      backgroundColor: AppColors.background,
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
          children: const [
            Text('STORING LUGGAGE.', style: AppText.titleXL),
            SizedBox(height: 6),
            Text(
              'STEP 4 OF 4: PAYMENT SUMMARY',
              style: AppText.muted,
            ),
          ],
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back),
          label: const Text('BACK'),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => StoreStep2PhoneScreen(
                  size: widget.size,
                  hours: widget.hours,
                  ratePerHour: widget.ratePerHour,
sessionId: widget.sessionId,
                  helpId: widget.helpId,
                ),
              ),
            );
          },
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
          const SizedBox(height: 16),
          const Divider(),
          _row('Prepaid Storage', '₹$prepaid'),

          const Divider(height: 32),
          _row(
            'TOTAL PAYABLE',
            '₹${backendAmountRupees ?? total}',
            highlight: true,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 68,
            child: ElevatedButton(
              onPressed: isLoading ? null : _startPayment,
              child: isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white)
                  : const Text('PAY & CONTINUE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body),
          Text(
            value,
            style: AppText.titleL.copyWith(
              fontSize: highlight ? 32 : 18,
              color:
                  highlight ? AppColors.primary : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
