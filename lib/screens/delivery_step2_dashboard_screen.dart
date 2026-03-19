import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'delivery_step3_locker_opening_screen.dart';

enum DeliveryStep { enterPhone, chooseCourier }

class DeliveryStep2DashboardScreen extends StatefulWidget {
  const DeliveryStep2DashboardScreen({
    super.key,
    required this.recipientPhone,
    this.prefilledAgentPhone,
  });

  final String recipientPhone;
  final String? prefilledAgentPhone;

  @override
  State<DeliveryStep2DashboardScreen> createState() =>
      _DeliveryStep2DashboardScreenState();
}

class _DeliveryStep2DashboardScreenState
    extends State<DeliveryStep2DashboardScreen> {
  // ================= STATE =================

  bool loadingSizes = true;
  Map<String, bool> sizeAvailability = {};

  String? selectedSize;

  // ================= AGENT =================

  final StringBuffer agentPhone = StringBuffer();
  DeliveryStep step = DeliveryStep.enterPhone;

  bool loadingPartners = false;
  List<Map<String, dynamic>> partners = [];
  Map<String, dynamic>? selectedPartner;

  @override
  void initState() {
    super.initState();
    _loadSizes();

    if (widget.prefilledAgentPhone != null &&
        widget.prefilledAgentPhone!.length == 10) {
      agentPhone.write(widget.prefilledAgentPhone);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _findPartners();
      });
    }
  }

  // ================= API =================

  Future<void> _loadSizes() async {
    final res = await ApiService.getAvailableSizes(ApiService.lockerId);

    setState(() {
      sizeAvailability = res;
      loadingSizes = false;

      if (res['small'] == true) selectedSize = 'small';
      else if (res['medium'] == true) selectedSize = 'medium';
      else if (res['large'] == true) selectedSize = 'large';
    });
  }

  Future<void> _findPartners() async {
    setState(() {
      loadingPartners = true;
      partners.clear();
      selectedPartner = null;
    });

    final res = await ApiService.findPartners(
      phone: agentPhone.toString(),
    );

    setState(() {
      partners = List<Map<String, dynamic>>.from(res);
      loadingPartners = false;
      step = DeliveryStep.chooseCourier;
    });
  }

  Future<void> _unlock() async {
    await ApiService.deliveryDropoff(
   recipientPhone: widget.recipientPhone,
  deliveryPhone: agentPhone.toString(),
  partnerId: selectedPartner!['_id'],
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
    if (loadingSizes) {
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
            _header(),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _sizePanel()),
                  const SizedBox(width: 32),

                  if (step == DeliveryStep.enterPhone) ...[
                    Expanded(flex: 2, child: _phonePanel()),
                  ] else ...[
                    Expanded(child: _courierPanel()),
                    const SizedBox(width: 32),
                    Expanded(child: _summaryPanel()),
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
            Text('DELIVERY DROP.', style: AppText.titleXL),
            const SizedBox(height: 6),
            Text('FOR ${widget.recipientPhone}', style: AppText.muted),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: Text('BACK'),
        ),
      ],
    );
  }

  // ================= SIZE PANEL =================

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
    final enabled = sizeAvailability[size] == true;
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

  // ================= PHONE (MIDDLE + RIGHT) =================

  Widget _phonePanel() {
    return _panel(
      title: 'AGENT NUMBER.',
      child: Column(
        children: [
          Container(
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              agentPhone.isEmpty ? '' : agentPhone.toString(),
              style: AppText.titleXL,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: _numpad()),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed:
                  agentPhone.length == 10 ? _findPartners : null,
              child: Text('FIND COURIERS'),
            ),
          ),
        ],
      ),
    );
  }

  // ================= COURIER PANEL =================

  Widget _courierPanel() {
    return _panel(
      title: 'COURIER SERVICES.',
      child: loadingPartners
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: partners.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final p = partners[i];
                final selected =
                    selectedPartner?['id'] == p['id'];

                return _selectableCard(
                  selected: selected,
                  onTap: () =>
                      setState(() => selectedPartner = p),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      p['name'],
                      style: AppText.titleM,
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ================= NUMPAD =================

  Widget _numpad() {
    final keys = [
      '1','2','3',
      '4','5','6',
      '7','8','9',
      'CLEAR','0','⌫'
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 70,
      ),
      itemBuilder: (_, i) => _key(keys[i]),
    );
  }

  Widget _key(String k) {
    return _selectableCard(
      selected: false,
      onTap: () {
        setState(() {
          if (k == 'CLEAR') {
            agentPhone.clear();
          } else if (k == '⌫') {
            if (agentPhone.isNotEmpty) {
              final cur = agentPhone.toString();
              agentPhone
                ..clear()
                ..write(cur.substring(0, cur.length - 1));
            }
          } else if (agentPhone.length < 10) {
            agentPhone.write(k);
          }
        });
      },
      child: Center(
        child: Text(
          k,
          style: AppText.titleL.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ================= SUMMARY =================

  Widget _summaryPanel() {
    final canUnlock =
        selectedSize != null && selectedPartner != null;

    return _panel(
      title: 'SUMMARY.',
      child: Column(
        children: [
          _row('TOTAL', 'FREE', highlight: true),
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

  Widget _row(String l, String v, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: AppText.muted),
        Text(
          v,
          style: AppText.titleL.copyWith(
            fontSize: highlight ? 34 : 18,
            color:
                highlight ? AppColors.primary : Colors.white,
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
