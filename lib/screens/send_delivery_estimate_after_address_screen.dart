import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'send_summary_screen.dart';
import '../services/audio_service.dart';

class SendDeliveryEstimateAfterAddressScreen extends StatefulWidget {
  const SendDeliveryEstimateAfterAddressScreen({
    super.key,
    required this.parcelId,
    required this.phoneNumber,
    required this.fromLocation,
    required this.receiverAddress,
    required this.lockerCost,
  });

  final String parcelId;
  final String phoneNumber;
  final String fromLocation;
  final Map<String, dynamic> receiverAddress;
  final int lockerCost;

  @override
  State<SendDeliveryEstimateAfterAddressScreen> createState() =>
      _SendDeliveryEstimateAfterAddressScreenState();
}

class _SendDeliveryEstimateAfterAddressScreenState
    extends State<SendDeliveryEstimateAfterAddressScreen> {
  // ================= STATE =================

  String selectedCategory = 'cheapest';
  Map<String, dynamic>? selectedCourier;

  List<Map<String, dynamic>> cheapestServices = [];
  List<Map<String, dynamic>> fastestServices = [];

  bool loading = true;
  bool lockingCourier = false;

  int get deliveryCost =>
      selectedCourier == null ? 0 : (selectedCourier!['rate'] as num).round();

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
      Future.delayed(const Duration(milliseconds: 300), () {
    AudioService.play(AudioEvent.selectservice);
  });
    _fetchRates();
  }

  // ================= FETCH RATES =================

  Future<void> _fetchRates() async {
    try {
      final List<dynamic> raw =
          await ApiService.getParcelRates(parcelId: widget.parcelId);

      if (raw.isEmpty) throw Exception('No couriers available');

      final List<Map<String, dynamic>> couriers = raw.map((e) {
        final map = Map<String, dynamic>.from(e);
        return {
          ...map,
          'rate': (map['rate'] as num).toDouble(),
          'estimated_delivery_days':
              int.tryParse(map['estimated_delivery_days'].toString()) ?? 99,
        };
      }).toList();

      final cheapest = [...couriers]
        ..sort((a, b) => a['rate'].compareTo(b['rate']));

      final fastest = [...couriers]
        ..sort((a, b) =>
            a['estimated_delivery_days']
                .compareTo(b['estimated_delivery_days']));

      setState(() {
        cheapestServices = cheapest;
        fastestServices = fastest;
        selectedCategory = 'cheapest';
        selectedCourier = cheapest.first;
        loading = false;
      });
    } catch (e) {
      debugPrint('RATE FETCH ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load delivery estimates')),
        );
      }
      setState(() => loading = false);
    }
  }

  // ================= CONTINUE =================

  Future<void> _onContinue(String toAddress) async {
    if (selectedCourier == null) return;

    setState(() => lockingCourier = true);

    try {
      // 🔥 THIS IS THE ONLY IMPORTANT PART
      await ApiService.selectCourier(
        parcelId: widget.parcelId,
        courierCode: selectedCourier!['courier_company_id'],
      );

      if (!mounted) return;

      // ✅ Navigate ONLY after success
      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => SendSummaryScreen(
        parcelId: widget.parcelId,
      phoneNumber: widget.phoneNumber,
      fromLocation: widget.fromLocation,
      toAddress: toAddress,
      courierName: selectedCourier!['courier_name'],
      estimatedDays: _estimatedDays(),
      deliveryCost: deliveryCost,
      lockerCost: widget.lockerCost,
    ),
  ),
);

    } catch (e) {
      debugPrint('COURIER LOCK ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to lock courier')),
        );
      }
    } finally {
      if (mounted) setState(() => lockingCourier = false);
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final toAddress =
        '${widget.receiverAddress['delivery_address']}, '
        '${widget.receiverAddress['delivery_city']} '
        '${widget.receiverAddress['delivery_pincode']}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('DELIVERY ESTIMATE', style: AppText.titleXL),
    OutlinedButton(
      onPressed: () {
        Navigator.pop(context); // ✅ BACK TO ADDRESS DASHBOARD
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white, width: 1.5),
      ),
      child: Text(
        'BACK',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ],
),

            const SizedBox(height: 6),
            Text(
              'Prices shown are estimates. Final price will be confirmed.',
              style: AppText.body.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),

            _addressCard(toAddress),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _categoryButton('CHEAPEST')),
                const SizedBox(width: 16),
                Expanded(child: _categoryButton('FASTEST')),
              ],
            ),

            const SizedBox(height: 24),

            Expanded(
              child: loading
                  ? Center(child: CircularProgressIndicator())
                  : _serviceList(),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 68,
              child: ElevatedButton(
                onPressed:
                    (selectedCourier == null || lockingCourier)
                        ? null
                        : () => _onContinue(toAddress),
                child: lockingCourier
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text('CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _addressCard(String address) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(address, style: AppText.body)),
        ],
      ),
    );
  }

  Widget _categoryButton(String label) {
    final value = label.toLowerCase();
    final selected = selectedCategory == value;

    final services =
        value == 'cheapest' ? cheapestServices : fastestServices;

    return InkWell(
      onTap: services.isEmpty
          ? null
          : () {
              setState(() {
                selectedCategory = value;
                selectedCourier = services.first;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white12,
            width: 2,
          ),
        ),
        child: Center(child: Text(label, style: AppText.titleM)),
      ),
    );
  }

  Widget _serviceList() {
    final services =
        selectedCategory == 'cheapest' ? cheapestServices : fastestServices;

    if (services.isEmpty) {
      return Center(
        child: Text('No services available', style: AppText.muted),
      );
    }

    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (_, i) {
        final s = services[i];
        final selected =
            selectedCourier?['courier_name'] == s['courier_name'];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => selectedCourier = s),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.white12,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(s['courier_name'], style: AppText.body),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${s['estimated_delivery_days']} Days',
                      style: AppText.muted,
                    ),
                  ),
                  Text(
                    '₹${s['rate']}',
                    style: AppText.titleM.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _estimatedDays() {
    if (selectedCourier == null) return '-';
    return '${selectedCourier!['estimated_delivery_days']} Days';
  }
}
