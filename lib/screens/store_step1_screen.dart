import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'store_step2_phone_screen.dart';
import '../services/audio_service.dart';

class StoreStep1Screen extends StatefulWidget {
  final String helpId;

  const StoreStep1Screen({
    super.key,
    required this.helpId,
  });

  @override
  State<StoreStep1Screen> createState() => _StoreStep1ScreenState();
}

class _StoreStep1ScreenState extends State<StoreStep1Screen> {
  bool isLoading = true;

  Map<String, bool> sizeAvailability = {
    'Small': false,
    'Medium': false,
    'Large': false,
  };

  String selectedSize = 'Small';
  int selectedHours = 2;
  int hourlyRate = 5;

  int get prepaidAmount => hourlyRate * selectedHours;
  int get total => prepaidAmount;

  bool get anyAvailable => sizeAvailability.values.any((v) => v);

  @override
  void initState() {
    super.initState();
      Future.delayed(const Duration(milliseconds: 300), () {
    AudioService.play(AudioEvent.storeselect);
  });
    _fetchAvailability();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _fetchAvailability() async {
    try {
      final res = await ApiService.getAvailableSizes('LOCKER_01');

      final newAvailability = {
        'Small': res['small'] ?? false,
        'Medium': res['medium'] ?? false,
        'Large': res['large'] ?? false,
      };

      setState(() {
        sizeAvailability = newAvailability;

        if (anyAvailable) {
          if (!sizeAvailability[selectedSize]!) {
            selectedSize = sizeAvailability.entries
                .firstWhere((e) => e.value)
                .key;
            hourlyRate = _rateForSize(selectedSize);
          }
        }

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching availability: $e');
      setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
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

            if (!anyAvailable)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ALL LOCKERS ARE CURRENTLY OCCUPIED.',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            Expanded(
              child: Row(
                children: [
                  Expanded(child: _sizePanel()),
                  const SizedBox(width: 32),
                  Expanded(child: _reservationPanel()),
                  const SizedBox(width: 32),
                  Expanded(child: _summaryPanel(context)),
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
            Text('STORING LUGGAGE.', style: AppText.titleXL),
            SizedBox(height: 6),
            Text(
              'STEP 1 OF 4: CHOOSE SIZE AND RESERVATION',
              style: AppText.muted,
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {
            ApiService.stopComplaint(widget.helpId);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
          label: Text('CANCEL'),
        ),
      ],
    );
  }

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

    return _selectableCard(
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
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                size.toUpperCase(),
                style: AppText.titleL.copyWith(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                available ? '₹$rate / hour' : 'NOT AVAILABLE',
                style: AppText.body.copyWith(
                  color: available
                      ? AppColors.primary
                      : Colors.redAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reservationPanel() {
    final options = [
      {'label': '2H', 'hours': 2},
      {'label': '4H', 'hours': 4},
      {'label': '8H', 'hours': 8},
      {'label': '1D', 'hours': 24},
      {'label': '3D', 'hours': 72},
      {'label': '7D', 'hours': 168},
    ];

    return _panel(
      title: 'RESERVATION.',
      child: Column(
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: options.map(_reservationTile).toList(),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _reservationTile(Map option) {
    final hours = option['hours'] as int;
    final label = option['label'] as String;
    final selected = selectedHours == hours;

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

  Widget _summaryPanel(BuildContext context) {
    return _panel(
      title: 'SUMMARY.',
      child: Column(
        children: [
          _summaryRow('Prepaid Time', '₹$prepaidAmount'),
          const Divider(height: 32),
          _summaryRow('TOTAL.', '₹$total', highlight: true),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: anyAvailable
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreStep2PhoneScreen(
                            size: selectedSize.toLowerCase(),
                            hours: selectedHours,
                            ratePerHour: hourlyRate,
                            helpId: widget.helpId,
                          ),
                        ),
                      );
                    }
                  : null,
              child: Text('CONTINUE.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
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
                  : AppColors.subtle,
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