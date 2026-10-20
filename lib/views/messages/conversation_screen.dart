import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../services/conversation_service.dart';
import '../../services/transaction_service.dart';

class ConversationScreen extends StatefulWidget {
  final int conversationId;
  const ConversationScreen({super.key, required this.conversationId});
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final ChatController _controller;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _controller = ChatController(
      context.read<ConversationService>(),
      widget.conversationId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.startPolling();
      _controller.addListener(_scrollToBottom);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollToBottom);
    _controller.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await _controller.send(text);
  }

  Future<void> _pickAttachment() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 75, maxWidth: 1200);
    if (picked == null) return;
    setState(() => _uploadingImage = true);
    try {
      await _controller.sendImage(File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${T.of(context, 'could_not_send_image')}: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  // ---------------------------------------------------------------
  // Propose a deal (with optional proof image)
  // ---------------------------------------------------------------
  Future<void> _startDeal(BuildContext context) async {
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    File? proofImage;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(T.of(dialogCtx, 'propose_deal_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: T.of(dialogCtx, 'item_description'),
                    hintText: T.of(dialogCtx, 'item_description_hint'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: T.of(dialogCtx, 'agreed_price'),
                    prefixText: '₱ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: T.of(dialogCtx, 'notes_optional'),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 75,
                      maxWidth: 1200,
                    );
                    if (picked == null) return;
                    setDialogState(() => proofImage = File(picked.path));
                  },
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                      image: proofImage != null
                          ? DecorationImage(
                              image: FileImage(proofImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: proofImage == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: AppColors.textSecondary),
                                const SizedBox(height: 4),
                                Text(
                                  T.of(dialogCtx, 'attach_image_optional'),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(T.of(dialogCtx, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(T.of(dialogCtx, 'propose')),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !context.mounted) return;

    if (descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(T.of(context, 'item_description_required'))),
      );
      return;
    }

    try {
      await context.read<TransactionService>().propose(
            conversationId: widget.conversationId,
            itemDescription: descCtrl.text.trim(),
            agreedPrice: double.tryParse(priceCtrl.text.trim()),
            notes: notesCtrl.text.trim(),
            proofImage: proofImage,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.of(context, 'deal_proposed')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<ChatController>(
        builder: (context, chat, _) {
          final myId = context.watch<AuthController>().user?.id;

          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              titleSpacing: 0,
              title: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  final id = chat.otherPartyId;
                  if (id != null) context.push('/users/$id');
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chat.otherName.isNotEmpty
                            ? chat.otherName
                            : (chat.otherEmail.isEmpty
                                ? T.of(context, 'chat_title')
                                : chat.otherEmail),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        T.of(context, 'tap_to_view_profile'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.handshake_outlined),
                  tooltip: T.of(context, 'start_a_deal'),
                  onPressed: () => _startDeal(context),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // -------- Message list --------
                  Expanded(
                    child: chat.loading && chat.messages.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary))
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            itemCount: chat.messages.length,
                            itemBuilder: (_, i) {
                              final m = chat.messages[i];
                              final mine = m.senderId == myId || m.mine;
                              return Align(
                                alignment: mine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.72,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mine
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft:
                                          Radius.circular(mine ? 16 : 4),
                                      bottomRight:
                                          Radius.circular(mine ? 4 : 16),
                                    ),
                                    border: mine
                                        ? null
                                        : Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (m.attachmentUrl != null &&
                                          m.attachmentUrl!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 6),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              m.attachmentUrl!,
                                              width: 200,
                                              fit: BoxFit.cover,
                                              loadingBuilder:
                                                  (_, child, progress) {
                                                if (progress == null) {
                                                  return child;
                                                }
                                                return Container(
                                                  width: 200,
                                                  height: 140,
                                                  color: mine
                                                      ? Colors.white
                                                          .withOpacity(0.15)
                                                      : AppColors.borderSoft,
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (_, err, __) {
                                                debugPrint(
                                                    '[CHAT IMG] failed: ${m.attachmentUrl} → $err');
                                                return Container(
                                                  width: 200,
                                                  height: 120,
                                                  color: mine
                                                      ? Colors.white
                                                          .withOpacity(0.15)
                                                      : AppColors.borderSoft,
                                                  child: const Center(
                                                    child: Icon(Icons
                                                        .broken_image_outlined),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      if (m.body != null && m.body!.isNotEmpty)
                                        Text(
                                          m.body!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: mine
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                            height: 1.35,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        D.time(context, m.createdAt),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: mine
                                              ? Colors.white.withOpacity(0.75)
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  if (chat.postTitle.isNotEmpty) _PostBanner(chat: chat),

                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: _uploadingImage
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : const Icon(Icons.attach_file_rounded,
                                  color: AppColors.textSecondary),
                          onPressed: _uploadingImage ? null : _pickAttachment,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: T.of(context, 'message_hint'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _send,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PostBanner extends StatelessWidget {
  final ChatController chat;
  const _PostBanner({required this.chat});

  @override
  Widget build(BuildContext context) {
    final isOffer = chat.postType == 'offer';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        border: Border(top: BorderSide(color: AppColors.primaryGhost)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOffer
                  ? Icons.flight_takeoff_rounded
                  : Icons.shopping_cart_outlined,
              size: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  T.of(context, 'about_this_pasabuy'),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  chat.postTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}