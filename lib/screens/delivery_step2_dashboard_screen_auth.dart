import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'delivery_step3_locker_opening_screen.dart';
import 'delivery_self_auth_phone_screen.dart';

class DeliveryStep2DashboardScreenAuth extends StatefulWidget {
  const DeliveryStep2DashboardScreenAuth({
    super.key,
    required this.recipientPhone,
    required this.senderPhone,
  });

  final String recipientPhone;
  final String senderPhone;

  @override
  State<DeliveryStep2DashboardScreenAuth> createState() =>
      _DeliveryStep2DashboardScreenAuthState();
}

class _DeliveryStep2DashboardScreenAuthState
    extends State<DeliveryStep2DashboardScreenAuth> {
  // ================= STATE =================

  Map<String, bool>? sizes;
  String? selectedSize;

  List<Map<String, dynamic>> couriers = [];
  Map<String, dynamic>? selectedCourier;

  bool loadingCourier = false;

  @override
  void initState() {
    super.initState();
    _loadSizes();
    _loadCourier();
  }

  // ================= API =================

  Future<void> _loadSizes() async {
    sizes = await ApiService.getAvailableSizes(ApiService.lockerId);
    setState(() {});
  }

  Future<void> _loadCourier() async {
    setState(() {
      loadingCourier = true;
      couriers.clear();
      selectedCourier = null;
    });

    try {
      final res = await ApiService.findPartners(
        phone: widget.senderPhone,
      );

      setState(() {
        couriers = res;
        if (couriers.isNotEmpty) {
          selectedCourier = couriers.first;
        }
        loadingCourier = false;
      });
    } catch (_) {
      loadingCourier = false;
    }
  }

  Future<void> _unlock() async {
    await ApiService.deliveryDropoff(
      recipientPhone: widget.recipientPhone,
  deliveryPhone: widget.senderPhone,
  partnerId: selectedCourier!['_id'],
  size: selectedSize!,
  hours: 1,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryStep3LockerOpeningScreen(
          recipientPhone: widget.recipientPhone,
        ),
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (sizes == null) {
      return Scaffold(
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
            _header(context),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _sizePanel()),
                  const SizedBox(width: 32),
                  Expanded(child: _courierPanel()),
                  const SizedBox(width: 32),
                  Expanded(child: _summaryPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DELIVERY DROP.', style: AppText.titleXL),
            const SizedBox(height: 6),
            Text('FOR ${widget.recipientPhone}', style: AppText.muted),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DeliverySelfAuthPhoneScreen(
                  recipientPhone: widget.recipientPhone,
                ),
              ),
            );
          },
          icon: const Icon(Icons.arrow_back),
          label: Text('BACK'),
        ),
      ],
    );
  }

  // ================= LEFT : SIZE =================

  Widget _sizePanel() {
    return _panel(
      title: 'SIZE.',
      child: Column(
        children: [
          Expanded(child: _sizeTile('small')),
          const SizedBox(height: 16),
          Expanded(child: _sizeTile('medium')),
          const SizedBox(height: 16),
          Expanded(child: _sizeTile('large')),
        ],
      ),
    );
  }

  Widget _sizeTile(String size) {
    final enabled = sizes![size] == true;
    final selected = selectedSize == size;

    return _selectableCard(
      selected: selected,
      onTap: enabled
          ? () => setState(() => selectedSize = size)
          : () {},
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Center(
          child: Text(
            size.toUpperCase(),
            style: AppText.titleL.copyWith(
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ================= MIDDLE : COURIER =================

  Widget _courierPanel() {
    return _panel(
      title: 'COURIER SERVICES.',
      child: loadingCourier
          ? Center(child: CircularProgressIndicator())
          : couriers.isEmpty
              ? Center(
                  child: Text(
                    'NO COURIERS FOUND',
                    style: AppText.muted,
                  ),
                )
              : ListView.separated(
                  itemCount: couriers.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final c = couriers[i];
                    final selected =
                        selectedCourier?['id'] == c['id'];

                    return _selectableCard(
                      selected: selected,
                      onTap: () =>
                          setState(() => selectedCourier = c),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          c['name'],
                          style: AppText.titleM.copyWith(
                            color: selected
                                ? AppColors.primary
                                : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // ================= RIGHT : SUMMARY =================

  Widget _summaryPanel() {
    final canUnlock =
        selectedSize != null && selectedCourier != null;

    return _panel(
      title: 'SUMMARY.',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text('TOTAL', style: AppText.muted),
          const SizedBox(height: 16),
          Text(
            'FREE',
            style: AppText.titleXL.copyWith(
              fontSize: 42,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: canUnlock ? _unlock : null,
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
