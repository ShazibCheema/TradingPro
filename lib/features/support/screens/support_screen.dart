import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/support_models.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';
import 'package:tradingpro/router/user_router.dart';
import 'package:go_router/go_router.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  Uint8List? _attachedBytes;
  String? _attachedFileName;

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

  Future<void> _pickAttachment(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _attachedBytes = bytes;
          _attachedFileName = picked.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not attach image: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    }
  }

  void _showAttachmentPicker() {
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
              Text('Attach File or Photo', style: AppTextStyles.h4),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAttachment(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAttachment(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(
      String conversationId, String uid, String fullName) async {
    final text = _textController.text.trim();
    if (text.isEmpty && _attachedBytes == null) return;

    final bytesToSend = _attachedBytes;
    final fileNameToSend = _attachedFileName;

    _textController.clear();
    setState(() {
      _isSending = true;
      _attachedBytes = null;
      _attachedFileName = null;
    });

    try {
      String? attachmentUrl;
      if (bytesToSend != null) {
        attachmentUrl = await ref
            .read(supportRepositoryProvider)
            .uploadSupportAttachment(
              conversationId: conversationId,
              bytes: bytesToSend,
              fileName: fileNameToSend ?? 'attachment.jpg',
            );
      }

      await ref.read(supportRepositoryProvider).sendMessage(
            conversationId: conversationId,
            senderId: uid,
            senderRole: MessageSenderRole.user,
            senderName: fullName,
            content: text,
            userId: uid,
            attachmentUrl: attachmentUrl,
            messageType: attachmentUrl != null ? 'image' : 'text',
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

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      final isLoggedIn = ref.read(userProvider).valueOrNull != null;
      context.go(isLoggedIn ? AppRoutes.profile : AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).valueOrNull;
    final convAsync = ref.watch(userConversationProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
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
                // Account recovery banner if guest
                if (user == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: AppColors.primaryContainer,
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Account Recovery Chat: Please mention your account email and answer verification questions from support.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                          message:
                              'Send us a message or attach a screenshot below. Our support team will respond promptly.',
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
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (e, _) {
                      debugPrint('Support Messages Error: $e');
                      return ErrorStateWidget(
                        message: 'Could not load messages: $e',
                      );
                    },
                  ),
                ),

                // Attached File Preview Banner
                if (_attachedBytes != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      border: const Border(
                        top: BorderSide(color: AppColors.divider, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            _attachedBytes!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'File attached',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _attachedFileName ?? 'Image preview',
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.negative, size: 20),
                          onPressed: () => setState(() {
                            _attachedBytes = null;
                            _attachedFileName = null;
                          }),
                        ),
                      ],
                    ),
                  ),

                // Message Input Row
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(color: AppColors.divider, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.attach_file_rounded,
                              color: AppColors.primary),
                          tooltip: 'Attach photo or file',
                          onPressed: _showAttachmentPicker,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: _attachedBytes != null
                                  ? 'Add a caption (optional)...'
                                  : 'Type your message...',
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
                              final senderUid = user?.uid ?? conversation.userId;
                              final senderName = user != null && user.fullName.isNotEmpty
                                  ? user.fullName
                                  : (conversation.userFullName.isNotEmpty
                                      ? conversation.userFullName
                                      : 'Guest User');
                              _sendMessage(conversation.conversationId,
                                  senderUid, senderName);
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
                              final senderUid = user?.uid ?? conversation.userId;
                              final senderName = user != null && user.fullName.isNotEmpty
                                  ? user.fullName
                                  : (conversation.userFullName.isNotEmpty
                                      ? conversation.userFullName
                                      : 'Guest User');
                              _sendMessage(conversation.conversationId,
                                  senderUid, senderName);
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
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SupportMessageModel message;
  const _MessageBubble({required this.message});

  void _showImageViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Attachment Preview'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    tooltip: 'Open in new tab',
                    icon: const Icon(Icons.open_in_new_rounded),
                    onPressed: () async {
                      final uri = Uri.parse(imageUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              Flexible(
                child: Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                    errorBuilder: (_, error, stackTrace) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image_rounded,
                              size: 48, color: AppColors.negative),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load image preview.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Open Attachment in Browser'),
                            onPressed: () async {
                              final uri = Uri.parse(imageUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    final hasAttachment = message.hasAttachment;

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
              decoration: const BoxDecoration(
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
              padding: const EdgeInsets.all(12),
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
                      padding: const EdgeInsets.only(bottom: 6),
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
                  if (hasAttachment) ...[
                    GestureDetector(
                      onTap: () => _showImageViewer(
                          context, message.attachmentUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 220,
                            maxWidth: 260,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.network(
                                message.attachmentUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) =>
                                    progress == null
                                        ? child
                                        : Container(
                                            height: 140,
                                            width: 200,
                                            color: isUser
                                                ? Colors.white12
                                                : AppColors.surfaceVariant,
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                errorBuilder: (_, __, ___) => Container(
                                  padding: const EdgeInsets.all(12),
                                  color: isUser
                                      ? Colors.white12
                                      : AppColors.surfaceVariant,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.image_outlined,
                                          color: isUser
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'View Attachment',
                                        style: TextStyle(
                                          color: isUser
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                          fontSize: 12,
                                          decoration:
                                              TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 6,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (message.content.isNotEmpty)
                      const SizedBox(height: 8),
                  ],
                  if (message.content.isNotEmpty)
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
