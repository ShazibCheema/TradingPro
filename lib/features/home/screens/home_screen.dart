import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/coin_model.dart';
import 'package:tradingpro/models/user_model.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';
import 'package:tradingpro/shared_widgets/market_data_widgets.dart';
import 'package:tradingpro/shared_widgets/price_chart.dart';
import 'package:tradingpro/router/user_router.dart';
import 'package:flutter/services.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final featuredAsync = ref.watch(featuredCoinsProvider);
    final allCoinsAsync = ref.watch(activeCoinsProvider);
    final unread = ref.watch(unreadNotifCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(userProvider);
          ref.invalidate(featuredCoinsProvider);
          ref.invalidate(activeCoinsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ─── Header ───────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.surface,
              elevation: 0,
              scrolledUnderElevation: 1,
              shadowColor: AppColors.divider,
              title: Row(
                children: [
                  const AppLogo(size: 34, borderRadius: 8, showShadow: false),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TradingPro: I&T',
                        style: AppTextStyles.h4.copyWith(fontSize: 15),
                      ),
                      Text(
                        'Investing & Trading',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      onPressed: () => context.go(AppRoutes.inbox),
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.negative,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Welcome Banner ────────────────────────────────────
                  userAsync.when(
                    data: (user) => _WelcomeBanner(user: user),
                    loading: () => const _WelcomeBannerSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // ─── Top 3 Featured Coins ─────────────────────────────
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Featured', style: AppTextStyles.h4),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.market),
                          child: Text(
                            'View All',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  featuredAsync.when(
                    data: (coins) => _FeaturedCoinRow(coins: coins),
                    loading: () => const _FeaturedCoinSkeleton(),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ErrorStateWidget(message: 'Could not load market data'),
                    ),
                  ),

                  // ─── Account Card ─────────────────────────────────────
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: userAsync.when(
                      data: (user) => _AccountCard(user: user),
                      loading: () => const _AccountCardSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                  // ─── Quick Actions ─────────────────────────────────────
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Quick Actions', style: AppTextStyles.h4),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _QuickActions(),
                  ),

                  // ─── Market Section ────────────────────────────────────
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Market', style: AppTextStyles.h4),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.market),
                          child: Text(
                            'See All',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Market column headers
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Name',
                            style: AppTextStyles.label,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Price',
                            style: AppTextStyles.label,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '24H Change',
                            style: AppTextStyles.label,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0),
                  allCoinsAsync.when(
                    data: (coins) => _MarketList(coins: coins.take(10).toList()),
                    loading: () => const _MarketListSkeleton(),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: ErrorStateWidget(message: 'Could not load market data'),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Welcome Banner ─────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final UserModel? user;
  const _WelcomeBanner({this.user});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final firstName = user?.fullName.split(' ').first ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  firstName.isNotEmpty ? firstName : 'Trader',
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your portfolio is ready.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBannerSkeleton extends StatelessWidget {
  const _WelcomeBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// ─── Featured Coin Cards ─────────────────────────────────────────────────────

class _FeaturedCoinRow extends StatelessWidget {
  final List<CoinModel> coins;
  const _FeaturedCoinRow({required this.coins});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: coins.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _FeaturedCoinCard(coin: coins[i]),
      ),
    );
  }
}

class _FeaturedCoinCard extends StatelessWidget {
  final CoinModel coin;
  const _FeaturedCoinCard({required this.coin});

  @override
  Widget build(BuildContext context) {
    final isPositive = coin.isPositive;
    final changeColor = AppColors.financialColor(isPositive);

    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Coin logo or placeholder
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  shape: BoxShape.circle,
                ),
                child: coin.logoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          coin.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _CoinInitial(coin.symbol),
                        ),
                      )
                    : _CoinInitial(coin.symbol),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.financialBgColor(isPositive),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 10,
                      color: changeColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${coin.percentageChange.abs().toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coin.symbol,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coin.hasPrice
                          ? AppFormatters.cryptoPrice(coin.latestPrice)
                          : '--',
                      style: AppTextStyles.financialSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    StaleDataIndicator(coin: coin),
                  ],
                ),
              ),
              MiniSparkline(
                currentPrice: coin.latestPrice,
                isPositive: isPositive,
                width: 45,
                height: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedCoinSkeleton extends StatelessWidget {
  const _FeaturedCoinSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => SkeletonBox(width: 150, height: 140, borderRadius: 16),
      ),
    );
  }
}

// ─── Account Card ─────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final UserModel? user;
  const _AccountCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trading Account',
            style: AppTextStyles.captionMedium.copyWith(
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.currency(user?.balance ?? 0),
                      style: AppTextStyles.financialLarge.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Profit',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
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
          const Divider(height: 0),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'USER ID',
                    style: AppTextStyles.label.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.userId7 ?? '-------',
                    style: AppTextStyles.financialSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              if (user?.userId7 != null)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: user!.userId7));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User ID copied'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: AppTextStyles.buttonSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

class _AccountCardSkeleton extends StatelessWidget {
  const _AccountCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: double.infinity,
      height: 180,
      borderRadius: 20,
    );
  }
}

// ─── Quick Actions ───────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionTile(
          icon: Icons.arrow_downward_rounded,
          label: 'Deposit',
          color: AppColors.positive,
          bg: AppColors.positiveLight,
          onTap: () => context.push(AppRoutes.deposit),
        ),
        const SizedBox(width: 12),
        _ActionTile(
          icon: Icons.arrow_upward_rounded,
          label: 'Withdraw',
          color: AppColors.negative,
          bg: AppColors.negativeLight,
          onTap: () => context.push(AppRoutes.withdrawal),
        ),
        const SizedBox(width: 12),
        _ActionTile(
          icon: Icons.candlestick_chart_outlined,
          label: 'Trading',
          color: AppColors.primary,
          bg: AppColors.primaryContainer,
          onTap: () => context.push(AppRoutes.trading),
        ),
        const SizedBox(width: 12),
        _ActionTile(
          icon: Icons.receipt_long_outlined,
          label: 'History',
          color: AppColors.pending,
          bg: AppColors.pendingLight,
          onTap: () => context.go(AppRoutes.account),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Market List ─────────────────────────────────────────────────────────────

class _MarketList extends StatelessWidget {
  final List<CoinModel> coins;
  const _MarketList({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: coins
          .map((coin) => _CoinListTile(coin: coin))
          .toList(),
    );
  }
}

class _CoinListTile extends StatelessWidget {
  final CoinModel coin;
  const _CoinListTile({required this.coin});

  @override
  Widget build(BuildContext context) {
    final isPositive = coin.isPositive;
    final changeColor = AppColors.financialColor(isPositive);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          // Icon
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
                                _CoinInitial(coin.symbol),
                          ),
                        )
                      : _CoinInitial(coin.symbol),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        ? AppColors.financialBgColor(isPositive)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    coin.hasPrice
                        ? AppFormatters.percentageChange(
                            coin.priceChangePercent24h)
                        : '--',
                    style: TextStyle(
                      color: coin.hasPrice ? changeColor : AppColors.textTertiary,
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
    );
  }
}

class _MarketListSkeleton extends StatelessWidget {
  const _MarketListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        6,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              SkeletonBox(width: 40, height: 40, borderRadius: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 80, height: 14),
                  const SizedBox(height: 4),
                  SkeletonBox(width: 50, height: 10),
                ],
              ),
              const Spacer(),
              SkeletonBox(width: 70, height: 14),
              const SizedBox(width: 12),
              SkeletonBox(width: 60, height: 26, borderRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _CoinInitial extends StatelessWidget {
  final String symbol;
  const _CoinInitial(this.symbol);

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
