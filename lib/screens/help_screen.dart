import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 40, 48, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // TOP BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Help & Support",
                    style: AppText.titleXL.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 40,
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      "CLOSE",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              Text(
                "Need assistance?",
                style: AppText.titleL.copyWith(
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "If you're facing issues with locker access, payment, or parcel drop, please contact support or wait for assistance.",
                style: AppText.muted.copyWith(fontSize: 18),
              ),

              const Spacer(),

              Center(
                child: Text(
                  "Support: +91 90000 00000",
                  style: AppText.titleL.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
