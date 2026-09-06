import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/trade_model.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class TradingScreen extends ConsumerStatefulWidget {
  const TradingScreen({super.key});

  @override
  ConsumerState<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends ConsumerState<TradingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTrade(double availableBalance) async {
    // if (_selectedCoin == null) {
    //   setState(() => _error = 'Please select a market coin.');
    //   return;
    // }
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid investment amount.');
      return;
    }
    if (amount > availableBalance) {
      setState(() => _error = 'Insufficient account balance.');
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Submit Trading Order',
      message:
          'Investment: \$${amount.toStringAsFixed(2)}\n\nSubmit this trade order?',
      confirmLabel: 'Confirm Trade',
      onConfirm: () {},
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(tradeRepositoryProvider).createTrade(
            // coinId: _selectedCoin!.coinId,
            investmentAmount: amount,
          );

      if (mounted) {
        _amountCtrl.clear();
        setState(() => _isSubmitting = false);
        _tabController.animateTo(1); // Switch to orders tab
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trade order submitted successfully!'),
            backgroundColor: AppColors.positive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final userTradesAsync = ref.watch(userTradesProvider);

    final availableBalance = userAsync.valueOrNull?.balance ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trading Account'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'New Trade'),
            Tab(text: 'My Positions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── TAB 1: New Trade ─────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Available Balance
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Available Balance',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSecondary)),
                      Text(
                        AppFormatters.currency(availableBalance),
                        style: AppTextStyles.h4
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Investment Amount
                Text('Investment Amount', style: AppTextStyles.h4),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Trade Amount (\$ USD)',
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    hintText: 'e.g. 500.00',
                    suffixIcon: TextButton(
                      onPressed: () {
                        _amountCtrl.text = availableBalance.toStringAsFixed(2);
                      },
                      child: const Text('MAX'),
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.negativeLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.negative),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                PrimaryButton(
                  label: 'Submit Trade Order',
                  onPressed: () => _submitTrade(availableBalance),
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),

          // ─── TAB 2: Positions ─────────────────────────────────────────
          userTradesAsync.when(
            data: (trades) {
              if (trades.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No Trade Positions',
                  message:
                      'Your active and settled trade orders will appear here.',
                  icon: Icons.candlestick_chart_outlined,
                );
              }
              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: trades.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _TradePositionCard(trade: trades[i]),
              );
            },
            loading: () => ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => const SkeletonBox(
                width: double.infinity,
                height: 110,
                borderRadius: 16,
              ),
            ),
            error: (e, _) => ErrorStateWidget(
              message: 'Failed to load trades',
              onRetry: () => ref.invalidate(userTradesProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradePositionCard extends StatelessWidget {
  final TradeModel trade;
  const _TradePositionCard({required this.trade});

  @override
  Widget build(BuildContext context) {
    final statusType = switch (trade.status) {
      TradeStatus.pending => StatusType.pending,
      TradeStatus.open => StatusType.info,
      TradeStatus.closed =>
        trade.hasProfit ? StatusType.success : StatusType.error,
      TradeStatus.cancelled => StatusType.neutral,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trade Investment',
                style: AppTextStyles.h4,
              ),
              StatusBadge(
                label: trade.status.name.toUpperCase(),
                type: statusType,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Investment', style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.currency(trade.investmentAmount),
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (trade.isClosed)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Outcome', style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(
                      trade.hasProfit
                          ? '+${AppFormatters.currency(trade.profitAmount!)}'
                          : '-${AppFormatters.currency(trade.lossAmount ?? 0)}',
                      style: AppTextStyles.body.copyWith(
                        color: trade.hasProfit
                            ? AppColors.positive
                            : AppColors.negative,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.dateTime(trade.createdAt),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
