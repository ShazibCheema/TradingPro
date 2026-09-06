import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/models/settings_models.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _minWithdrawalCtrl = TextEditingController();
  final _autoCloseMinCtrl = TextEditingController();
  final _autoCloseMsgCtrl = TextEditingController();
  final _depositMsgCtrl = TextEditingController();
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _minWithdrawalCtrl.dispose();
    _autoCloseMinCtrl.dispose();
    _autoCloseMsgCtrl.dispose();
    _depositMsgCtrl.dispose();
    super.dispose();
  }

  void _showDepositMethodDialog([DepositMethodModel? existing]) {
    final assetCtrl = TextEditingController(text: existing?.asset ?? 'USDT');
    final networkCtrl =
        TextEditingController(text: existing?.network ?? 'TRC20');
    final addressCtrl =
        TextEditingController(text: existing?.walletAddress ?? '');
    final minDepCtrl = TextEditingController(
        text: existing != null ? existing.minimumDeposit.toString() : '10.00');
    final orderCtrl = TextEditingController(
        text: existing != null ? existing.displayOrder.toString() : '0');
    var isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existing == null
                ? 'Add Deposit Channel'
                : 'Edit Deposit Channel',
            style: AppTextStyles.h3,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: assetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Crypto Asset (e.g. USDT, BTC, ETH)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: networkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Network (e.g. TRC20, ERC20, Bitcoin)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Admin Receiving Wallet Address',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: minDepCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Minimum Deposit Amount (\$ USD)',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Channel Active'),
                  value: isActive,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
                TextFormField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Display Order',
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
                final minDep = double.tryParse(minDepCtrl.text) ?? 10.0;
                final order = int.tryParse(orderCtrl.text) ?? 0;

                Navigator.of(ctx).pop();

                await ref.read(depositRepositoryProvider).saveDepositMethod(
                      DepositMethodModel(
                        methodId: existing?.methodId ?? '',
                        asset: assetCtrl.text.trim(),
                        network: networkCtrl.text.trim(),
                        walletAddress: addressCtrl.text.trim(),
                        minimumDeposit: minDep,
                        isActive: isActive,
                        displayOrder: order,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Deposit channel saved!'),
                      backgroundColor: AppColors.positive,
                    ),
                  );
                }
              },
              child: const Text('Save Channel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final minWithdrawal =
          double.tryParse(_minWithdrawalCtrl.text.replaceAll(',', '')) ?? 50.0;
      final autoCloseMin = int.tryParse(_autoCloseMinCtrl.text) ?? 30;

      await ref.read(settingsRepositoryProvider).updateAppSettings(
            minimumWithdrawal: minWithdrawal,
            supportAutoCloseMinutes: autoCloseMin,
            supportAutoCloseMessage: _autoCloseMsgCtrl.text.trim(),
            depositProcessingMessage: _depositMsgCtrl.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Platform configuration updated!'),
            backgroundColor: AppColors.positive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final methodsAsync = ref.watch(allDepositMethodsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Platform Settings & Controls', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              'Remotely manage platform-wide limits, auto-close timers, and deposit receiving addresses.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),

            // ─── Financial & Support Settings Card ──────────────────────────
            settingsAsync.when(
              data: (settings) {
                if (!_initialized) {
                  _minWithdrawalCtrl.text =
                      settings.minimumWithdrawal.toStringAsFixed(2);
                  _autoCloseMinCtrl.text =
                      settings.supportAutoCloseMinutes.toString();
                  _autoCloseMsgCtrl.text = settings.supportAutoCloseMessage;
                  _depositMsgCtrl.text = settings.depositProcessingMessage;
                  _initialized = true;
                }

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Rules & Defaults', style: AppTextStyles.h4),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _minWithdrawalCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Minimum User Withdrawal Limit (\$ USD)',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _autoCloseMinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText:
                              'Support Chat Inactivity Auto-Close Duration (Minutes)',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _autoCloseMsgCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Support Auto-Close System Message',
                          prefixIcon: Icon(Icons.message_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _depositMsgCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Deposit Processing Notice',
                          prefixIcon: Icon(Icons.info_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Save Platform Configuration',
                        onPressed: _saveSettings,
                        isLoading: _isSaving,
                        width: 260,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => ErrorStateWidget(
                message: 'Failed to load configuration',
              ),
            ),

            const SizedBox(height: 32),

            // ─── Deposit Methods Channels Card ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deposit Receiving Channels', style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      Text(
                        'Configured wallet addresses and networks visible to users during deposits.',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showDepositMethodDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Channel'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            methodsAsync.when(
              data: (methods) {
                if (methods.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Deposit Channels',
                    message:
                        'Users currently cannot deposit. Add a receiving crypto address.',
                    icon: Icons.account_balance_wallet_outlined,
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: methods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final m = methods[i];
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${m.asset} (${m.network})',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.walletAddress,
                                  style: AppTextStyles.captionMedium.copyWith(
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Min Deposit: \$${m.minimumDeposit.toStringAsFixed(2)} • Active: ${m.isActive}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.primary),
                            onPressed: () => _showDepositMethodDialog(m),
                          ),
                          IconButton(
                            icon: Icon(
                              m.isActive
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_outlined,
                              color: m.isActive
                                  ? AppColors.positive
                                  : AppColors.gray400,
                            ),
                            onPressed: () async {
                              await ref
                                  .read(depositRepositoryProvider)
                                  .toggleDepositMethodActive(
                                      m.methodId, !m.isActive);
                            },
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
                message: 'Failed to load deposit channels',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
