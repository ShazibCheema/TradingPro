import 'package:flutter/material.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';

class LegalDialogs {
  LegalDialogs._();

  static void showPrivacyPolicy(BuildContext context) {
    _showLegalModal(
      context: context,
      title: 'Privacy Policy',
      content: '''
Last Updated: September 2026

1. Information We Collect
We collect information you provide directly to us when creating an account, making deposits or withdrawal requests, including your name, email address, transaction proofs, and wallet addresses.

2. How We Use Information
We use your information to:
• Facilitate and verify financial transactions and trade requests.
• Send transaction notifications and service updates.
• Ensure security and prevent unauthorized access or fraud.
• Comply with applicable legal and financial compliance obligations.

3. Data Retention & Deletion
You can request immediate deletion of your account and associated personal data at any time via the "Delete Account" feature in your Profile Settings.

4. Data Sharing
We do not sell or rent your personal data to third parties. Data is only processed through secure infrastructure (Firebase / Google Cloud) to operate the application.

5. Security
We implement industry-standard encryption and security controls to safeguard your personal and financial information.
''',
    );
  }

  static void showTermsOfService(BuildContext context) {
    _showLegalModal(
      context: context,
      title: 'Terms of Service',
      content: '''
Last Updated: September 2026

1. Acceptance of Terms
By accessing or using TradingPro: I&T, you agree to be bound by these Terms of Service. If you do not agree, do not use the application.

2. Eligibility & Account Security
You must be of legal age in your jurisdiction to open an account. You are responsible for maintaining the confidentiality of your login credentials.

3. Investment & Trades
All trade requests and deposits submitted through the app are processed according to platform guidelines. Users acknowledge that past returns are not indicative of future performance.

4. Account Termination
You may terminate your account at any time. We reserve the right to suspend or terminate accounts that violate platform policies or attempt fraudulent activities.

5. Modifications
We reserve the right to update these terms at any time. Continued use of the platform constitutes acceptance of modified terms.
''',
    );
  }

  static void showRiskDisclosure(BuildContext context) {
    _showLegalModal(
      context: context,
      title: 'Risk Disclosure & Disclaimer',
      content: '''
IMPORTANT FINANCIAL NOTICE:

1. Investment Risk
Trading and investing in cryptocurrencies and financial instruments involve a high level of risk and may not be suitable for all investors. The high degree of market volatility can work against you as well as for you.

2. No Guaranteed Profits
There is no guarantee of profits or protection from losses. You should never invest money that you cannot afford to lose.

3. Independent Decision
TradingPro does not provide individualized investment advice. Users are responsible for evaluating their financial situation and risk tolerance before initiating any investment or trade request.

4. Regulatory Compliance
Users must comply with all local laws and regulations governing financial and cryptocurrency activities in their respective jurisdictions.
''',
    );
  }

  static void _showLegalModal({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.h3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  content,
                  style: AppTextStyles.body.copyWith(
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
