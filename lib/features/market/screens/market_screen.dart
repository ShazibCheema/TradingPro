import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';
import 'package:tradingpro/shared_widgets/market_data_widgets.dart';
import 'package:tradingpro/router/user_router.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCoinsAsync = ref.watch(activeCoinsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TradingProAppBar(title: 'Markets'),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search coin or symbol (e.g. BTC, ETH)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Header columns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Name', style: AppTextStyles.label),
                ),
                Expanded(
                  child: Text(
                    'Latest Price',
                    style: AppTextStyles.label,
                    textAlign: TextAlign.end,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Rise and Fall',
                    style: AppTextStyles.label,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),

          // Coins List
          Expanded(
            child: allCoinsAsync.when(
              data: (coins) {
                final filtered = coins.where((c) {
                  return c.name.toLowerCase().contains(_searchQuery) ||
                      c.symbol.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Coins Found',
                    message: 'Try searching with a different symbol or name.',
                    icon: Icons.search_off_rounded,
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final coin = filtered[i];
                    return InkWell(
                      onTap: () => context.push(AppRoutes.trading),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: AppColors.divider, width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon & Name
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: AppColors.gray100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: coin.logoUrl != null
                                        ? ClipOval(
                                            child: Image.network(
                                              coin.logoUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _CoinLetter(coin.symbol),
                                            ),
                                          )
                                        : _CoinLetter(coin.symbol),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          coin.symbol,
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          coin.name,
                                          style: AppTextStyles.caption,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        StaleDataIndicator(coin: coin),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Price
                            Expanded(
                              child: Text(
                                coin.hasPrice
                                    ? AppFormatters.cryptoPrice(coin.latestPrice)
                                    : '--',
                                style: AppTextStyles.financialSmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Change
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: coin.hasPrice
                                          ? AppColors.financialBgColor(
                                              coin.isPositive)
                                          : AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      coin.hasPrice
                                          ? AppFormatters.percentageChange(
                                              coin.priceChangePercent24h)
                                          : '--',
                                      style: TextStyle(
                                        color: coin.hasPrice
                                            ? AppColors.financialColor(
                                                coin.isPositive)
                                            : AppColors.textTertiary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: 8,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const SkeletonBox(
                  width: double.infinity,
                  height: 50,
                  borderRadius: 10,
                ),
              ),
              error: (e, _) => ErrorStateWidget(
                message: 'Failed to load markets',
                onRetry: () => ref.invalidate(activeCoinsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinLetter extends StatelessWidget {
  final String symbol;
  const _CoinLetter(this.symbol);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        symbol.isNotEmpty ? symbol[0].toUpperCase() : '?',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontSize: 14,
        ),
      ),
    );
  }
}
