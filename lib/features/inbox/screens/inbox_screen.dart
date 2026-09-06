import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/notification_model.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inbox'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: currentUserId == null
                ? null
                : () async {
                    await ref
                        .read(notificationRepositoryProvider)
                        .markAllAsRead(currentUserId);
                  },
            child: Text(
              'Mark all read',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Notifications',
              message: 'Updates regarding your deposits, withdrawals, and profits will appear here.',
              icon: Icons.notifications_none_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationCard(
                notification: notif,
                onTap: () async {
                  if (!notif.isRead && currentUserId != null) {
                    try {
                      await ref
                          .read(notificationRepositoryProvider)
                          .markAsRead(currentUserId, notif.notificationId);
                    } catch (e) {
                      debugPrint('Error marking notification as read: $e');
                    }
                  }
                },
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const SkeletonBox(
            width: double.infinity,
            height: 90,
            borderRadius: 16,
          ),
        ),
        error: (e, _) {
          debugPrint('Inbox Error: $e');
          return ErrorStateWidget(
            message: 'Could not load notifications: $e',
            onRetry: () => ref.invalidate(notificationsProvider),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, bgColor) = _getTypeStyle(notification.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : AppColors.primary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? AppColors.divider
                : AppColors.primary.withOpacity(0.2),
            width: notification.isRead ? 0.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppFormatters.dateTime(notification.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _getTypeStyle(NotificationType type) {
    switch (type) {
      case NotificationType.depositSubmitted:
        return (
          Icons.arrow_downward_rounded,
          AppColors.pending,
          AppColors.pendingLight
        );
      case NotificationType.depositApproved:
        return (
          Icons.check_circle_outline_rounded,
          AppColors.positive,
          AppColors.positiveLight
        );
      case NotificationType.depositRejected:
        return (
          Icons.cancel_outlined,
          AppColors.negative,
          AppColors.negativeLight
        );
      case NotificationType.withdrawalApproved:
        return (
          Icons.arrow_upward_rounded,
          AppColors.positive,
          AppColors.positiveLight
        );
      case NotificationType.withdrawalRejected:
        return (
          Icons.cancel_outlined,
          AppColors.negative,
          AppColors.negativeLight
        );
      case NotificationType.profitAwarded:
        return (
          Icons.monetization_on_outlined,
          AppColors.positive,
          AppColors.positiveLight
        );
      case NotificationType.tradeOpened:
        return (
          Icons.play_circle_outline_rounded,
          AppColors.primary,
          AppColors.primaryContainer
        );
      case NotificationType.tradeCancelled:
        return (
          Icons.cancel_outlined,
          AppColors.negative,
          AppColors.negativeLight
        );
      case NotificationType.tradeProfit:
        return (
          Icons.trending_up_rounded,
          AppColors.positive,
          AppColors.positiveLight
        );
      case NotificationType.tradeLoss:
        return (
          Icons.trending_down_rounded,
          AppColors.negative,
          AppColors.negativeLight
        );
      case NotificationType.supportMessage:
        return (
          Icons.chat_bubble_outline_rounded,
          AppColors.primary,
          AppColors.primaryContainer
        );
      case NotificationType.adminMessage:
        return (
          Icons.admin_panel_settings_outlined,
          AppColors.primary,
          AppColors.primaryContainer
        );
      case NotificationType.broadcast:
        return (
          Icons.campaign_rounded,
          AppColors.primary,
          AppColors.primaryContainer
        );
      case NotificationType.system:
        return (
          Icons.info_outline_rounded,
          AppColors.gray600,
          AppColors.gray100
        );
    }
  }
}
