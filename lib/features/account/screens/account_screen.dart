import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/transaction_model.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';
import 'package:tradingpro/shared_widgets/skeleton_widgets.dart';
import 'package:tradingpro/services/export_service.dart';
import 'package:tradingpro/router/user_router.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFilter = 0;

  final _filters = [
    ('All', null),
    ('Deposits', TransactionType.deposit),
    ('Withdrawals', TransactionType.withdrawal),
    ('Profit', TransactionType.profit),
    ('Trades', TransactionType.trade),
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

  void _showExportStatementDialog(
      BuildContext context, dynamic user, List<TransactionModel> txs) {
    final csv = ExportService.generateTransactionsCsv(
      userName: user?.fullName ?? 'Valued Trader',
      userId7: user?.userId7 ?? '0000000',
      transactions: txs,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Account Statement', style: AppTextStyles.h3),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial statement preview (${txs.length} transactions in CSV format):',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 10),
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csv,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy CSV'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account statement copied to clipboard!'),
                    backgroundColor: AppColors.positive,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final filterType = _filters[_selectedFilter].$2;
    final txAsync = ref.watch(transactionsProvider(filterType));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Export Statement',
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            onPressed: () {
              final user = userAsync.valueOrNull;
              final txs = txAsync.valueOrNull ?? [];
              _showExportStatementDialog(context, user, txs);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ─── Balance + Actions ────────────────────────────────────────
          userAsync.when(
            data: (user) => _BalanceHeader(user: user),
            loading: () => Padding(
              padding: const EdgeInsets.all(20),
              child: ShimmerSkeleton(
                width: double.infinity,
                height: 180,
                borderRadius: 20,
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // ─── Transaction Filter Tabs ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  _filters.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_filters[i].$1),
                      selected: _selectedFilter == i,
                      onSelected: (_) => setState(() => _selectedFilter = i),
                      selectedColor: AppColors.primaryContainer,
                      checkmarkColor: AppColors.primary,
                      labelStyle: AppTextStyles.bodySmall.copyWith(
                        color: _selectedFilter == i
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: _selectedFilter == i
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ─── Transaction List ─────────────────────────────────────────
          Expanded(
            child: txAsync.when(
              data: (txs) => txs.isEmpty
                  ? const EmptyStateWidget(
                      title: 'No Transactions',
                      message: 'Your transaction history will appear here.',
                      icon: Icons.receipt_long_outlined,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: txs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _TransactionCard(tx: txs[i]),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TransactionListSkeleton(count: 6),
              ),
              error: (e, _) => ErrorStateWidget(
                message: 'Could not load transactions',
                onRetry: () => ref.invalidate(transactionsProvider(filterType)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  final dynamic user;
  const _BalanceHeader({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Balance',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.currency(user?.balance ?? 0),
                      style: AppTextStyles.financialLarge,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Profit',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.currencyWithSign(user?.profit ?? 0),
                    style: AppTextStyles.financialSmall.copyWith(
                      color: (user?.profit ?? 0) >= 0
                          ? AppColors.positive
                          : AppColors.negative,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.deposit),
                  icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  label: const Text('Deposit'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: AppColors.positive,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.withdrawal),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  label: const Text('Withdraw'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: AppColors.negative,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.isCredit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCredit ? AppColors.positiveLight : AppColors.negativeLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? AppColors.positive : AppColors.negative,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.typeDisplayName,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.description,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.dateTime(tx.createdAt),
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                style: AppTextStyles.financialSmall.copyWith(
                  color: isCredit ? AppColors.positive : AppColors.negative,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Bal: ${AppFormatters.currency(tx.balanceAfter)}',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
