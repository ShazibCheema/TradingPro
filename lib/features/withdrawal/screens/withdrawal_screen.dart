import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/core/utils/app_validators.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _selectedAsset = 'USDT';
  String _selectedNetwork = 'TRC20';
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _error;

  final _supportedAssets = [
    ('USDT', ['TRC20', 'ERC20', 'BEP20']),
    ('BTC', ['Bitcoin']),
    ('ETH', ['ERC20', 'Arbitrum']),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_usdt_address');
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _addressCtrl.text = saved);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal(
    double availableBalance,
    double minWithdrawal,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Confirm Withdrawal Request',
      message:
          'Amount: \$${amount.toStringAsFixed(2)}\nAsset: $_selectedAsset ($_selectedNetwork)\nDestination: ${_addressCtrl.text.trim()}\n\nAre you sure you want to withdraw?',
      confirmLabel: 'Confirm',
      onConfirm: () {},
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(withdrawalRepositoryProvider).submitWithdrawal(
            amount: amount,
            asset: _selectedAsset,
            network: _selectedNetwork,
            walletAddress: _addressCtrl.text.trim(),
          );

      if (mounted) {
        setState(() {
          _isSubmitted = true;
          _isSubmitting = false;
        });
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
    if (_isSubmitted) {
      return _buildSubmittedSuccess();
    }

    final userAsync = ref.watch(userProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    final availableBalance = userAsync.valueOrNull?.balance ?? 0.0;
    final minWithdrawal =
        settingsAsync.valueOrNull?.minimumWithdrawal ?? 50.0;

    final currentNetworks = _supportedAssets
        .firstWhere((a) => a.$1 == _selectedAsset)
        .$2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TradingProAppBar(title: 'Withdraw Funds'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Available Balance Card ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Balance',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.currency(availableBalance),
                          style: AppTextStyles.financialMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Min: \$${minWithdrawal.toStringAsFixed(2)}',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Asset Selection ────────────────────────────────────────
              Text('Select Asset & Network', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              Row(
                children: _supportedAssets.map((assetData) {
                  final isSelected = _selectedAsset == assetData.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(assetData.$1),
                      selected: isSelected,
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedAsset = assetData.$1;
                            _selectedNetwork = assetData.$2.first;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Network Dropdown
              DropdownButtonFormField<String>(
                value: _selectedNetwork,
                decoration: const InputDecoration(
                  labelText: 'Network',
                  prefixIcon: Icon(Icons.hub_outlined),
                ),
                items: currentNetworks.map((net) {
                  return DropdownMenuItem(
                    value: net,
                    child: Text(net),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedNetwork = val);
                },
              ),

              const SizedBox(height: 20),

              // ─── Amount ─────────────────────────────────────────────────
              Text('Withdrawal Amount', style: AppTextStyles.h4),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (\$ USD)',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  hintText: 'e.g. 100.00',
                  suffixIcon: TextButton(
                    onPressed: () {
                      _amountCtrl.text =
                          availableBalance.toStringAsFixed(2);
                    },
                    child: const Text('MAX'),
                  ),
                ),
                validator: (v) => AppValidators.withdrawalAmount(
                  v,
                  availableBalance,
                  minWithdrawal,
                ),
              ),

              const SizedBox(height: 20),

              // ─── Destination Address ────────────────────────────────────
              Text('Recipient Address', style: AppTextStyles.h4),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: '$_selectedAsset Wallet Address',
                  hintText: 'Paste destination address',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: AppValidators.walletAddress,
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
                label: 'Confirm Withdrawal',
                onPressed: () =>
                    _submitWithdrawal(availableBalance, minWithdrawal),
                isLoading: _isSubmitting,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmittedSuccess() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TradingProAppBar(title: 'Withdrawal Submitted', showBack: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.positiveLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 48,
                  color: AppColors.positive,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Withdrawal Submitted',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your withdrawal request has been submitted for admin processing. Funds will be transferred once verified.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const StatusBadge(label: 'Pending Approval', type: StatusType.pending),
              const SizedBox(height: 36),
              PrimaryButton(
                label: 'Back to Account',
                onPressed: () => Navigator.of(context).pop(),
                width: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
