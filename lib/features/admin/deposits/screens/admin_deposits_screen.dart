import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/core/utils/app_snackbar.dart';
import 'package:tradingpro/models/deposit_model.dart';
import 'package:tradingpro/models/settings_models.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class AdminDepositsScreen extends ConsumerStatefulWidget {
  const AdminDepositsScreen({super.key});

  @override
  ConsumerState<AdminDepositsScreen> createState() =>
      _AdminDepositsScreenState();
}

class _AdminDepositsScreenState extends ConsumerState<AdminDepositsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _filters = [
    ('Pending', DepositStatus.pending),
    ('Approved', DepositStatus.approved),
    ('Rejected', DepositStatus.rejected),
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

  void _showAddDepositAddressDialog([DepositMethodModel? existing]) {
    final assetCtrl = TextEditingController(text: existing?.asset ?? 'USDT');
    final networkCtrl = TextEditingController(text: existing?.network ?? 'TRC20');
    final addressCtrl = TextEditingController(text: existing?.walletAddress ?? '');
    final minDepCtrl = TextEditingController(
        text: existing != null ? existing.minimumDeposit.toString() : '50');
    final instructionsCtrl =
        TextEditingController(text: existing?.instructions ?? '');
    var isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sbCtx, setDialogState) {
          final isMobile = MediaQuery.of(sbCtx).size.width < 600;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: 24,
            ),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              elevation: 24,
              child: Container(
                width: isMobile ? double.infinity : 500,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sbCtx).size.height * 0.88,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing == null ? 'Add Deposit Address' : 'Edit Deposit Address',
                          style: AppTextStyles.h3.copyWith(fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: assetCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Asset / Currency (e.g. USDT, BTC, ETH)',
                                hintText: 'e.g. USDT',
                                prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: networkCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Network (e.g. TRC20, ERC20, BEP20)',
                                hintText: 'e.g. TRC20',
                                prefixIcon: Icon(Icons.hub_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: addressCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Wallet Deposit Address',
                                hintText: 'Paste public crypto address here...',
                                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: minDepCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Minimum Deposit (\$ USD)',
                                hintText: '50.00',
                                prefixIcon: Icon(Icons.attach_money_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: instructionsCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Special Deposit Instructions (Optional)',
                                hintText: 'e.g. Send exact amount. Take screenshot of TXID.',
                                prefixIcon: Icon(Icons.info_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Active for Users', style: TextStyle(fontSize: 13)),
                              subtitle: const Text('Allow users to select this deposit address', style: TextStyle(fontSize: 11)),
                              value: isActive,
                              activeColor: AppColors.primary,
                              onChanged: (v) => setDialogState(() => isActive = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final asset = assetCtrl.text.trim().toUpperCase();
                            final network = networkCtrl.text.trim().toUpperCase();
                            final address = addressCtrl.text.trim();
                            final minDep = double.tryParse(minDepCtrl.text.trim()) ?? 0.0;
                            final instructions = instructionsCtrl.text.trim();

                            if (asset.isEmpty || network.isEmpty || address.isEmpty) {
                              AppSnackbar.showWarning(
                                sbCtx,
                                message: 'Please provide Asset, Network, and Wallet Address.',
                              );
                              return;
                            }

                            Navigator.of(dialogCtx).pop();

                            try {
                              final repo = ref.read(depositRepositoryProvider);
                              await repo.saveDepositMethod(
                                DepositMethodModel(
                                  methodId: existing?.methodId ?? '',
                                  asset: asset,
                                  network: network,
                                  walletAddress: address,
                                  minimumDeposit: minDep,
                                  instructions: instructions.isNotEmpty ? instructions : null,
                                  isActive: isActive,
                                  displayOrder: existing?.displayOrder ?? 0,
                                  createdAt: existing?.createdAt ?? DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                              );

                              if (mounted) {
                                AppSnackbar.showSuccess(
                                  context,
                                  existing == null
                                      ? 'Deposit address added successfully! Users can now see it.'
                                      : 'Deposit address updated successfully!',
                                );
                              }
                            } catch (e, stack) {
                              if (mounted) {
                                AppSnackbar.showError(
                                  context,
                                  error: e,
                                  stackTrace: stack,
                                  fallbackMessage: 'Failed to save deposit address.',
                                );
                              }
                            }
                          },
                          child: Text(existing == null ? 'Add Address' : 'Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
}

  void _showManageAddressesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final allMethodsAsync = ref.watch(allDepositMethodsProvider);

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollCtrl) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Deposit Addresses & Wallets', style: AppTextStyles.h3),
                          const SizedBox(height: 2),
                          Text(
                            'Active addresses displayed in User app for deposits.',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          // Ensure dialog shows after sheet is dismissed
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted) {
                              _showAddDepositAddressDialog();
                            }
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Address'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: allMethodsAsync.when(
                      data: (methods) {
                        if (methods.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.account_balance_wallet_outlined,
                                    size: 48, color: AppColors.gray400),
                                const SizedBox(height: 12),
                                const Text('No Deposit Addresses Configured'),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _showAddDepositAddressDialog();
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add First Deposit Address'),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollCtrl,
                          itemCount: methods.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final m = methods[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider, width: 0.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryContainer,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${m.asset} (${m.network})',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusBadge(
                                            label: m.isActive ? 'ACTIVE' : 'DISABLED',
                                            type: m.isActive
                                                ? StatusType.success
                                                : StatusType.pending,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined,
                                                size: 18, color: AppColors.primary),
                                            onPressed: () {
                                              Navigator.of(ctx).pop();
                                              Future.delayed(const Duration(milliseconds: 100), () {
                                                if (mounted) {
                                                  _showAddDepositAddressDialog(m);
                                                }
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              m.isActive
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              size: 18,
                                              color: m.isActive
                                                  ? AppColors.gray600
                                                  : AppColors.negative,
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
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          m.walletAddress,
                                          style: const TextStyle(
                                            fontFamily: 'Courier',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 16),
                                        onPressed: () {
                                          Clipboard.setData(
                                              ClipboardData(text: m.walletAddress));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Address copied'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Min Deposit: \$${m.minimumDeposit.toStringAsFixed(2)}',
                                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showApproveDialog(DepositModel deposit) {
    final creditAmountCtrl =
        TextEditingController(text: deposit.amount.toStringAsFixed(2));
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Approve Deposit', style: AppTextStyles.h3),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User: ${deposit.userFullName} (${deposit.userEmail})',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text('User 7-Digit ID: ${deposit.userId7}',
                  style: AppTextStyles.caption),
              const SizedBox(height: 12),
              Text(
                'Submitted: \$${deposit.amount.toStringAsFixed(2)} ${deposit.asset} (${deposit.network})',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: creditAmountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Account Credited Amount (\$ USD)',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Admin Note (Optional)',
                  prefixIcon: Icon(Icons.note_rounded),
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
            onPressed: () async {
              final amount =
                  double.tryParse(creditAmountCtrl.text.replaceAll(',', '')) ??
                      deposit.amount;
              Navigator.of(ctx).pop();
              await _executeApprove(deposit, amount, noteCtrl.text.trim());
            },
            child: const Text('Confirm & Credit Balance'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeApprove(
      DepositModel deposit, double amount, String note) async {
    try {
      await ref.read(depositRepositoryProvider).approveDeposit(
            depositId: deposit.depositId,
            userId: deposit.userId,
            creditedAmount: amount,
            adminNote: note.isNotEmpty ? note : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit approved and balance credited atomically!'),
            backgroundColor: AppColors.positive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve deposit: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    }
  }

  void _showRejectDialog(DepositModel deposit) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reject Deposit', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${deposit.userFullName} (ID: ${deposit.userId7})',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'e.g. Unverified transaction or invalid transfer proof',
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
                await ref.read(depositRepositoryProvider).rejectDeposit(
                      depositId: deposit.depositId,
                      userId: deposit.userId,
                      reason: reasonCtrl.text.trim().isNotEmpty
                          ? reasonCtrl.text.trim()
                          : 'Payment unverified',
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Deposit rejected.'),
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

  void _showScreenshotPreview(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment Proof Screenshot'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 500),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('Failed to load screenshot.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManageAddressesSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
        label: const Text(
          'Deposit Addresses',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) ...[
              Text('Deposit Reviews & Addresses', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(
                'Review payment screenshots and manage receiving deposit wallet addresses.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showManageAddressesSheet,
                      icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                      label: const Text('Manage Addresses'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddDepositAddressDialog(),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Address'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Deposit Reviews & Addresses', style: AppTextStyles.h2),
                        const SizedBox(height: 4),
                        Text(
                          'Inspect submitted payment screenshots and manage user deposit wallet addresses.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showManageAddressesSheet,
                        icon: const Icon(Icons.account_balance_wallet_rounded,
                            size: 18),
                        label: const Text('View All Addresses'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddDepositAddressDialog(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Deposit Address'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

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
                  final depositsAsync =
                      ref.watch(adminDepositsProvider(filter.$2));

                  return depositsAsync.when(
                    data: (deposits) {
                      if (deposits.isEmpty) {
                        return EmptyStateWidget(
                          title: 'No ${filter.$1} Deposits',
                          message:
                              'Deposits categorized as ${filter.$1.toLowerCase()} will appear here.',
                          icon: Icons.arrow_downward_rounded,
                        );
                      }

                      return ListView.separated(
                        itemCount: deposits.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final dep = deposits[i];
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
                                            '${dep.userFullName} (ID: ${dep.userId7})',
                                            style: AppTextStyles.body.copyWith(
                                                fontWeight: FontWeight.w700),
                                          ),
                                          Text(
                                            '${dep.userEmail} • ${AppFormatters.dateTime(dep.createdAt)}',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '\$${dep.amount.toStringAsFixed(2)} ${dep.asset}',
                                      style:
                                          AppTextStyles.financialMedium.copyWith(
                                        color: AppColors.positive,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Network: ${dep.network} • Target Address: ${dep.walletAddress}',
                                  style: AppTextStyles.caption.copyWith(
                                    fontFamily: 'Courier',
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    if (dep.screenshotUrl != null &&
                                        dep.screenshotUrl!.isNotEmpty)
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.image_outlined,
                                            size: 16),
                                        label: const Text('View Proof'),
                                        onPressed: () => _showScreenshotPreview(
                                            dep.screenshotUrl!),
                                      ),
                                    const Spacer(),
                                    if (dep.isPending) ...[
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.negative,
                                          side: const BorderSide(
                                              color: AppColors.negative),
                                        ),
                                        onPressed: () => _showRejectDialog(dep),
                                        child: const Text('Reject'),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.positive,
                                        ),
                                        onPressed: () => _showApproveDialog(dep),
                                        child: const Text('Approve & Credit'),
                                      ),
                                    ] else
                                      StatusBadge(
                                        label: dep.status.name.toUpperCase(),
                                        type: dep.isApproved
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
                      message: 'Failed to load deposits',
                      onRetry: () =>
                          ref.invalidate(adminDepositsProvider(filter.$2)),
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
