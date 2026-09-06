import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/audit_log_model.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class AdminAuditLogsScreen extends ConsumerStatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  ConsumerState<AdminAuditLogsScreen> createState() =>
      _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends ConsumerState<AdminAuditLogsScreen> {
  String? _selectedTargetType;
  final _searchCtrl = TextEditingController();
  String _query = '';

  final _targetFilters = [
    ('All Actions', null),
    ('Deposits', 'deposit'),
    ('Withdrawals', 'withdrawal'),
    ('Users & Profits', 'user'),
    ('Trades', 'trade'),
    ('Coins', 'coin'),
    ('Settings', 'settings'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showLogDetailsDialog(AuditLogModel log) {
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
              child: const Icon(Icons.security_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Audit Record Details', style: AppTextStyles.h3),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Action:', log.action),
              _detailRow('Target Type:', log.targetType.toUpperCase()),
              _detailRow('Target ID:', log.targetId),
              if (log.userId != null) _detailRow('User UID:', log.userId!),
              _detailRow('Admin UID:', log.adminUid),
              _detailRow(
                  'Timestamp:', AppFormatters.dateTime(log.createdAt)),
              if (log.description != null)
                _detailRow('Description:', log.description!),
              const SizedBox(height: 12),
              Text('Metadata Payload:', style: AppTextStyles.captionMedium),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(log.metadata),
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    color: AppColors.textPrimary,
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
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.captionMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auditLogsAsync =
        ref.watch(adminAuditLogsProvider(_selectedTargetType));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Immutable Audit Trail', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              'Comprehensive tamper-evident record of all administrative financial operations and security events.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),

            // Target Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _targetFilters.map((f) {
                  final isSelected = _selectedTargetType == f.$2;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.$1),
                      selected: isSelected,
                      selectedColor: AppColors.primaryContainer,
                      checkmarkColor: AppColors.primary,
                      labelStyle: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedTargetType = f.$2);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Search by ID/action
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by Action, Target ID, or User ID...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: auditLogsAsync.when(
                data: (logs) {
                  final filtered = logs.where((l) {
                    return l.action.toLowerCase().contains(_query) ||
                        l.targetId.toLowerCase().contains(_query) ||
                        (l.userId?.toLowerCase().contains(_query) ?? false) ||
                        (l.description?.toLowerCase().contains(_query) ?? false);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No Audit Records',
                      message: 'No administrative actions recorded under this filter.',
                      icon: Icons.history_rounded,
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final log = filtered[i];
                      return Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.divider, width: 0.5),
                          ),
                          child: ListTile(
                            onTap: () => _showLogDetailsDialog(log),
                            leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getActionColor(log.action).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getActionIcon(log.action),
                              color: _getActionColor(log.action),
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                log.action,
                                style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.gray100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log.targetType.toUpperCase(),
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Target: ${log.targetId} • ${AppFormatters.dateTime(log.createdAt)}',
                            style: AppTextStyles.caption,
                          ),
                          trailing: const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => ErrorStateWidget(
                  message: 'Failed to load audit trail',
                  onRetry: () => ref.invalidate(
                      adminAuditLogsProvider(_selectedTargetType)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    if (action.contains('APPROVE') || action.contains('PROFIT')) {
      return AppColors.positive;
    }
    if (action.contains('REJECT') || action.contains('SUSPEND')) {
      return AppColors.negative;
    }
    return AppColors.primary;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('DEPOSIT')) return Icons.arrow_downward_rounded;
    if (action.contains('WITHDRAWAL')) return Icons.arrow_upward_rounded;
    if (action.contains('PROFIT')) return Icons.monetization_on_rounded;
    if (action.contains('TRADE')) return Icons.candlestick_chart_rounded;
    return Icons.settings_suggest_rounded;
  }
}
