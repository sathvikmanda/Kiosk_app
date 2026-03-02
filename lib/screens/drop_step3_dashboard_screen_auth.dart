import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../models/drop_mode.dart';
import '../services/api_service.dart';
import 'drop_step4_payment_screen_auth.dart';
import 'locker_opened_screen.dart';

const Color navy = Color(0xFF1E293B); 

class DropStep3DashboardScreenAuth extends StatefulWidget {
  const DropStep3DashboardScreenAuth({
    super.key,
    required this.senderPhone,
    required this.recipientPhone,
    required this.dropMode,
    required this.helpId,
  });
final String helpId;

  final String senderPhone;
  final String recipientPhone;
  final DropMode dropMode;

  @override
  State<DropStep3DashboardScreenAuth> createState() =>
      _DropStep3DashboardScreenAuthState();
}

class _DropStep3DashboardScreenAuthState
    extends State<DropStep3DashboardScreenAuth> {
  // ================= STATE =================

  bool isLoading = true;

  bool isCourierMode = false;
  bool findingPartners = false;
  bool hasCourierPartners = false;

  Map<String, bool> sizeAvailability = {
    'Small': false,
    'Medium': false,
    'Large': false,
  };

  String selectedSize = 'Small';
  int selectedHours = 2;
  int hourlyRate = 5;

  List<dynamic> courierPartners = [];
  Map<String, dynamic>? selectedCourier;

  int get prepaidAmount => hourlyRate * selectedHours;
  int get dropCharge => 10;
  int get total => prepaidAmount + dropCharge;

  bool get canUnlock =>
      selectedSize.isNotEmpty && selectedCourier != null;

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
    _checkCourierAvailability(); // 👈 silent check
  }

  // ================= API =================

  Future<void> _fetchAvailability() async {
    try {
      final res = await ApiService.getAvailableSizes(ApiService.lockerId);

      setState(() {
        sizeAvailability = {
          'Small': res['small'] ?? false,
          'Medium': res['medium'] ?? false,
          'Large': res['large'] ?? false,
        };

        if (!sizeAvailability[selectedSize]!) {
          selectedSize = sizeAvailability.entries
              .firstWhere((e) => e.value)
              .key;
          hourlyRate = _rateForSize(selectedSize);
        }

        isLoading = false;
      });
    } catch (_) {
      isLoading = false;
    }
  }

  Future<void> _checkCourierAvailability() async {
    try {
      final res =
          await ApiService.findPartners(phone: widget.senderPhone);

      setState(() {
        hasCourierPartners = res.isNotEmpty;
      });
    } catch (_) {
      hasCourierPartners = false;
    }
  }

  Future<void> _loadCourierPartners() async {
    setState(() {
      findingPartners = true;
      isCourierMode = true;
      selectedCourier = null;
    });

    try {
      final res =
          await ApiService.findPartners(phone: widget.senderPhone);

      setState(() {
        courierPartners = res;
        findingPartners = false;

        if (res.isEmpty) {
          isCourierMode = false;
        }
      });
    } catch (_) {
      setState(() {
        findingPartners = false;
        isCourierMode = false;
      });
    }
  }

  int _rateForSize(String size) {
    switch (size) {
      case 'Small':
        return 5;
      case 'Medium':
        return 10;
      case 'Large':
        return 20;
      default:
        return 5;
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _sizePanel()),
                  const SizedBox(width: 32),

                  if (!isCourierMode) ...[
                    Expanded(child: _reservationPanel()),
                    const SizedBox(width: 32),
                    Expanded(child: _summaryPanel()),
                  ] else ...[
                    Expanded(child: _courierListPanel()),
                    const SizedBox(width: 32),
                    Expanded(child: _courierSummaryPanel()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCourierMode ? 'DROP AS COURIER.' : 'PERSONAL DROP.',
              style: AppText.titleXL,
            ),
            const SizedBox(height: 6),
            Text(
              'FOR ${widget.recipientPhone}',
              style: AppText.muted,
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('BACK'),
        ),
      ],
    );
  }

  // ================= SIZE =================

  Widget _sizePanel() {
    return _panel(
      title: 'SIZE.',
      child: Column(
        children: [
          Expanded(child: _sizeTile('Small', 5)),
          const SizedBox(height: 16),
          Expanded(child: _sizeTile('Medium', 10)),
          const SizedBox(height: 16),
          Expanded(child: _sizeTile('Large', 20)),
        ],
      ),
    );
  }

  Widget _sizeTile(String size, int rate) {
    final selected = selectedSize == size;
    final available = sizeAvailability[size] == true;

    return SizedBox(
      width: double.infinity,
      child: _selectableCard(
        selected: selected,
        onTap: !available
            ? () {}
            : () {
                setState(() {
                  selectedSize = size;
                  hourlyRate = rate;
                });
              },
        child: Opacity(
          opacity: available ? 1.0 : 0.35,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(size.toUpperCase(), style: AppText.titleL),
              const SizedBox(height: 10),
              Text(
                available ? '₹$rate / hour' : 'NOT AVAILABLE',
                style: AppText.body.copyWith(
                  color:
                      available ? AppColors.primary : Colors.redAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= PERSONAL =================

Widget _reservationPanel() {
  final options = [2, 4, 8, 24, 72];

  return _panel(
    title: 'RESERVATION.',
    child: Column(
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: options.map(_durationTile).toList(),
        ),

        const Spacer(),

        if (hasCourierPartners)
          SizedBox(
            width: double.infinity,
            height: 86,
            child: ElevatedButton.icon(
              onPressed: _loadCourierPartners,
              style: ElevatedButton.styleFrom(
                backgroundColor: navy, // 🟧 ORANGE
                foregroundColor: Colors.white,      // 🤍 ICON + TEXT
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              icon: const Icon(
                Icons.local_shipping_rounded,
                size: 42,
              ),
              label: Text(
                'DROP AS COURIER',
                style: AppText.titleM.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}



  Widget _durationTile(int hours) {
    final selected = selectedHours == hours;
    final label =
        hours < 24 ? '${hours}H' : hours == 24 ? '24H' : '3D';

    return SizedBox(
      width: 130,
      height: 110,
      child: _selectableCard(
        selected: selected,
        onTap: () => setState(() => selectedHours = hours),
        child: Center(
          child: Text(
            label,
            style: AppText.titleL.copyWith(
              fontSize: 32,
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ================= COURIER =================

  Widget _courierListPanel() {
    return _panel(
      title: 'COURIER SERVICES.',
      child: findingPartners
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: courierPartners.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final p = courierPartners[i];
                final selected = selectedCourier == p;

                return _selectableCard(
                  selected: selected,
                  onTap: () {
                    setState(() {
                      selectedCourier = p;
                    });
                  },
                  child: ListTile(
                    title:
                        Text(p['name'], style: AppText.titleM),
                  ),
                );
              },
            ),
    );
  }

Widget _courierSummaryPanel() {
  return _panel(
    title: 'SUMMARY.',
    child: Column(
      children: [
        _summaryRow('Drop Charge', 'FREE'),
        const SizedBox(height: 16),
        _summaryRow('Prepaid Time', 'FREE'),
        const Divider(height: 32),
        _summaryRow('TOTAL.', 'FREE', highlight: true),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: !canUnlock
                ? null
                : () async {
                    try {
                      final partnerId = selectedCourier?['id'];
                      if (partnerId == null) return;

                      final result =
                          await ApiService.deliveryDropoff(
                       recipientPhone: widget.recipientPhone,
                          deliveryPhone: widget.senderPhone,
                          partnerId: partnerId,
                          size: selectedSize.toLowerCase(),
                          hours: selectedHours,
                      );

                      final accessCode = result['accessCode'];
                      if (accessCode == null) {
                        throw Exception(
                            'accessCode missing in API response');
                      }

                      if (!mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LockerOpenedScreen(
                            accessCode: accessCode,
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Failed to unlock locker'),
                        ),
                      );
                    }
                  },
            child: Text(
              'UNLOCK LOCKER',
              style: AppText.titleM.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  // ================= SUMMARY =================

  Widget _summaryPanel() {
    return _panel(
      title: 'SUMMARY.',
      child: Column(
        children: [
          _summaryRow('Drop Charge', '₹$dropCharge'),
          const SizedBox(height: 16),
          _summaryRow('Prepaid Time', '₹$prepaidAmount'),
          const Divider(height: 32),
          _summaryRow('TOTAL.', '₹$total', highlight: true),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 84,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DropStep4PaymentScreenAuth(
                      senderPhone: widget.senderPhone,
                      recipientPhone: widget.recipientPhone,
                      size: selectedSize,
                      hours: selectedHours,
                      ratePerHour: hourlyRate,
                      dropCharge: dropCharge,
                      helpId: widget.helpId,
                    ),
                  ),
                );
              },
              child: Text(
                'CONTINUE',
                style: AppText.titleM.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.muted),
        Text(
          value,
          style: AppText.titleL.copyWith(
            fontSize: highlight ? 34 : 18,
            color: highlight
                ? AppColors.primary
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ================= COMMON =================

  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.titleL),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _selectableCard({
    required bool selected,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? AppColors.primary.withOpacity(0.22)
          : AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Colors.white12,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: child,
        ),
      ),
    );
  }
}
