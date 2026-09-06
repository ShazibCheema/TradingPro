import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _userId7Ctrl = TextEditingController();
  bool _isBroadcast = true;
  bool _isSending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _userId7Ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and Message Body are required.'),
          backgroundColor: AppColors.negative,
        ),
      );
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: _isBroadcast ? 'Broadcast to All Users?' : 'Send Direct Notification?',
      message: _isBroadcast
          ? 'This message will be dispatched to every registered platform user.\n\nTitle: $title'
          : 'This message will be sent to User 7-Digit ID: ${_userId7Ctrl.text.trim()}.\n\nTitle: $title',
      confirmLabel: 'Send Message',
      onConfirm: () {},
    );

    if (confirmed != true) return;

    setState(() => _isSending = true);

    try {
      String? targetUid;
      if (!_isBroadcast) {
        final targetUser = await ref
            .read(userRepositoryProvider)
            .getUserByUserId7(_userId7Ctrl.text.trim());
        if (targetUser == null) {
          throw Exception(
              'No user found with 7-digit ID: ${_userId7Ctrl.text.trim()}');
        }
        targetUid = targetUser.uid;
      }

      await ref.read(adminRepositoryProvider).sendNotification(
            targetUserId: targetUid,
            targetUserId7:
                !_isBroadcast ? _userId7Ctrl.text.trim() : null,
            title: title,
            body: body,
          );

      if (mounted) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _userId7Ctrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification dispatched successfully!'),
            backgroundColor: AppColors.positive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(adminBroadcastNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notification Dispatcher', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              'Compose push notifications and inbox alerts directly to specific users or broadcast platform-wide.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),

            // Composer Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Compose Message', style: AppTextStyles.h4),
                  const SizedBox(height: 16),

                  // Scope selector
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('Broadcast (All Users)'),
                        selected: _isBroadcast,
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: TextStyle(
                          color: _isBroadcast
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (v) {
                          if (v) setState(() => _isBroadcast = true);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Specific User (7-Digit ID)'),
                        selected: !_isBroadcast,
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: TextStyle(
                          color: !_isBroadcast
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (v) {
                          if (v) setState(() => _isBroadcast = false);
                        },
                      ),
                    ],
                  ),

                  if (!_isBroadcast) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _userId7Ctrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Recipient 7-Digit User ID (e.g. 5832147)',
                        prefixIcon: Icon(Icons.person_pin_rounded),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notification Title',
                      hintText: 'e.g. System Maintenance or Deposit Bonus',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bodyCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Message Body',
                      hintText: 'Type complete notification content...',
                      prefixIcon: Icon(Icons.message_rounded),
                    ),
                  ),

                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _isBroadcast
                        ? 'Broadcast to All Users'
                        : 'Send Direct Message',
                    onPressed: _sendNotification,
                    isLoading: _isSending,
                    width: 240,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // History Title
            Text('Notification Dispatch History', style: AppTextStyles.h3),
            const SizedBox(height: 12),

            historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Broadcast History',
                    message: 'Past administrative messages will be logged here.',
                    icon: Icons.notifications_none_rounded,
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = history[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.divider, width: 0.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: item.isBroadcast
                                  ? AppColors.primaryContainer
                                  : AppColors.positiveLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.isBroadcast
                                  ? Icons.campaign_rounded
                                  : Icons.person_rounded,
                              color: item.isBroadcast
                                  ? AppColors.primary
                                  : AppColors.positive,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      item.isBroadcast
                                          ? 'BROADCAST'
                                          : 'ID: ${item.targetUserId7 ?? "Direct"}',
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: item.isBroadcast
                                            ? AppColors.primary
                                            : AppColors.positive,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.body,
                                  style: AppTextStyles.bodySmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppFormatters.dateTime(item.createdAt),
                                  style: AppTextStyles.caption.copyWith(
                                      fontSize: 10),
                                ),
                              ],
                            ),
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
                message: 'Failed to load dispatch history',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
