import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/support_models.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String conversationId, String uid, String fullName) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      await ref.read(supportRepositoryProvider).sendMessage(
            conversationId: conversationId,
            senderId: uid,
            senderRole: MessageSenderRole.user,
            senderName: fullName,
            content: text,
            userId: uid,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
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
    final user = ref.watch(userProvider).valueOrNull;
    final convAsync = ref.watch(userConversationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Support', style: AppTextStyles.h4),
            Text(
              'Live assistance & inquiry',
              style: AppTextStyles.caption.copyWith(color: AppColors.positive),
            ),
          ],
        ),
      ),
      body: convAsync.when(
        data: (conversation) {
          if (conversation == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final messagesAsync = ref.watch(
            conversationMessagesProvider(conversation.conversationId),
          );

          return Column(
            children: [
              // Notice banner if closed
              if (!conversation.isOpen)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  color: AppColors.gray100,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.gray600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This conversation was closed due to inactivity. Sending a new message will automatically reopen it.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Messages List
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _scrollToBottom());

                    if (messages.isEmpty) {
                      return const EmptyStateWidget(
                        title: 'How can we help you?',
                        message: 'Send us a message below. Our admin team will respond promptly.',
                        icon: Icons.chat_outlined,
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return _MessageBubble(message: msg);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) {
                    debugPrint('Support Messages Error: $e');
                    return ErrorStateWidget(
                      message: 'Could not load messages: $e',
                    );
                  },
                ),
              ),

              // Message Input
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.divider, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: AppTextStyles.body
                                .copyWith(color: AppColors.textTertiary),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) {
                            if (user != null) {
                              _sendMessage(conversation.conversationId,
                                  user.uid, user.fullName);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
                          onPressed: () {
                            if (user != null) {
                              _sendMessage(conversation.conversationId,
                                  user.uid, user.fullName);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) {
          debugPrint('Support Connection Error: $e');
          return ErrorStateWidget(
            message: 'Connecting to support services: $e',
            onRetry: () => ref.invalidate(userConversationProvider),
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SupportMessageModel message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.gray600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.divider, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName.isNotEmpty
                            ? message.senderName
                            : 'Support Representative',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: AppTextStyles.body.copyWith(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.time(message.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: isUser
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
