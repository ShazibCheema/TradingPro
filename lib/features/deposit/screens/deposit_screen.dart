import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_validators.dart';
import 'package:tradingpro/models/settings_models.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  DepositMethodModel? _selectedMethod;
  File? _screenshotFile;
  bool _isUploading = false;
  bool _isSubmitted = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _screenshotFile = File(picked.path);
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Could not select image: $e');
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Upload Payment Proof', style: AppTextStyles.h4),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitDeposit() async {
    if (_selectedMethod == null) {
      setState(() => _error = 'Please select a deposit method.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_screenshotFile == null) {
      setState(() => _error = 'Payment screenshot proof is required.');
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Confirm Deposit Submission',
      message:
          'You are submitting a deposit of \$${_amountCtrl.text} ${_selectedMethod!.asset} (${_selectedMethod!.network}). Ensure your transfer is complete before proceeding.',
      confirmLabel: 'Submit',
      onConfirm: () {},
    );

    if (confirmed != true) return;

    final user = ref.read(userProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final depositRepo = ref.read(depositRepositoryProvider);

      // Upload screenshot to secure Storage
      final screenshotUrl = await depositRepo.uploadScreenshot(
        user.uid,
        _screenshotFile!,
      );

      final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));

      // Submit via Cloud Function
      await depositRepo.submitDeposit(
        asset: _selectedMethod!.asset,
        network: _selectedMethod!.network,
        walletAddress: _selectedMethod!.walletAddress,
        amount: amount,
        screenshotUrl: screenshotUrl,
      );

      if (mounted) {
        setState(() {
          _isSubmitted = true;
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _buildSubmittedSuccess();
    }

    final methodsAsync = ref.watch(activeDepositMethodsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TradingProAppBar(title: 'Deposit Funds'),
      body: methodsAsync.when(
        data: (methods) {
          if (methods.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Deposit Methods Available',
              message:
                  'Deposit channels are currently undergoing scheduled maintenance. Please contact support.',
              icon: Icons.account_balance_wallet_outlined,
            );
          }

          _selectedMethod ??= methods.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Step 1 & 2: Select Currency & Network ────────────────
                  Text('1. Select Deposit Method', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: methods.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final method = methods[i];
                        final isSelected = _selectedMethod?.methodId ==
                            method.methodId;
                        return ChoiceChip(
                          label: Text('${method.asset} (${method.network})'),
                          selected: isSelected,
                          selectedColor: AppColors.primaryContainer,
                          labelStyle: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedMethod = method);
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Step 3: Deposit Address & QR Code ────────────────────
                  Text('2. Deposit Address', style: AppTextStyles.h4),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider, width: 0.5),
                    ),
                    child: Column(
                      children: [
                        // QR Code
                        if (_selectedMethod!.walletAddress.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: QrImageView(
                              data: _selectedMethod!.walletAddress,
                              version: QrVersions.auto,
                              size: 160,
                              foregroundColor: AppColors.textPrimary,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Send only ${_selectedMethod!.asset} (${_selectedMethod!.network}) to this address:',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedMethod!.walletAddress,
                                  style: AppTextStyles.captionMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Courier',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded,
                                    size: 18, color: AppColors.primary),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text: _selectedMethod!.walletAddress));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Address copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (_selectedMethod!.minimumDeposit > 0) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Minimum deposit: \$${_selectedMethod!.minimumDeposit.toStringAsFixed(2)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.pending,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Step 4: Enter Amount ─────────────────────────────────
                  Text('3. Enter Amount Sent', style: AppTextStyles.h4),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (USD equivalent / ${_selectedMethod!.asset})',
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                      hintText: 'e.g. 100.00',
                    ),
                    validator: (v) => AppValidators.positiveAmount(v),
                  ),

                  const SizedBox(height: 24),

                  // ─── Step 5: Upload Screenshot ────────────────────────────
                  Text('4. Upload Payment Proof', style: AppTextStyles.h4),
                  const SizedBox(height: 10),
                  if (_screenshotFile == null)
                    GestureDetector(
                      onTap: _showImageSourcePicker,
                      child: Container(
                        width: double.infinity,
                        height: 130,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.4),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_outlined,
                                size: 36, color: AppColors.primary),
                            const SizedBox(height: 8),
                            Text(
                              'Upload transfer screenshot',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Camera or photo gallery (JPG, PNG)',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _screenshotFile!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Screenshot attached',
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap replace to choose a different file',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.negative),
                            onPressed: () =>
                                setState(() => _screenshotFile = null),
                          ),
                        ],
                      ),
                    ),

                  // ─── Error Display ────────────────────────────────────────
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

                  // ─── Submit Button ────────────────────────────────────────
                  PrimaryButton(
                    label: 'Submit Deposit',
                    onPressed: _submitDeposit,
                    isLoading: _isUploading,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => ErrorStateWidget(
          message: 'Could not load deposit methods',
          onRetry: () => ref.invalidate(activeDepositMethodsProvider),
        ),
      ),
    );
  }

  Widget _buildSubmittedSuccess() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TradingProAppBar(title: 'Deposit Status', showBack: false),
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
                  color: AppColors.pendingLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  size: 48,
                  color: AppColors.pending,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Deposit Submitted',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your deposit has been submitted successfully. It will be reviewed and confirmed within 30 minutes to 24 hours.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const StatusBadge(label: 'Pending Review', type: StatusType.pending),
              const SizedBox(height: 36),
              PrimaryButton(
                label: 'Back to Home',
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
