import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_validators.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class MandatoryChangePasswordDialog extends ConsumerStatefulWidget {
  const MandatoryChangePasswordDialog({super.key});

  static bool isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (isShowing) return;
    isShowing = true;
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const MandatoryChangePasswordDialog(),
      );
    } finally {
      isShowing = false;
    }
  }

  @override
  ConsumerState<MandatoryChangePasswordDialog> createState() =>
      _MandatoryChangePasswordDialogState();
}

class _MandatoryChangePasswordDialogState
    extends ConsumerState<MandatoryChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tempPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureTemp = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _tempPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final tempPass = _tempPasswordCtrl.text.trim();
    final newPass = _newPasswordCtrl.text.trim();

    if (tempPass == newPass) {
      setState(() {
        _error =
            'New password cannot be the same as your temporary password. Please choose a different new password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).updateTemporaryPassword(
            temporaryPassword: tempPass,
            newPassword: newPass,
          );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Password updated successfully! Welcome to TradingPro.'),
            backgroundColor: AppColors.positive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '').trim();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header ─────────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Change Temporary Password',
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'You logged in with a temporary password. For account security, you must set a permanent new password to continue.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Temporary Password ─────────────────────────────────
                  TextFormField(
                    controller: _tempPasswordCtrl,
                    obscureText: _obscureTemp,
                    decoration: InputDecoration(
                      labelText: 'Temporary Password',
                      hintText: 'Enter your temporary password',
                      prefixIcon: const Icon(Icons.password_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureTemp
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureTemp = !_obscureTemp),
                      ),
                    ),
                    validator: (v) =>
                        AppValidators.required(v, 'Temporary password'),
                  ),
                  const SizedBox(height: 16),

                  // ─── New Password ───────────────────────────────────────
                  TextFormField(
                    controller: _newPasswordCtrl,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Minimum 6 characters',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) {
                      final valErr = AppValidators.password(v);
                      if (valErr != null) return valErr;
                      if (v != null &&
                          _tempPasswordCtrl.text.isNotEmpty &&
                          v.trim() == _tempPasswordCtrl.text.trim()) {
                        return 'Cannot match temporary password.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ─── Confirm New Password ───────────────────────────────
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      hintText: 'Re-enter your new password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) => AppValidators.confirmPassword(
                        v, _newPasswordCtrl.text),
                  ),

                  // ─── Error Box ──────────────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.negativeLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.negative.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 18, color: AppColors.negative),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.negative),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ─── Submit Button ──────────────────────────────────────
                  PrimaryButton(
                    label: 'Set New Password & Continue',
                    onPressed: _submit,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
