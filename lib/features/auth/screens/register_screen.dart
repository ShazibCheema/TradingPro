import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_validators.dart';
import 'package:tradingpro/core/utils/app_snackbar.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';
import 'package:tradingpro/shared_widgets/legal_dialogs.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isValidatingCode = false;
  String? _error;
  String? _inviteCodeError;
  String? _validatedInviterUid;  // set after successful validation

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  /// Validates the invitation code field in real-time.
  Future<void> _validateInviteCode(String value) async {
    final code = value.trim();
    if (code.isEmpty) {
      setState(() {
        _inviteCodeError = null;
        _validatedInviterUid = null;
      });
      return;
    }
    setState(() {
      _isValidatingCode = true;
      _inviteCodeError = null;
      _validatedInviterUid = null;
    });
    try {
      final uid = await ref.read(authRepositoryProvider).validateInvitationCode(
            code: code,
            currentEmail: _emailCtrl.text.trim().isNotEmpty
                ? _emailCtrl.text.trim()
                : null,
          );
      if (mounted) {
        setState(() {
          _validatedInviterUid = uid;
          _inviteCodeError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _inviteCodeError = e.toString().replaceFirst('Exception: ', '');
          _validatedInviterUid = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isValidatingCode = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Block if invitation code is entered but invalid
    final inviteCode = _inviteCtrl.text.trim();
    if (inviteCode.isNotEmpty && _inviteCodeError != null) return;
    if (inviteCode.isNotEmpty && _validatedInviterUid == null && !_isValidatingCode) {
      // Trigger one final validation attempt
      await _validateInviteCode(inviteCode);
      if (_inviteCodeError != null) return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).registerWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
            invitedByUserId:
                inviteCode.isNotEmpty ? _validatedInviterUid : null,
          );
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Account created successfully! Welcome to TradingPro.');
      }
      // Router will auto-redirect after auth state changes
    } catch (e, stack) {
      debugPrint('🚨 [User Registration Failure]: $e');
      debugPrint('📍 [StackTrace]: $stack');

      final userFriendly = e.toString().replaceFirst('Exception: ', '').trim();
      if (mounted) {
        setState(() => _error = userFriendly);
        AppSnackbar.showError(
          context,
          error: e,
          stackTrace: stack,
          fallbackMessage: 'Account creation failed. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: AppLogo(size: 64, borderRadius: 16)),
              const SizedBox(height: 20),
              Text('Create Account', style: AppTextStyles.h1),
              const SizedBox(height: 6),
              Text(
                'Join TradingPro: I&T today',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: AppValidators.fullName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: AppValidators.email,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        helperText: 'Minimum 8 characters',
                      ),
                      validator: AppValidators.password,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          AppValidators.confirmPassword(v, _passwordCtrl.text),
                    ),
                    const SizedBox(height: 16),

                    // ── Optional Invitation Code ─────────────────────────────
                    TextFormField(
                      controller: _inviteCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 7,
                      onChanged: _validateInviteCode,
                      onFieldSubmitted: (_) => _register(),
                      decoration: InputDecoration(
                        labelText: 'Invitation Code (Optional)',
                        helperText: 'Enter your referrer\'s 7-digit User ID',
                        prefixIcon: const Icon(Icons.card_giftcard_rounded),
                        counterText: '',
                        suffixIcon: _isValidatingCode
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                            : _inviteCtrl.text.isNotEmpty
                                ? Icon(
                                    _inviteCodeError == null
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.error_outline_rounded,
                                    color: _inviteCodeError == null
                                        ? Colors.green
                                        : Colors.red,
                                  )
                                : null,
                        errorText: _inviteCodeError,
                      ),
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
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.negative,
                              size: 16,
                            ),
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

                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: 'Create Account',
                      onPressed: _register,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'By creating an account you agree to our ',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => LegalDialogs.showTermsOfService(context),
                          child: Text(
                            'Terms of Service',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          ' and ',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => LegalDialogs.showPrivacyPolicy(context),
                          child: Text(
                            'Privacy Policy',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          '.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
