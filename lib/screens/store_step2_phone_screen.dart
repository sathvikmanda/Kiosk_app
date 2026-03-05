import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../services/api_service.dart';
import 'store_step3_otp_screen.dart';
import '../services/audio_service.dart';

class StoreStep2PhoneScreen extends StatefulWidget {
  const StoreStep2PhoneScreen({
    super.key,
    required this.size,
    required this.hours,
    required this.ratePerHour,


    required this.helpId,
  });
final String helpId;


  final String size;
  final int hours;
  final int ratePerHour;


  @override
  State<StoreStep2PhoneScreen> createState() => _StoreStep2PhoneScreenState();
}

class _StoreStep2PhoneScreenState extends State<StoreStep2PhoneScreen> {
  static const int phoneLength = 10;
  final List<String> _phoneDigits = [];
  @override
void initState() {
  super.initState();

  // Delay slightly so audio doesn't clash with navigation
  Future.delayed(const Duration(milliseconds: 300), () {
    AudioService.play(AudioEvent.enterPhone);
  });
}

  bool isLoading = false;

  void _onKeyPress(String value) {
    setState(() {
      if (value == 'Clear') {
        _phoneDigits.clear();
      } else if (value == '⌫') {
        if (_phoneDigits.isNotEmpty) _phoneDigits.removeLast();
      } else if (_phoneDigits.length < phoneLength) {
        _phoneDigits.add(value);
      }
    });
  }

  String get phoneNumber => _phoneDigits.join();

  @override
  Widget build(BuildContext context) {
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
                  Expanded(flex: 4, child: _phonePanel()),
                  const SizedBox(width: 32),
                  Expanded(flex: 5, child: _rightPanel(context)),
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
          children: const [
            Text('STORING LUGGAGE.', style: AppText.titleXL),
            SizedBox(height: 6),
            Text(
              'STEP 2 OF 4: ENTER PHONE NUMBER',
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

  // ================= LEFT PANEL =================

  Widget _phonePanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENTER YOUR PHONE NUMBER.',
            style: AppText.titleL,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(phoneLength, (i) => _digitBox(i)),
          ),
        ],
      ),
    );
  }

  Widget _digitBox(int index) {
    final filled = index < _phoneDigits.length;

    return Container(
      width: 44,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? AppColors.primary : Colors.white12,
          width: 1.4,
        ),
      ),
      child: Text(
        filled ? _phoneDigits[index] : '•',
        style: AppText.titleL.copyWith(
          fontSize: 22,
          color: filled ? AppColors.primary : Colors.white38,
        ),
      ),
    );
  }

  // ================= RIGHT PANEL =================

  Widget _rightPanel(BuildContext context) {
    final keys = [
      '1','2','3',
      '4','5','6',
      '7','8','9',
      'Clear','0','⌫',
    ];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: keys.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                mainAxisExtent: 80,
              ),
              itemBuilder: (_, i) => _key(keys[i]),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 68,
            child: ElevatedButton(
              onPressed: _phoneDigits.length == phoneLength && !isLoading
                  ? _handleContinue
                  : null,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CONTINUE.'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleContinue() async {
    setState(() => isLoading = true);

    try {
      await ApiService.sendOtp(phone: phoneNumber);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoreStep3OtpScreen(
            phoneNumber: phoneNumber,
            size: widget.size,
            hours: widget.hours,
            ratePerHour: widget.ratePerHour,


            helpId: widget.helpId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send OTP')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _key(String label) {
    final isNumber = label.length == 1;

    return Material(
      color: AppColors.card,
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onKeyPress(label),
        child: Center(
          child: Text(
            label,
            style: AppText.titleL.copyWith(
              fontSize: isNumber ? 32 : 20,
              color: label == 'Clear'
                  ? Colors.white70
                  : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
