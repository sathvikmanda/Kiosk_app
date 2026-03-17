import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/inactivity_controller.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final int amount;
  final String backendBaseUrl;
  final String razorpayKey;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.backendBaseUrl,
    required this.razorpayKey,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    _openCheckout();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _openCheckout() {
    var options = {
      'key': widget.razorpayKey,
      'amount': widget.amount,
      'currency': 'INR',
      'order_id': widget.orderId,
      'name': 'Drop Point',
      'description': 'Locker Payment',
      'timeout': 120,
      'prefill': {
        'contact': '',
        'email': '',
      },
      'theme': {
        'color': '#FF7A00',
      }
    };

    try {
      InactivityController().pauseForPayment();
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay error: $e');
    }
  }

  // ================= HANDLERS =================

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    InactivityController().resumeAfterPayment();
    setState(() => _loading = true);

    final verified = await _verifyPayment(
      paymentId: response.paymentId!,
      signature: response.signature!,
    );

    setState(() => _loading = false);

    if (verified) {
      Navigator.pop(context, true); // ✅ SUCCESS TO SOURCE
    } else {
      _showError('Payment verification failed');
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    InactivityController().resumeAfterPayment();
    Navigator.pop(context, false);
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }

  // ================= BACKEND VERIFICATION =================

  Future<bool> _verifyPayment({
    required String paymentId,
    required String signature,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${widget.backendBaseUrl}/verify-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_order_id': widget.orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('Verification error: $e');
    }
    return false;
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : const Text(
                'Opening Payment Gateway...',
                style: TextStyle(fontSize: 18),
              ),
      ),
    );
  }
}
