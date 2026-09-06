import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/user_model.dart';
import 'package:tradingpro/models/transaction_model.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState
    extends ConsumerState<AdminUserDetailScreen> {
  final _profitAmountCtrl = TextEditingController();
  final _profitReasonCtrl = TextEditingController();
  bool _isActionLoading = false;

  @override
  void dispose() {
    _profitAmountCtrl.dispose();
    _profitReasonCtrl.dispose();
    super.dispose();
  }

  void _showAwardProfitDialog(UserModel user) {
    _profitAmountCtrl.clear();
    _profitReasonCtrl.text = 'Trading Profit';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final entered =
              double.tryParse(_profitAmountCtrl.text.replaceAll(',', '')) ?? 0.0;
          final newBalance = user.balance + entered;
          final newProfit = user.profit + entered;

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Award Trading Profit', style: AppTextStyles.h3),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User: ${user.fullName} (ID: ${user.userId7})',
                    style: AppTextStyles.captionMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _balanceRow(
                            'Current Balance:', AppFormatters.currency(user.balance)),
                        const SizedBox(height: 6),
                        _balanceRow(
                            'Profit to Add:', '+\$${entered.toStringAsFixed(2)}',
                            color: AppColors.positive),
                        const Divider(height: 16),
                        _balanceRow('New Balance:',
                            AppFormatters.currency(newBalance),
                            isBold: true),
                        const SizedBox(height: 4),
                        _balanceRow('New Total Profit:',
                            AppFormatters.currencyWithSign(newProfit),
                            isBold: true, color: AppColors.positive),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _profitAmountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Profit Amount (\$ USD)',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _profitReasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reason / Memo',
                      hintText: 'e.g. Daily Trading Profit',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.positive,
                ),
                onPressed: entered <= 0
                    ? null
                    : () async {
                        Navigator.of(ctx).pop();
                        await _executeAwardProfit(user, entered);
                      },
                child: const Text('Confirm Award'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _executeAwardProfit(UserModel user, double amount) async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(adminRepositoryProvider).awardProfit(
            userId: user.uid,
            amount: amount,
            reason: _profitReasonCtrl.text.trim().isNotEmpty
                ? _profitReasonCtrl.text.trim()
                : 'Trading Profit',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Awarded \$${amount.toStringAsFixed(2)} profit to ${user.fullName}!'),
            backgroundColor: AppColors.positive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to award profit: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _showAdjustmentDialog(UserModel user) {
    final adjAmountCtrl = TextEditingController();
    final adjReasonCtrl = TextEditingController();
    var isCredit = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final entered =
              double.tryParse(adjAmountCtrl.text.replaceAll(',', '')) ?? 0.0;
          final newBalance =
              isCredit ? user.balance + entered : user.balance - entered;

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Balance Adjustment', style: AppTextStyles.h3),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User: ${user.fullName} (ID: ${user.userId7})',
                    style: AppTextStyles.captionMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('+ Credit (Add)'),
                        selected: isCredit,
                        selectedColor: AppColors.positiveLight,
                        labelStyle: TextStyle(
                          color: isCredit
                              ? AppColors.positive
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (v) {
                          if (v) setDialogState(() => isCredit = true);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('- Debit (Deduct)'),
                        selected: !isCredit,
                        selectedColor: AppColors.negativeLight,
                        labelStyle: TextStyle(
                          color: !isCredit
                              ? AppColors.negative
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (v) {
                          if (v) setDialogState(() => isCredit = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _balanceRow('Current Balance:',
                            AppFormatters.currency(user.balance)),
                        const SizedBox(height: 6),
                        _balanceRow(
                          'Adjustment:',
                          '${isCredit ? "+" : "-"}\$${entered.toStringAsFixed(2)}',
                          color: isCredit
                              ? AppColors.positive
                              : AppColors.negative,
                        ),
                        const Divider(height: 16),
                        _balanceRow(
                          'New Balance:',
                          AppFormatters.currency(newBalance),
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: adjAmountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Adjustment Amount (\$ USD)',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: adjReasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mandatory Rationale / Reason',
                      hintText: 'e.g. Approved Deposit Correction',
                      prefixIcon: Icon(Icons.description_rounded),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCredit ? AppColors.positive : AppColors.negative,
                ),
                onPressed: entered <= 0
                    ? null
                    : () async {
                        final reason = adjReasonCtrl.text.trim();
                        if (reason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rationale is strictly required.'),
                              backgroundColor: AppColors.negative,
                            ),
                          );
                          return;
                        }
                        Navigator.of(ctx).pop();
                        await _executeAdjustment(
                            user, entered, reason, isCredit);
                      },
                child: const Text('Confirm Adjustment'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _executeAdjustment(
      UserModel user, double amount, String reason, bool isCredit) async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(adminRepositoryProvider).makeAdjustment(
            userId: user.uid,
            amount: amount,
            reason: reason,
            isCredit: isCredit,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Balance adjusted by ${isCredit ? "+" : "-"}\$${amount.toStringAsFixed(2)} successfully!'),
            backgroundColor: AppColors.positive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed adjustment: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Widget _balanceRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
        Text(value,
            style: AppTextStyles.caption.copyWith(
                color: color ?? AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600)),
      ],
    );
  }

  Future<void> _toggleAccountStatus(UserModel user) async {
    final newStatus = user.isActive
        ? AccountStatus.suspended
        : AccountStatus.active;

    final confirmed = await ConfirmDialog.show(
      context,
      title: user.isActive ? 'Suspend User Account?' : 'Activate User Account?',
      message: user.isActive
          ? 'Suspending ${user.fullName} will restrict all financial actions and trading operations.'
          : 'Re-activating ${user.fullName} will restore their platform access.',
      confirmLabel: user.isActive ? 'Suspend' : 'Activate',
      isDestructive: user.isActive,
      onConfirm: () {},
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .updateAccountStatus(user.uid, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account marked as ${newStatus.name.toUpperCase()}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStream =
        ref.watch(userRepositoryProvider).streamUser(widget.userId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TradingProAppBar(title: 'User Profile & Ledger'),
      body: StreamBuilder<UserModel?>(
        stream: userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('User document not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Details Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : 'U',
                                style: AppTextStyles.h3
                                    .copyWith(color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.fullName, style: AppTextStyles.h3),
                                Text(user.email,
                                    style: AppTextStyles.bodySmall),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.gray100,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '7-Digit ID: ${user.userId7}',
                                        style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    StatusBadge(
                                      label:
                                          user.accountStatus.name.toUpperCase(),
                                      type: user.isActive
                                          ? StatusType.success
                                          : StatusType.error,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 0),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Balance',
                                    style: AppTextStyles.caption),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.currency(user.balance),
                                  style: AppTextStyles.financialMedium,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Profit',
                                    style: AppTextStyles.caption),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.currencyWithSign(user.profit),
                                  style: AppTextStyles.financialMedium.copyWith(
                                    color: user.profit >= 0
                                        ? AppColors.positive
                                        : AppColors.negative,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.monetization_on_rounded,
                                size: 18),
                            label: const Text('Award Profit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.positive,
                              minimumSize: const Size(150, 48),
                            ),
                            onPressed: _isActionLoading
                                ? null
                                : () => _showAwardProfitDialog(user),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: const Text('Adjustment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(150, 48),
                            ),
                            onPressed: _isActionLoading
                                ? null
                                : () => _showAdjustmentDialog(user),
                          ),
                          OutlinedButton.icon(
                            icon: Icon(
                              user.isActive
                                  ? Icons.block_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: user.isActive
                                  ? AppColors.negative
                                  : AppColors.positive,
                              size: 18,
                            ),
                            label: Text(
                              user.isActive ? 'Suspend' : 'Activate',
                              style: TextStyle(
                                color: user.isActive
                                    ? AppColors.negative
                                    : AppColors.positive,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: user.isActive
                                    ? AppColors.negative
                                    : AppColors.positive,
                              ),
                              minimumSize: const Size(150, 48),
                            ),
                            onPressed: _isActionLoading
                                ? null
                                : () => _toggleAccountStatus(user),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Transaction Ledger Title
                Text('User Transaction Ledger', style: AppTextStyles.h4),
                const SizedBox(height: 12),

                // Ledger Stream for this specific user
                StreamBuilder<List<TransactionModel>>(
                  stream: ref
                      .read(transactionRepositoryProvider)
                      .streamTransactions(user.uid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final txs = snap.data ?? [];
                    if (txs.isEmpty) {
                      return const EmptyStateWidget(
                        title: 'No Ledger Entries',
                        message: 'This user has no financial operations yet.',
                        icon: Icons.receipt_long_outlined,
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: txs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final tx = txs[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.divider, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                tx.isCredit
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: tx.isCredit
                                    ? AppColors.positive
                                    : AppColors.negative,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.typeDisplayName,
                                      style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${tx.description} • ${AppFormatters.dateTime(tx.createdAt)}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${tx.isCredit ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                                    style:
                                        AppTextStyles.financialSmall.copyWith(
                                      color: tx.isCredit
                                          ? AppColors.positive
                                          : AppColors.negative,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Bal: \$${tx.balanceAfter.toStringAsFixed(2)}',
                                    style: AppTextStyles.caption.copyWith(
                                        fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
