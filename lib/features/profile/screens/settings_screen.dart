import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/models/settings_models.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notifPrefsProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TradingProAppBar(title: 'Settings'),
      body: prefsAsync.when(
        data: (prefs) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Notification Preferences',
                    style: AppTextStyles.captionMedium.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      _ToggleTile(
                        title: 'Transactions',
                        subtitle: 'Balance adjustments and ledger updates',
                        value: prefs.transactions,
                        onChanged: (val) => _update(
                          ref,
                          currentUserId,
                          prefs.copyWith(transactions: val),
                        ),
                      ),
                      const Divider(height: 0),
                      _ToggleTile(
                        title: 'Deposits',
                        subtitle: 'Deposit submissions, approvals, and rejections',
                        value: prefs.deposits,
                        onChanged: (val) => _update(
                          ref,
                          currentUserId,
                          prefs.copyWith(deposits: val),
                        ),
                      ),
                      const Divider(height: 0),
                      _ToggleTile(
                        title: 'Withdrawals',
                        subtitle: 'Withdrawal confirmations and settlements',
                        value: prefs.withdrawals,
                        onChanged: (val) => _update(
                          ref,
                          currentUserId,
                          prefs.copyWith(withdrawals: val),
                        ),
                      ),
                      const Divider(height: 0),
                      _ToggleTile(
                        title: 'Profit',
                        subtitle: 'Profit awards and trading yield additions',
                        value: prefs.profit,
                        onChanged: (val) => _update(
                          ref,
                          currentUserId,
                          prefs.copyWith(profit: val),
                        ),
                      ),
                      const Divider(height: 0),
                      _ToggleTile(
                        title: 'Trading',
                        subtitle: 'Trade openings, closings, and cancellations',
                        value: prefs.trading,
                        onChanged: (val) => _update(
                          ref,
                          currentUserId,
                          prefs.copyWith(trading: val),
                        ),
                      ),
                      const Divider(height: 0),
                      _ToggleTile(
                        title: 'Customer Support',
                        subtitle: 'Replies from admin on live support inquiries',
                        value: prefs.customerSupport,
                        onChanged: (val) => _update(
                          ref,
                          currentUserId,
                          prefs.copyWith(customerSupport: val),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Disabling a category suppresses push alerts for that category while maintaining transaction records in your inbox.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => ErrorStateWidget(
          message: 'Could not load preferences',
          onRetry: () => ref.invalidate(notifPrefsProvider),
        ),
      ),
    );
  }

  void _update(
    WidgetRef ref,
    String? uid,
    NotificationPrefsModel updated,
  ) {
    if (uid == null) return;
    ref.read(notificationRepositoryProvider).updatePrefs(uid, updated);
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primaryContainer,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
