import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'send_delivery_estimate_after_address_screen.dart';
import 'send_step4_link_sent_screen.dart';
import 'send_step1_phone_screen.dart';
import '../services/audio_service.dart'; // ✅ ADDED

class SendAddressDashboardScreen extends StatefulWidget {
  const SendAddressDashboardScreen({
    super.key,
    required this.phoneNumber,
    required this.fromLocation,
    required this.lockerSize,
    required this.lockerCost,
  });

  final String phoneNumber;
  final String fromLocation;
  final String lockerSize; // small | medium | large
  final int lockerCost;

  @override
  State<SendAddressDashboardScreen> createState() =>
      _SendAddressDashboardScreenState();
}

class _SendAddressDashboardScreenState
    extends State<SendAddressDashboardScreen> {
  late Future<List<Map<String, dynamic>>> receiversFuture;
  Map<String, dynamic>? selectedReceiver;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
      Future.delayed(const Duration(milliseconds: 300), () {
    AudioService.play(AudioEvent.selectdornewd);
  });
    receiversFuture = ApiService.fetchSavedReceivers(
      senderPhone: widget.phoneNumber,
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 HEADER WITH BACK BUTTON (ADDED ONLY)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SELECT DELIVERY ADDRESS', style: AppText.titleXL),
             OutlinedButton(
  onPressed: () {
    Navigator.pop(context);
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

            const SizedBox(height: 32),

            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 7, child: _leftPanel()),
                  const SizedBox(width: 32),
                  Expanded(flex: 3, child: _rightPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LEFT PANEL =================

  Widget _leftPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saved Addresses', style: AppText.titleL),
          const SizedBox(height: 24),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: receiversFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final receivers = snap.data ?? [];

                if (receivers.isEmpty) {
                  return _emptyState();
                }

                return ListView(
                  children: [
                    ...receivers.map(_addressTile),
                    const SizedBox(height: 20),
                    _addNewAddressCard(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= EMPTY STATE =================

  Widget _emptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.location_off,
          size: 64,
          color: Colors.white38,
        ),
        const SizedBox(height: 20),
        Text(
          'No saved delivery addresses',
          style: AppText.titleM,
        ),
        const SizedBox(height: 8),
        Text(
          'Add a new address to continue',
          style: AppText.body.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 32),
        _addNewAddressCard(),
      ],
    );
  }

  // ================= ADDRESS TILE =================

  Widget _addressTile(Map<String, dynamic> r) {
    final selected = selectedReceiver?['_id'] == r['_id'];

    return GestureDetector(
      onTap: () => setState(() => selectedReceiver = r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white12,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  r['receiverName'] ?? 'Receiver',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                if (r['receiverPhone'] != null)
                  Text(
                    '  •  ${r['receiverPhone']}',
                    style: AppText.body.copyWith(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${r['delivery_address']}, '
              '${r['delivery_city']} '
              '${r['delivery_pincode']}',
              style: AppText.body.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ADD NEW ADDRESS =================

  Widget _addNewAddressCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SendStep4LinkSentScreen(
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.6),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.add, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'A link will be sent to your WhatsApp to add a new address',
                style: AppText.body.copyWith(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= RIGHT PANEL =================

  Widget _rightPanel() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next Step', style: AppText.titleM),
          const SizedBox(height: 12),
          Text(
            'Select an address to view delivery estimates.',
            style: AppText.body.copyWith(color: Colors.white70),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 68,
            child: ElevatedButton(
              onPressed:
                  (selectedReceiver == null || _loading)
                      ? null
                      : _onContinue,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text('CONTINUE'),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CONTINUE =================
Future<void> _onContinue() async {
  setState(() => _loading = true);

  try {
    final res = await ApiService.createParcel(
      senderPhone: widget.phoneNumber,
      receiver: selectedReceiver!,
      size: widget.lockerSize,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendDeliveryEstimateAfterAddressScreen(
          parcelId: res['parcelId'],
          phoneNumber: widget.phoneNumber,
          fromLocation: widget.fromLocation,
          receiverAddress: selectedReceiver!,
          lockerCost: widget.lockerCost,
        ),
      ),
    );
  } catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to create parcel')),
    );
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

}