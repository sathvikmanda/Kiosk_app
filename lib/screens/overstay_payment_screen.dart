import 'package:flutter/material.dart';
import '../core/inactivity_controller.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'locker_opened_screen.dart';
import 'kiosk_home_screen.dart';

// ===============================
// DATE FORMATTER (SAFE FOR KIOSK)
// ===============================
String formatDateTime(String isoString) {
  try {
    final dt = DateTime.parse(isoString).toLocal();
    return DateFormat('dd MMM yyyy, h:mm a').format(dt);
  } catch (_) {
    return isoString;
  }
}
String extractIsoDate(dynamic value) {
  if (value == null) return '';

  // If backend already sends ISO string
  if (value is String) return value;

  // If Mongo-style { "$date": "..." }
  if (value is Map && value['\$date'] != null) {
    return value['\$date'].toString();
  }

  return '';
}


class OverstayPaymentScreen extends StatefulWidget {
  const OverstayPaymentScreen({
    super.key,
    required this.parcelId,
    required this.amount,
    required this.usageSummary,
    required this.parcelRaw,
  });

  final String parcelId;
  final int amount;
  final Map<String, dynamic> usageSummary;
  final Map<String, dynamic> parcelRaw;

  @override
  State<OverstayPaymentScreen> createState() =>
      _OverstayPaymentScreenState();
}

class _OverstayPaymentScreenState
    extends State<OverstayPaymentScreen> {
  late Razorpay _razorpay;
  bool paying = false;
  bool _paymentLaunched = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(
        Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(
        Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ===============================
  // PAYMENT INIT
  // ===============================
  Future<void> _startPayment() async {
    if (_paymentLaunched) return;
    _paymentLaunched = true;
    setState(() {
      paying = true;
      error = null;
    });
final int totalInPaise = widget.amount ;
    try {
      final order =
          await ApiService.createRazorpayOrder(
        parcelId: widget.parcelId,
        amount: totalInPaise,
      );

      if (order == null ||
          order['key'] == null ||
          order['orderId'] == null ||
          order['amount'] == null ||
          order['amount'] <= 0) {
        throw Exception('Invalid payment order');
      }

      InactivityController().pauseForPayment();
      _razorpay.open({
        'key': order['key'],
        'amount': order['amount'],
        'order_id': order['orderId'],
        'name': 'DropPoint',
        'description': 'Overstay Charges',
        'prefill': {'contact': '9999999999'},
      });
    } catch (e) {
      setState(() {
        paying = false;
        error =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ===============================
  // PAYMENT CALLBACKS
  // ===============================
  Future<void> _onSuccess(
      PaymentSuccessResponse res) async {
    InactivityController().resumeAfterPayment();
    try {
      final result =
          await ApiService.verifyOverstayPayment(
        parcelId: widget.parcelId,
        razorpayOrderId: res.orderId!,
        razorpayPaymentId: res.paymentId!,
        razorpaySignature: res.signature!,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LockerOpenedScreen(
            accessCode: result['accessCode'],
          ),
        ),
      );
    } catch (e) {
      setState(() {
        paying = false;
        error =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onPaymentError(
      PaymentFailureResponse res) {
    InactivityController().resumeAfterPayment();
    _paymentLaunched = false;
    setState(() {
      paying = false;
      error = 'Payment failed or cancelled';
    });
  }

  // ===============================
  // UI HELPERS
  // ===============================
  Widget _row(String label, String value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.muted),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // OVERSTAY SUMMARY (USER-FACING)
  // ===============================
Widget _overstaySummaryCard() {
  final u = widget.usageSummary;

  final size =
      u['size']?.toString().toUpperCase() ?? '-';
  final int extraHours = u['extraHours'] ?? 0;
  final int rate = u['ratePerHour'] ?? 0;

  final storedAt = u['storedAt'] ?? '';
  final freeUntil = u['freeUntil'] ?? '';
  final now = u['now'] ?? '';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 28,
      vertical: 20,
    ),
    decoration: BoxDecoration(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECTION TITLE
        Text(
          'OVERSTAY DETAILS',
          style: AppText.muted.copyWith(
            letterSpacing: 1.4,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        // CONTEXT
        _row('Locker Size', size),

        const SizedBox(height: 20),
        Divider(color: AppColors.subtle),

        // TIME DETAILS
        const SizedBox(height: 20),
        _row('Stored On', formatDateTime(storedAt)),
        _row(
            'Paid Storage Until',
            formatDateTime(freeUntil)),
        _row(
            'Payment Time',
            formatDateTime(now)),

        const SizedBox(height: 20),
        Divider(color: AppColors.subtle),

        // BILLING DETAILS
        const SizedBox(height: 20),
        _row(
            'Extra Time Used',
            '$extraHours hours'),
        _row(
            'Rate per Hour',
            '₹$rate'),

        const SizedBox(height: 28),

        // CALCULATION (HIGHLIGHT)
        
      ],
    ),
  );
}


  // ===============================
  // BUILD
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(30,30,30,26),
            child: Column(
              children: [
                Text('PAYMENT REQUIRED',
                    style: AppText.titleXL),
                const SizedBox(height: 16),
                Text(
                  'Your parcel exceeded the paid storage time.\nPlease review the details below.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                      color:
                          AppColors.inactive),
                ),
                const SizedBox(height: 20),

                Text(
                  '₹${widget.amount}',
                  style: AppText.titleXL
                      .copyWith(
                    color: AppColors.primary,
                    fontSize: 52,
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
  child: Center(
    child: _overstaySummaryCard(),
  ),
),


                if (error != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                            bottom: 12),
                    child: Text(
                      error!,
                      style: AppText.body
                          .copyWith(
                              color: Colors
                                  .redAccent),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed:
                        (paying || _paymentLaunched) ? null : _startPayment,
                    child: paying
                        ? const CircularProgressIndicator(
                            color:
                                Colors.black)
                        : Text(
                            'PAY & UNLOCK',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // ================= BACK BUTTON =================
          Positioned(
            top: 24,
            right: 24,
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(14),
              onTap: paying
                  ? null
                  : () {
                      Navigator
                          .pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const KioskHomeScreen(),
                        ),
                        (_) => false,
                      );
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.onSurface,
                    width: 2,
                  ),
                ),
                child: Text(
                  'BACK',
                  style: AppText.body.copyWith(
                    color: AppColors.onSurface,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
