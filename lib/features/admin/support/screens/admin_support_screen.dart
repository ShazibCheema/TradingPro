import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';
import 'admin_chat_screen.dart';

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() =>
      _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportAsync = ref.watch(adminAllSupportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Support Inquiries', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              'Live chat with users. Inactive chats auto-close after 30 minutes server-side.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by User Name, Email, or 7-digit ID...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: supportAsync.when(
                data: (conversations) {
                  final filtered = conversations.where((c) {
                    return c.userFullName.toLowerCase().contains(_query) ||
                        c.userEmail.toLowerCase().contains(_query) ||
                        c.userId7.toLowerCase().contains(_query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No Support Conversations',
                      message: 'Support inquiries will appear here.',
                      icon: Icons.chat_bubble_outline_rounded,
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final conv = filtered[i];
                      return Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminChatScreen(conversation: conv),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: conv.unreadByAdmin > 0
                                    ? AppColors.primary
                                    : AppColors.divider,
                                width: conv.unreadByAdmin > 0 ? 1.5 : 0.5,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                conv.userFullName,
                                style: AppTextStyles.body
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ID: ${conv.userId7}',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              StatusBadge(
                                label: conv.status.name.toUpperCase(),
                                type: conv.isOpen
                                    ? StatusType.success
                                    : StatusType.neutral,
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                conv.lastMessage ?? 'No messages yet.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: conv.unreadByAdmin > 0
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontWeight: conv.unreadByAdmin > 0
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (conv.lastMessageAt != null)
                                Text(
                                  'Updated: ${AppFormatters.dateTime(conv.lastMessageAt!)}',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                          trailing: conv.unreadByAdmin > 0
                              ? Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${conv.unreadByAdmin}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: AppColors.gray400),
                        ),
                      ),
                    ),
                  );
                },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => ErrorStateWidget(
                  message: 'Failed to load support chats',
                  onRetry: () => ref.invalidate(adminAllSupportProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
