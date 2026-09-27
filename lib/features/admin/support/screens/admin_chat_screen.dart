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

class AdminChatScreen extends ConsumerStatefulWidget {
  final SupportConversationModel conversation;
  const AdminChatScreen({super.key, required this.conversation});

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  Uint8List? _attachedBytes;
  String? _attachedFileName;

  @override
  void initState() {
    super.initState();
    // Mark as read by admin upon opening
    Future.microtask(() {
      ref
          .read(supportRepositoryProvider)
          .markReadByAdmin(widget.conversation.conversationId);
    });
  }

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
              Text('Attach File or Image', style: AppTextStyles.h4),
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
                title: const Text('Choose from Gallery / Files'),
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

  Future<void> _sendAdminMessage() async {
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
      final currentUserId = ref.read(currentUserIdProvider) ?? 'admin';
      String? attachmentUrl;

      if (bytesToSend != null) {
        attachmentUrl = await ref
            .read(supportRepositoryProvider)
            .uploadSupportAttachment(
              conversationId: widget.conversation.conversationId,
              bytes: bytesToSend,
              fileName: fileNameToSend ?? 'admin_attachment.jpg',
            );
      }

      await ref.read(supportRepositoryProvider).sendMessage(
            conversationId: widget.conversation.conversationId,
            senderId: currentUserId,
            senderRole: MessageSenderRole.admin,
            senderName: 'Support Representative',
            content: text,
            userId: widget.conversation.userId,
            attachmentUrl: attachmentUrl,
            messageType: attachmentUrl != null ? 'image' : 'text',
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reply: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _toggleClose() async {
    setState(() => _isSending = true);
    try {
      final settings = ref.read(appSettingsProvider).valueOrNull;
      final closeMsg = settings?.supportAutoCloseMessage ??
          'This conversation has been closed by the support representative.';

      await ref.read(supportRepositoryProvider).closeConversation(
            widget.conversation.conversationId,
            systemMessage: closeMsg,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation closed successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error closing chat: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showImageViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Attachment Preview'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    tooltip: 'Open full size in browser',
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
                            'Failed to load image directly.',
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
    final messagesAsync = ref.watch(
      conversationMessagesProvider(widget.conversation.conversationId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.conversation.userFullName} (ID: ${widget.conversation.userId7})',
              style: AppTextStyles.h4,
            ),
            Text(
              widget.conversation.userEmail,
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Close Conversation',
            icon: const Icon(Icons.archive_outlined),
            onPressed: _toggleClose,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                if (messages.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No messages yet',
                    message: 'Reply below to start assisting the user.',
                    icon: Icons.chat_bubble_outline_rounded,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isAdmin = msg.isAdmin;
                    final isSystem = msg.isSystem;
                    final hasAttachment = msg.hasAttachment;

                    if (isSystem) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              msg.content,
                              style: AppTextStyles.caption.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: isAdmin
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isAdmin) ...[
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded,
                                  size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isAdmin ? 16 : 4),
                                  bottomRight: Radius.circular(isAdmin ? 4 : 16),
                                ),
                                border: isAdmin
                                    ? null
                                    : Border.all(
                                        color: AppColors.divider, width: 0.5),
                              ),
                              child: Column(
                                crossAxisAlignment: isAdmin
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (hasAttachment) ...[
                                    GestureDetector(
                                      onTap: () => _showImageViewer(
                                          context, msg.attachmentUrl!),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxHeight: 240,
                                            maxWidth: 280,
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.network(
                                                msg.attachmentUrl!,
                                                fit: BoxFit.cover,
                                                loadingBuilder:
                                                    (_, child, progress) =>
                                                        progress == null
                                                            ? child
                                                            : Container(
                                                                height: 140,
                                                                width: 200,
                                                                color: isAdmin
                                                                    ? Colors
                                                                        .white12
                                                                    : AppColors
                                                                        .surfaceVariant,
                                                                child:
                                                                    const Center(
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color: AppColors
                                                                        .primary,
                                                                  ),
                                                                ),
                                                              ),
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  color: isAdmin
                                                      ? Colors.white12
                                                      : AppColors
                                                          .surfaceVariant,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                          Icons.image_outlined,
                                                          color: isAdmin
                                                              ? Colors.white
                                                              : AppColors
                                                                  .textPrimary,
                                                          size: 20),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'View Attachment',
                                                        style: TextStyle(
                                                          color: isAdmin
                                                              ? Colors.white
                                                              : AppColors
                                                                  .textPrimary,
                                                          fontSize: 12,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
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
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
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
                                    if (msg.content.isNotEmpty)
                                      const SizedBox(height: 8),
                                  ],
                                  if (msg.content.isNotEmpty)
                                    Text(
                                      msg.content,
                                      style: AppTextStyles.body.copyWith(
                                        color: isAdmin
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppFormatters.dateTime(msg.createdAt),
                                    style: AppTextStyles.caption.copyWith(
                                      color: isAdmin
                                          ? Colors.white70
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
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => ErrorStateWidget(
                message: 'Failed to load message thread',
              ),
            ),
          ),

          // Attached File Preview Banner
          if (_attachedBytes != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          'File ready to send',
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

          // Message Input
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      decoration: InputDecoration(
                        hintText: _attachedBytes != null
                            ? 'Add a caption (optional)...'
                            : 'Type administrative reply...',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendAdminMessage(),
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
                      onPressed: _isSending ? null : _sendAdminMessage,
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
