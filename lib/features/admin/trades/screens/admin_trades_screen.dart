import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/trade_model.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class AdminTradesScreen extends ConsumerStatefulWidget {
  const AdminTradesScreen({super.key});

  @override
  ConsumerState<AdminTradesScreen> createState() => _AdminTradesScreenState();
}

class _AdminTradesScreenState extends ConsumerState<AdminTradesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _filters = [
    ('All', null),
    ('Pending', TradeStatus.pending),
    ('Open', TradeStatus.open),
    ('Closed', TradeStatus.closed),
    ('Cancelled', TradeStatus.cancelled),
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

  void _showCloseTradeDialog(TradeModel trade) {
    final closePriceCtrl =
        TextEditingController(text: trade.entryPrice.toString());
    final profitCtrl = TextEditingController(text: '0.00');
    final lossCtrl = TextEditingController(text: '0.00');
    final noteCtrl = TextEditingController();
    var isProfit = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Close Trade Order', style: AppTextStyles.h3),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User: ${trade.userFullName} (ID: ${trade.userId7})',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Asset: ${trade.coinSymbol} • Investment: \$${trade.investmentAmount.toStringAsFixed(2)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    'Entry Price: ${AppFormatters.cryptoPrice(trade.entryPrice)}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: closePriceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Closing Exit Price',
                      prefixIcon: Icon(Icons.show_chart_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Outcome: '),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Profit (Win)'),
                        selected: isProfit,
                        selectedColor: AppColors.positiveLight,
                        labelStyle: TextStyle(
                            color: isProfit
                                ? AppColors.positive
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700),
                        onSelected: (v) {
                          if (v) setDialogState(() => isProfit = true);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Loss'),
                        selected: !isProfit,
                        selectedColor: AppColors.negativeLight,
                        labelStyle: TextStyle(
                            color: !isProfit
                                ? AppColors.negative
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700),
                        onSelected: (v) {
                          if (v) setDialogState(() => isProfit = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (isProfit)
                    TextFormField(
                      controller: profitCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Profit Return Amount (\$ USD)',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                    )
                  else
                    TextFormField(
                      controller: lossCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Loss Deducted Amount (\$ USD)',
                        prefixIcon: Icon(Icons.money_off_rounded),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Admin Note / Rationale',
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
                onPressed: () async {
                  final closePrice =
                      double.tryParse(closePriceCtrl.text) ?? trade.entryPrice;
                  final profit = isProfit
                      ? double.tryParse(profitCtrl.text.replaceAll(',', '')) ??
                          0.0
                      : 0.0;
                  final loss = !isProfit
                      ? double.tryParse(lossCtrl.text.replaceAll(',', '')) ??
                          0.0
                      : 0.0;

                  Navigator.of(ctx).pop();

                  try {
                    await ref.read(tradeRepositoryProvider).closeTrade(
                          tradeId: trade.tradeId,
                          userId: trade.userId,
                          closingPrice: closePrice,
                          profitAmount: profit,
                          lossAmount: loss,
                          adminNote: noteCtrl.text.trim().isNotEmpty
                              ? noteCtrl.text.trim()
                              : null,
                        );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trade closed & settled to ledger!'),
                          backgroundColor: AppColors.positive,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error closing trade: $e'),
                          backgroundColor: AppColors.negative,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Confirm Close & Settle'),
              ),
            ],
          );
        },
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
            Text('Trade Management', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              'Manage user trading orders, approve open positions, and settle trade profit/loss outcomes.',
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
                  final tradesAsync = ref.watch(adminTradesProvider(filter.$2));

                  return tradesAsync.when(
                    data: (trades) {
                      if (trades.isEmpty) {
                        return EmptyStateWidget(
                          title: 'No ${filter.$1} Trades',
                          message: 'Trades under this status will appear here.',
                          icon: Icons.candlestick_chart_outlined,
                        );
                      }

                      return ListView.separated(
                        itemCount: trades.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final t = trades[i];
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
                                            '${t.userFullName} (ID: ${t.userId7})',
                                            style: AppTextStyles.body.copyWith(
                                                fontWeight: FontWeight.w700),
                                          ),
                                          Text(
                                            '${t.coinSymbol} • Created: ${AppFormatters.dateTime(t.createdAt)}',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Invested: \$${t.investmentAmount.toStringAsFixed(2)}',
                                      style:
                                          AppTextStyles.financialSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(
                                      'Entry: ${AppFormatters.cryptoPrice(t.entryPrice)}',
                                      style: AppTextStyles.captionMedium,
                                    ),
                                    if (t.closingPrice != null) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        'Exit: ${AppFormatters.cryptoPrice(t.closingPrice!)}',
                                        style: AppTextStyles.captionMedium,
                                      ),
                                    ],
                                    if (t.isClosed) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        t.hasProfit
                                            ? 'Profit: +${AppFormatters.currency(t.profitAmount!)}'
                                            : 'Loss: -${AppFormatters.currency(t.lossAmount ?? 0)}',
                                        style:
                                            AppTextStyles.captionMedium.copyWith(
                                          color: t.hasProfit
                                              ? AppColors.positive
                                              : AppColors.negative,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    if (t.isPending) ...[
                                      ElevatedButton(
                                        onPressed: () async {
                                          try {
                                            await ref
                                                .read(tradeRepositoryProvider)
                                                .openTrade(
                                                  tradeId: t.tradeId,
                                                  userId: t.userId,
                                                );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Trade opened successfully!'),
                                                  backgroundColor:
                                                      AppColors.positive,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Failed to open trade: $e'),
                                                  backgroundColor:
                                                      AppColors.negative,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: const Text('Open Trade'),
                                      ),
                                    ] else if (t.isOpen) ...[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                        ),
                                        onPressed: () =>
                                            _showCloseTradeDialog(t),
                                        child: const Text('Close & Settle'),
                                      ),
                                    ] else
                                      StatusBadge(
                                        label: t.status.name.toUpperCase(),
                                        type: t.hasProfit
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
                      message: 'Failed to load trades',
                      onRetry: () =>
                          ref.invalidate(adminTradesProvider(filter.$2)),
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
