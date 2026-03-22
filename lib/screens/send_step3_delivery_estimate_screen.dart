import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/inactivity_controller.dart';
import '../services/api_service.dart';
import 'send_step1_phone_screen.dart';
import '../services/audio_service.dart';

class SendStep3DeliveryEstimateScreen extends StatefulWidget {
  const SendStep3DeliveryEstimateScreen({super.key});

  @override
  State<SendStep3DeliveryEstimateScreen> createState() =>
      _SendStep3DeliveryEstimateScreenState();
}

class _SendStep3DeliveryEstimateScreenState
    extends State<SendStep3DeliveryEstimateScreen> {
  static const int pinLength = 6;
  bool get allLockersUnavailable {
  if (availableSizes == null) return false;
  return !(availableSizes!['small'] == true ||
           availableSizes!['medium'] == true ||
           availableSizes!['large'] == true);
}


  final List<String> _pincode = [];
  bool showNumpad = true;

  String selectedCategory = 'cheapest';
  String? selectedService;
  int deliveryCost = 0;

  List<dynamic> cheapestServices = [];
  List<dynamic> fastestServices = [];
  bool loadingEstimates = false;

  // 🔥 LOCKER STATE
  String selectedSize = 'Small';
  int lockerCost = 50;
  Map<String, bool>? availableSizes;
  bool loadingSizes = true;

  int get total => lockerCost + deliveryCost;
  String get lockerSize => selectedSize.toLowerCase();

  @override
  void initState() {
    super.initState();
           Future.delayed(const Duration(milliseconds: 300), () {
    AudioService.play(AudioEvent.deliveryestimate);
  });
    _fetchAvailableSizes();
    
  }

  Future<void> _fetchAvailableSizes() async {
    try {
      final sizes = await ApiService.getAvailableSizes('L00002');

      setState(() {
        availableSizes = sizes;
        loadingSizes = false;

        // 🔒 Auto-correct invalid default selection
        if (!sizes[selectedSize.toLowerCase()]!) {
          if (sizes['small'] == true) {
            selectedSize = 'Small';
            lockerCost = 50;
          } else if (sizes['medium'] == true) {
            selectedSize = 'Medium';
            lockerCost = 80;
          } else if (sizes['large'] == true) {
            selectedSize = 'Large';
            lockerCost = 120;
          }
        }
      });
    } catch (_) {
      loadingSizes = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load locker availability')),
      );
    }
  }

  void _onKeyPress(String value) {
    setState(() {
      if (value == 'Clear') {
        _pincode.clear();
        _resetDelivery();
        showNumpad = true;
        return;
      }

      if (value == '⌫') {
        if (_pincode.isNotEmpty) _pincode.removeLast();
        return;
      }

      if (_pincode.length < pinLength) {
        _pincode.add(value);
      }

      if (_pincode.length == pinLength) {
        showNumpad = false;
        _fetchEstimates();
      }
    });
  }

  void _editPincode() {
    setState(() {
      showNumpad = true;
      _resetDelivery();
    });
  }

  void _resetDelivery() {
    selectedCategory = 'cheapest';
    selectedService = null;
    deliveryCost = 0;
    cheapestServices.clear();
    fastestServices.clear();
  }

  Future<void> _fetchEstimates() async {
    setState(() => loadingEstimates = true);

    try {
      final data = await ApiService.getDeliveryEstimate(
        dropPincode: _pincode.join(),
      );

      final cheapest = data['cheapest'] ?? [];
      final fastest = data['fastest'] ?? [];

      setState(() {
        cheapestServices = cheapest;
        fastestServices = fastest;

        if (cheapest.isNotEmpty) {
          selectedCategory = 'cheapest';
          selectedService = cheapest.first['courier_name'];
          deliveryCost = (cheapest.first['rate'] as num).round();
        }
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch delivery estimates')),
      );
    } finally {
      setState(() => loadingEstimates = false);
    }
  }

  String _selectedEstimatedDays() {
    final services =
        selectedCategory == 'cheapest' ? cheapestServices : fastestServices;

    final match = services.firstWhere(
      (s) => s['courier_name'] == selectedService,
      orElse: () => null,
    );

    if (match == null) return '-';
    return '${match['estimated_delivery_days']} Days';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
        child: Column(
          children: [
            _header(context),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 4, child: _leftPanel()),
                  const SizedBox(width: 32),
                  Expanded(flex: 5, child: _rightPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DELIVERY ESTIMATION', style: AppText.titleXL),
            const SizedBox(height: 6),
            Text(
              'Prices shown are estimates. Final price will be confirmed after address selection.',
              style: AppText.body.copyWith(color: AppColors.inactive),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {
            final helpId = InactivityController().activeHelpId;
            if (helpId != null) {
              ApiService.stopComplaint(helpId); // fire and forget
              InactivityController().activeHelpId = null;
            }
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          label: Text('BACK'),
        ),
      ],
    );
  }

  Widget _leftPanel() {
    final keys = ['1','2','3','4','5','6','7','8','9','Clear','0','⌫'];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ENTER DESTINATION PINCODE', style: AppText.titleL),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: _editPincode,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                pinLength,
                (i) => _digitBox(
                  filled: i < _pincode.length,
                  value: i < _pincode.length ? _pincode[i] : '',
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          Expanded(
            child: showNumpad
                ? GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: keys.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      mainAxisExtent: 64,
                    ),
                    itemBuilder: (_, i) => _key(keys[i]),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _categoryButton('CHEAPEST')),
                          const SizedBox(width: 16),
                          Expanded(child: _categoryButton('FASTEST')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (loadingEstimates)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: CircularProgressIndicator(),
                        )
                      else
                        Expanded(child: _serviceList()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

Widget _rightPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (loadingSizes)
  const Padding(
    padding: EdgeInsets.only(top: 40),
    child: CircularProgressIndicator(),
  )
else if (allLockersUnavailable)
  _noLockerAvailableView()
else ...[
  _sizeTile('Small', 50),
  const SizedBox(height: 12),
  _sizeTile('Medium', 80),
  const SizedBox(height: 12),
  _sizeTile('Large', 120),
],


          const SizedBox(height: 28),

          // Summary — hidden when no lockers available
          if (!allLockersUnavailable) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.subtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SUMMARY', style: AppText.titleM),
                  const SizedBox(height: 16),
                  _summaryRow(
                    'Locker (${selectedSize.toUpperCase()})',
                    '₹$lockerCost',
                  ),
                  const SizedBox(height: 8),
                  _summaryRow(
                    selectedService ?? 'Delivery',
                    selectedService != null ? '₹$deliveryCost' : '-',
                  ),
                  const Divider(height: 28),
                  _summaryRow(
                    'TOTAL',
                    '₹$total',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],

          SizedBox(
            width: double.infinity,
            height: 68,
            child: ElevatedButton(
              onPressed: (selectedService != null && !allLockersUnavailable)

                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SendStep1PhoneScreen(
                            fromLocation: 'Drop Point – T-HUB',
                            toPincode: _pincode.join(),
                            courierName: selectedService!,
                            estimatedDays: _selectedEstimatedDays(),
                            deliveryCost: deliveryCost,
                            lockerCost: lockerCost,
                            lockerSize: lockerSize,
                          ),
                        ),
                      );
                    }
                  : null,
              child: Text('CONTINUE'),
            ),
          ),
        ],
      ),
    );
  }



  Widget _noLockerAvailableView() {
  return Center(
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.6),
          width: 1.5,
        ),
      ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              color: Colors.redAccent,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              'ALL LOCKERS UNAVAILABLE',
              style: AppText.titleM.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please try another location or come back later.',
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
          ],
        ),
      ),
  );
}

Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isTotal ? AppText.titleM : AppText.body),
        Text(
          value,
          style: (isTotal ? AppText.titleL : AppText.body)
              .copyWith(color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _sizeTile(String size, int cost) {
    final key = size.toLowerCase();
    final isAvailable = availableSizes?[key] ?? false;
    final selected = selectedSize == size;

    return InkWell(
      onTap: isAvailable
          ? () {
              setState(() {
                selectedSize = size;
                lockerCost = cost;
              });
            }
          : null,
      child: Opacity(
        opacity: isAvailable ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected && isAvailable
                ? AppColors.primary.withOpacity(0.2)
                : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected && isAvailable
                  ? AppColors.primary
                  : AppColors.subtle,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(size.toUpperCase(), style: AppText.body),
                  if (!isAvailable) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(Unavailable)',
                      style: AppText.muted.copyWith(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
              Text('₹$cost', style: AppText.titleM),
            ],
          ),
        ),
      ),
    );
  }

  Widget _key(String label) => Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _onKeyPress(label),
          child: Center(
            child: Text(
              label,
              style: AppText.titleM.copyWith(
                color: RegExp(r'^[0-9]$').hasMatch(label)
                    ? AppColors.primary
                    : AppText.titleM.color,
              ),
            ),
          ),
        ),
      );

  Widget _digitBox({required bool filled, required String value}) {
    return Container(
      width: 44,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Text(
        filled ? value : '•',
        style: AppText.titleM,
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
                selectedService = services.first['courier_name'];
                deliveryCost = (services.first['rate'] as num).round();
              });
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.subtle,
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

    return ListView(
      children: services.map((s) {
        final selected = selectedService == s['courier_name'];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                selectedService = s['courier_name'];
                deliveryCost = (s['rate'] as num).round();
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
                  color: selected ? AppColors.primary : AppColors.subtle,
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
      }).toList(),
    );
  }
}
