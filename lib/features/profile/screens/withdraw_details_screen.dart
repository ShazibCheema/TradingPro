import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class WithdrawDetailsScreen extends StatefulWidget {
  const WithdrawDetailsScreen({super.key});

  @override
  State<WithdrawDetailsScreen> createState() => _WithdrawDetailsScreenState();
}

class _WithdrawDetailsScreenState extends State<WithdrawDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usdtAddressCtrl = TextEditingController();
  final _btcAddressCtrl = TextEditingController();
  final _ethAddressCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedDetails();
  }

  Future<void> _loadSavedDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usdtAddressCtrl.text = prefs.getString('saved_usdt_address') ?? '';
      _btcAddressCtrl.text = prefs.getString('saved_btc_address') ?? '';
      _ethAddressCtrl.text = prefs.getString('saved_eth_address') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_usdt_address', _usdtAddressCtrl.text.trim());
    await prefs.setString('saved_btc_address', _btcAddressCtrl.text.trim());
    await prefs.setString('saved_eth_address', _ethAddressCtrl.text.trim());

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal details saved successfully'),
          backgroundColor: AppColors.positive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usdtAddressCtrl.dispose();
    _btcAddressCtrl.dispose();
    _ethAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TradingProAppBar(title: 'Withdraw Details'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved Wallet Addresses',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Save your preferred withdrawal addresses for quick auto-fill when making a withdrawal.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 24),

                    // USDT TRC20
                    _AddressField(
                      controller: _usdtAddressCtrl,
                      label: 'USDT Address (TRC20)',
                      icon: Icons.currency_exchange_rounded,
                      hint: 'TXxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                    ),
                    const SizedBox(height: 16),

                    // BTC
                    _AddressField(
                      controller: _btcAddressCtrl,
                      label: 'Bitcoin (BTC) Address',
                      icon: Icons.currency_bitcoin_rounded,
                      hint: '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
                    ),
                    const SizedBox(height: 16),

                    // ETH
                    _AddressField(
                      controller: _ethAddressCtrl,
                      label: 'Ethereum (ETH) Address (ERC20)',
                      icon: Icons.token_rounded,
                      hint: '0x71C...849',
                    ),
                    const SizedBox(height: 32),

                    PrimaryButton(
                      label: 'Save Addresses',
                      onPressed: _save,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;

  const _AddressField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
      validator: (v) {
        if (v != null && v.isNotEmpty && v.trim().length < 10) {
          return 'Enter a valid address';
        }
        return null;
      },
    );
  }
}
