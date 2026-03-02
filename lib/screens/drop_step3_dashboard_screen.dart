import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'drop_step4_payment_screen.dart';
import '../models/drop_mode.dart';
import 'locker_opened_screen.dart';


const Color navy = Color(0xFF1E293B); // slate-800

enum CourierStep { enterPhone, choosePartner }

class DropStep3DashboardScreen extends StatefulWidget {
  const DropStep3DashboardScreen({
    super.key,
    required this.phone,
    required this.helpId,
  });
final String helpId;

  final String phone;


  @override
  State<DropStep3DashboardScreen> createState() =>
      _DropStep3DashboardScreenState();
}

class _DropStep3DashboardScreenState
    extends State<DropStep3DashboardScreen> {
  // ================= MODE =================
String? courierError;
  DropMode dropMode = DropMode.personal;
  CourierStep courierStep = CourierStep.enterPhone;

  // ================= SIZE =================
bool allLockersUnavailable = false;

  bool isLoading = true;
  Map<String, bool> sizeAvailability = {
    'Small': false,
    'Medium': false,
    'Large': false,
  };

  String selectedSize = 'Small';
  int selectedHours = 2;
  int hourlyRate = 5;

  // ================= COURIER =================

  String courierPhone = '';
  bool findingPartners = false;
  List<dynamic> courierPartners = [];
  Map<String, dynamic>? selectedCourier;

  // ================= PRICING =================

  int get prepaidAmount => hourlyRate * selectedHours;
  int get dropCharge => 10;
  int get total => prepaidAmount + dropCharge;

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

Future<void> _fetchAvailability() async {
  try {
    final res = await ApiService.getAvailableSizes(ApiService.lockerId);

    final updatedAvailability = {
      'Small': res['small'] ?? false,
      'Medium': res['medium'] ?? false,
      'Large': res['large'] ?? false,
    };

    final hasAnyAvailable =
        updatedAvailability.values.any((v) => v == true);

    setState(() {
      sizeAvailability = updatedAvailability;
      allLockersUnavailable = !hasAnyAvailable;

      if (hasAnyAvailable) {
        if (!sizeAvailability[selectedSize]!) {
          selectedSize = sizeAvailability.entries
              .firstWhere((e) => e.value)
              .key;
          hourlyRate = _rateForSize(selectedSize);
        }
      }

      isLoading = false;
    });
  } catch (_) {
    setState(() {
      isLoading = false;
      allLockersUnavailable = true;
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
            _header(context),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _sizePanel()),
                  const SizedBox(width: 32),
                  if (dropMode == DropMode.personal) ...[
                    Expanded(child: _reservationPanel()),
                    const SizedBox(width: 32),
                    Expanded(child: _summaryPanel(context)),
                  ] else ...[
                    Expanded(flex: 2, child: _courierPanel()),
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

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dropMode == DropMode.personal
                  ? 'PERSONAL DROP.'
                  : 'DROP AS COURIER.',
              style: AppText.titleXL,
            ),
            const SizedBox(height: 6),
            Text('FOR ${widget.phone}', style: AppText.muted),
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

  // ================= SIZE PANEL =================

Widget _sizePanel() {
  return _panel(
    title: 'SIZE.',
    child: allLockersUnavailable
        ? _noLockerAvailableView()
        : Column(
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
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'ALL LOCKERS UNAVAILABLE',
            style: AppText.titleM.copyWith(
              color: Colors.redAccent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Please try again later or choose another location.',
            textAlign: TextAlign.center,
            style: AppText.body,
          ),
        ],
      ),
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
        onTap: (!available || allLockersUnavailable)
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

  // ================= PERSONAL DROP =================

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
          SizedBox(
            width: double.infinity,
            height: 86,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  dropMode = DropMode.delivery;
                  courierStep = CourierStep.enterPhone;
                  selectedCourier = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.local_shipping_rounded, size: 42),
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
          child: Text(label,
              style: AppText.titleL.copyWith(fontSize: 32)),
        ),
      ),
    );
  }

  // ================= COURIER =================

  Widget _courierPanel() {
    if (courierStep == CourierStep.enterPhone) {
      return _courierPhoneEntry();
    }
    return Row(
      children: [
        Expanded(child: _courierListPanel()),
        const SizedBox(width: 32),
        Expanded(child: _courierSummaryPanel()),
      ],
    );
  }

  Widget _courierPhoneEntry() {
    return _panel(
      title: 'ENTER YOUR NUMBER',
      child: Column(
        children: [
          Container(
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(courierPhone, style: AppText.titleXL),
          ),
          const SizedBox(height: 24),
          Expanded(child: _courierKeypad()),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: courierPhone.length == 10
                  ? _findPartners
                  : null,
              child: const Text(
  'Find Couriers',
  style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 20,
    letterSpacing: 1.1,
  ),
),

            ),
          ),
        ],
      ),
    );
  }

  Widget _courierKeypad() {
    return Column(
      children: [
        _keypadRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _keypadRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _keypadRow(['7', '8', '9']),
        const SizedBox(height: 12),
        _keypadRow(['CLEAR', '0', '⌫']),
      ],
    );
  }

  Widget _keypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 68,
              child: _selectableCard(
                selected: false,
                onTap: () {
                  setState(() {
                    if (key == '⌫' && courierPhone.isNotEmpty) {
                      courierPhone = courierPhone.substring(
                          0, courierPhone.length - 1);
                    } else if (key == 'CLEAR') {
                      courierPhone = '';
                    } else if (courierPhone.length < 10) {
                      courierPhone += key;
                    }
                  });
                },
                child: Center(
                  child: Text(
                    key,
                    style: AppText.titleL.copyWith(
                      fontSize: 26,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _findPartners() async {
    final res =
        await ApiService.findPartners(phone: courierPhone);
    setState(() {
      courierPartners = res;
      selectedCourier = null;
      courierStep = CourierStep.choosePartner;
    });
  }

 Widget _courierListPanel() {
  return _panel(
    title: 'COURIER SERVICES.',
    child: Column(
      children: [
        _editablePhoneHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: courierPartners.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final p = courierPartners[i];
              final selected =
                  selectedCourier?['id'] == p['id'];

              return _selectableCard(
                selected: selected,
                onTap: () {
                  setState(() {
                    selectedCourier = {
                      'id': p['id'],
                      'name': p['name'],
                    };
                  });
                },
                child: ListTile(
                  title: Text(
                    p['name'],
                    style: AppText.titleM,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}


Widget _editablePhoneHeader() {
  return GestureDetector(
    onTap: () {
      setState(() {
        courierStep = CourierStep.enterPhone;
        selectedCourier = null;
      });
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            courierPhone,
            style: AppText.titleL.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const Icon(
            Icons.edit,
            color: AppColors.primary,
          ),
        ],
      ),
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

if (courierError != null) ...[
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Colors.redAccent,
        width: 1.5,
      ),
    ),
    child: Row(
      children: const [
        Icon(Icons.warning_amber_rounded,
            color: Colors.redAccent),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "Please select your courier company.",
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ],
    ),
  ),
],

SizedBox(
  width: double.infinity,
  height: 64,
  child: ElevatedButton(

onPressed: () async {
  final partnerId = selectedCourier?['id'];

  if (partnerId == null) {
    setState(() {
      courierError = "Please select your courier company.";
    });
    return;
  }

  // clear error if valid
  setState(() {
    courierError = null;
  });

  final result = await ApiService.deliveryDropoff(
    recipientPhone: widget.phone,
    deliveryPhone: courierPhone,
    partnerId: partnerId,
    size: selectedSize.toLowerCase(),
    hours: selectedHours,
  );

  final accessCode = result['accessCode'];
  if (accessCode == null) {
    throw Exception('accessCode missing from API response');
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

  // ================= COMMON =================
Widget _summaryPanel(BuildContext context) {
  return _panel(
    title: 'SUMMARY.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryRow('Drop Charge', 'FREE'),
        const SizedBox(height: 16),
        _summaryRow('Prepaid Time', 'FREE'),

        const Divider(height: 32),

        _summaryRow('TOTAL.', '₹FREE', highlight: true),

        const SizedBox(height: 16),

        // ⚠️ WARNING / INFO TEXT (ADDED)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orangeAccent.withOpacity(0.6),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.orangeAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You will NOT be charged now.\n'
                  'The recipient will pay the amount during pickup.',
                  style: AppText.body.copyWith(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: allLockersUnavailable
    ? null
    : () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DropStep4PaymentScreen(
                    phone: widget.phone,
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
