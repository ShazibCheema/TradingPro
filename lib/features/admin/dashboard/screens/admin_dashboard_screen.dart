import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/deposit_model.dart';
import 'package:tradingpro/models/withdrawal_model.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final recentAsync = ref.watch(adminRecentActivityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
          ref.invalidate(adminRecentActivityProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── Header Section ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Executive Dashboard', style: AppTextStyles.h2),
                          const SizedBox(height: 4),
                          Text(
                            'Real-time administrative platform statistics and recent queue activities.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                      icon: const Icon(Icons.campaign_rounded, size: 18),
                      label: const Text('New Broadcast'),
                      onPressed: () => context.go('/admin/notifications'),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Stats Cards Grid ────────────────────────────────────────────
            statsAsync.when(
              data: (stats) {
                return SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.crossAxisExtent >= 1100
                          ? 4
                          : constraints.crossAxisExtent >= 650
                              ? 2
                              : 1;

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.65,
                        ),
                        delegate: SliverChildListDelegate([
                          _StatCard(
                            title: 'Total Users',
                            value: '${stats.totalUsers}',
                            subtitle: '${stats.activeUsers} active accounts',
                            icon: Icons.people_rounded,
                            color: AppColors.primary,
                            onTap: () => context.go('/admin/users'),
                          ),
                          _StatCard(
                            title: 'Pending Deposits',
                            value: '${stats.pendingDeposits}',
                            subtitle: 'Awaiting credit review',
                            icon: Icons.arrow_downward_rounded,
                            color: AppColors.pending,
                            onTap: () => context.go('/admin/deposits'),
                          ),
                          _StatCard(
                            title: 'Pending Withdrawals',
                            value: '${stats.pendingWithdrawals}',
                            subtitle: 'Awaiting payout settlement',
                            icon: Icons.arrow_upward_rounded,
                            color: AppColors.negative,
                            onTap: () => context.go('/admin/withdrawals'),
                          ),
                          _StatCard(
                            title: 'Open Trades',
                            value: '${stats.openTrades}',
                            subtitle: 'Active market positions',
                            icon: Icons.candlestick_chart_rounded,
                            color: AppColors.positive,
                            onTap: () => context.go('/admin/trades'),
                          ),
                          _StatCard(
                            title: 'Open Support Chats',
                            value: '${stats.openSupportChats}',
                            subtitle: 'Active support tickets',
                            icon: Icons.headset_mic_rounded,
                            color: AppColors.primary,
                            onTap: () => context.go('/admin/support'),
                          ),
                          _StatCard(
                            title: 'New Messages',
                            value: '${stats.newMessages}',
                            subtitle: 'Unread customer messages',
                            icon: Icons.mark_chat_unread_rounded,
                            color: stats.newMessages > 0
                                ? AppColors.pending
                                : AppColors.gray500,
                            onTap: () => context.go('/admin/support'),
                          ),
                          _StatCard(
                            title: 'Total User Balances',
                            value: AppFormatters.currency(
                                stats.totalPlatformBalance),
                            subtitle: 'Platform user liabilities',
                            icon: Icons.account_balance_rounded,
                            color: AppColors.positive,
                          ),
                          _StatCard(
                            title: 'Total Profit Awarded',
                            value: AppFormatters.currency(
                                stats.totalProfitAwarded),
                            subtitle: 'Cumulative awarded profits',
                            icon: Icons.monetization_on_rounded,
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            title: 'Audit Logs',
                            value: 'Secured',
                            subtitle: 'Tamper-evident trail',
                            icon: Icons.security_rounded,
                            color: AppColors.gray700,
                            onTap: () => context.go('/admin/audit-logs'),
                          ),
                        ]),
                      );
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ErrorStateWidget(
                    message: 'Failed to load platform statistics',
                    onRetry: () => ref.invalidate(adminDashboardStatsProvider),
                  ),
                ),
              ),
            ),

            // ─── Recent Activity Section ───────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Queue Activity', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            recentAsync.when(
              data: (recent) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.crossAxisExtent >= 900;
                      if (isWide) {
                        return SliverToBoxAdapter(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDepositsSection(
                                    context, recent.recentDeposits),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildWithdrawalsSection(
                                    context, recent.recentWithdrawals),
                                ),
                              ],
                            ),
                        );
                      } else {
                        return SliverList(
                          delegate: SliverChildListDelegate([
                            _buildDepositsSection(
                                context, recent.recentDeposits),
                            const SizedBox(height: 20),
                            _buildWithdrawalsSection(
                                context, recent.recentWithdrawals),
                          ]),
                        );
                      }
                    },
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: ErrorStateWidget(
                    message: 'Recent activity: $e',
                    onRetry: () => ref.invalidate(adminRecentActivityProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositsSection(
      BuildContext context, List<DepositModel> deposits) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Text('Recent Deposits', style: AppTextStyles.h4),
              TextButton(
                onPressed: () => context.go('/admin/deposits'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (deposits.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No recent deposits.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deposits.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, i) {
                final d = deposits[i];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.positiveLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_downward_rounded,
                          size: 16, color: AppColors.positive),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${d.userFullName} (ID: ${d.userId7})',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${d.asset} • ${AppFormatters.time(d.createdAt)}',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+\$${d.amount.toStringAsFixed(2)}',
                          style: AppTextStyles.captionMedium.copyWith(
                            color: AppColors.positive,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        StatusBadge(
                          label: d.status.name.toUpperCase(),
                          type: d.isApproved
                              ? StatusType.success
                              : d.isPending
                                  ? StatusType.pending
                                  : StatusType.error,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalsSection(
      BuildContext context, List<WithdrawalModel> withdrawals) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Text('Recent Withdrawals', style: AppTextStyles.h4),
              TextButton(
                onPressed: () => context.go('/admin/withdrawals'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (withdrawals.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No recent withdrawals.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: withdrawals.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, i) {
                final w = withdrawals[i];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.negativeLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded,
                          size: 16, color: AppColors.negative),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${w.userFullName} (ID: ${w.userId7})',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${w.asset} • ${AppFormatters.time(w.createdAt)}',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '-\$${w.amount.toStringAsFixed(2)}',
                          style: AppTextStyles.captionMedium.copyWith(
                            color: AppColors.negative,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        StatusBadge(
                          label: w.status.name.toUpperCase(),
                          type: w.isApproved
                              ? StatusType.success
                              : w.isPending
                                  ? StatusType.pending
                                  : StatusType.error,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
                Text(
                  title,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
