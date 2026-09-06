import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';
import 'package:tradingpro/shared_widgets/legal_dialogs.dart';
import 'package:tradingpro/router/user_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // ─── Profile Header Card ───────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.fullName,
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // User ID Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'USER ID: ',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              user.userId7,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: user.userId7));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User ID copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Settings & Options List ──────────────────────────────
                _ProfileSection(
                  title: 'Account Settings',
                  items: [
                    _ProfileItem(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      onTap: () => context.push(AppRoutes.changePassword),
                    ),
                    _ProfileItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Withdraw Details',
                      subtitle: 'Save preferred crypto addresses',
                      onTap: () => context.push(AppRoutes.withdrawDetails),
                    ),
                    _ProfileItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notification Settings',
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                    _ProfileItem(
                      icon: Icons.person_remove_outlined,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your account and data',
                      iconColor: AppColors.negative,
                      textColor: AppColors.negative,
                      onTap: () => _showDeleteAccountDialog(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _ProfileSection(
                  title: 'Legal & Policies',
                  items: [
                    _ProfileItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () => LegalDialogs.showPrivacyPolicy(context),
                    ),
                    _ProfileItem(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      onTap: () => LegalDialogs.showTermsOfService(context),
                    ),
                    _ProfileItem(
                      icon: Icons.warning_amber_rounded,
                      title: 'Risk Disclosure & Disclaimer',
                      onTap: () => LegalDialogs.showRiskDisclosure(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _ProfileSection(
                  title: 'Support & Info',
                  items: [
                    _ProfileItem(
                      icon: Icons.headset_mic_outlined,
                      title: 'Customer Support',
                      subtitle: 'Live conversation with admin',
                      onTap: () => context.push(AppRoutes.support),
                    ),
                    _ProfileItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About TradingPro',
                      subtitle: 'Version 1.0.0 (I&T)',
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Logout Button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutConfirm(context, ref),
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.negative, size: 18),
                    label: Text(
                      'Logout',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.negative,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.negative, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => ErrorStateWidget(
          message: 'Failed to load profile',
          onRetry: () => ref.invalidate(userProvider),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final passwordCtrl = TextEditingController();
    bool isDeleting = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.negative, size: 28),
              const SizedBox(width: 8),
              Text('Delete Account', style: AppTextStyles.h4.copyWith(color: AppColors.negative)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action is irreversible. All your profile information and active sessions will be permanently deleted.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your password to confirm deletion:',
                style: AppTextStyles.captionMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Current password',
                  errorText: errorText,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.negative,
                foregroundColor: Colors.white,
              ),
              onPressed: isDeleting
                  ? null
                  : () async {
                      final pwd = passwordCtrl.text.trim();
                      if (pwd.isEmpty) {
                        setState(() => errorText = 'Password is required');
                        return;
                      }

                      setState(() {
                        isDeleting = true;
                        errorText = null;
                      });

                      try {
                        await ref.read(authRepositoryProvider).deleteAccount(password: pwd);
                        if (dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop();
                        }
                      } catch (e) {
                        setState(() {
                          isDeleting = false;
                          errorText = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Delete Permanently'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.show_chart_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text('TradingPro: I&T', style: AppTextStyles.h4),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Investing & Trading Platform',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'TradingPro is an admin-managed investing and trading platform providing transparent financial records and real-time support.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            Text('Version: 1.0.0 (Production Build)',
                style: AppTextStyles.caption),
          ],
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

  void _showLogoutConfirm(BuildContext context, WidgetRef ref) {
    ConfirmDialog.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to sign out of your account?',
      confirmLabel: 'Logout',
      isDestructive: true,
      onConfirm: () async {
        await ref.read(authRepositoryProvider).signOut();
      },
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileItem> items;

  const _ProfileSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                return Column(
                  children: [
                    ListTile(
                      onTap: item.onTap,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item.iconColor != null
                              ? item.iconColor!.withOpacity(0.12)
                              : AppColors.gray100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon,
                            color: item.iconColor ?? AppColors.textPrimary, size: 18),
                      ),
                      title: Text(
                        item.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: item.textColor ?? AppColors.textPrimary,
                        ),
                      ),
                      subtitle: item.subtitle != null
                          ? Text(item.subtitle!, style: AppTextStyles.caption)
                          : null,
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.gray400,
                      ),
                    ),
                    if (index < items.length - 1) const Divider(height: 0),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  _ProfileItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.textColor,
    required this.onTap,
  });
}
