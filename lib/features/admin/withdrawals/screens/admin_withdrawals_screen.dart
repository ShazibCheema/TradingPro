import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/withdrawal_model.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class AdminWithdrawalsScreen extends ConsumerStatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  ConsumerState<AdminWithdrawalsScreen> createState() =>
      _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState
    extends ConsumerState<AdminWithdrawalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _filters = [
    ('Pending', WithdrawalStatus.pending),
    ('Approved', WithdrawalStatus.approved),
    ('Rejected', WithdrawalStatus.rejected),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveWithdrawal(WithdrawalModel w) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Approve Withdrawal Payout',
      message:
          'User: ${w.userFullName} (ID: ${w.userId7})\nAmount: \$${w.amount.toStringAsFixed(2)} ${w.asset}\nAddress: ${w.walletAddress} (${w.network})\n\nConfirming marks this payout as settled.',
      confirmLabel: 'Approve & Settle',
      onConfirm: () {},
    );

    if (confirmed != true) return;

    try {
      await ref.read(withdrawalRepositoryProvider).approveWithdrawal(
            withdrawalId: w.withdrawalId,
            userId: w.userId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal approved and settled!'),
            backgroundColor: AppColors.positive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve withdrawal: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    }
  }

  void _showRejectDialog(WithdrawalModel w) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reject Withdrawal Request', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${w.userFullName} (ID: ${w.userId7})',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'e.g. Ineligible request or incorrect destination address',
                prefixIcon: Icon(Icons.warning_amber_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(withdrawalRepositoryProvider).rejectWithdrawal(
                      withdrawalId: w.withdrawalId,
                      userId: w.userId,
                      reason: reasonCtrl.text.trim().isNotEmpty
                          ? reasonCtrl.text.trim()
                          : 'Withdrawal rejected by admin',
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Withdrawal rejected. Reserved balance restored.'),
                      backgroundColor: AppColors.negative,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.negative,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Withdrawal Queue', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              'Verify user payout requests, check destination addresses, and confirm settlements.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),

            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: _filters.map((f) => Tab(text: f.$1)).toList(),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _filters.map((filter) {
                  final withdrawalsAsync =
                      ref.watch(adminWithdrawalsProvider(filter.$2));

                  return withdrawalsAsync.when(
                    data: (withdrawals) {
                      if (withdrawals.isEmpty) {
                        return EmptyStateWidget(
                          title: 'No ${filter.$1} Withdrawals',
                          message:
                              'Withdrawals marked as ${filter.$1.toLowerCase()} will appear here.',
                          icon: Icons.arrow_upward_rounded,
                        );
                      }

                      return ListView.separated(
                        itemCount: withdrawals.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final w = withdrawals[i];
                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.divider, width: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${w.userFullName} (ID: ${w.userId7})',
                                            style: AppTextStyles.body.copyWith(
                                                fontWeight: FontWeight.w700),
                                          ),
                                          Text(
                                            '${w.userEmail} • ${AppFormatters.dateTime(w.createdAt)}',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '-\$${w.amount.toStringAsFixed(2)} ${w.asset}',
                                      style:
                                          AppTextStyles.financialMedium.copyWith(
                                        color: AppColors.negative,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${w.asset} (${w.network}): ${w.walletAddress}',
                                          style: AppTextStyles.captionMedium
                                              .copyWith(fontFamily: 'Courier'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    const Spacer(),
                                    if (w.isPending) ...[
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.negative,
                                          side: const BorderSide(
                                              color: AppColors.negative),
                                        ),
                                        onPressed: () => _showRejectDialog(w),
                                        child: const Text('Reject'),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.positive,
                                        ),
                                        onPressed: () => _approveWithdrawal(w),
                                        child: const Text('Approve & Settle'),
                                      ),
                                    ] else
                                      StatusBadge(
                                        label: w.status.name.toUpperCase(),
                                        type: w.isApproved
                                            ? StatusType.success
                                            : StatusType.error,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (e, _) => ErrorStateWidget(
                      message: 'Failed to load withdrawals',
                      onRetry: () =>
                          ref.invalidate(adminWithdrawalsProvider(filter.$2)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
