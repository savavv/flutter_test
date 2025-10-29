import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../widgets/message_bubble.dart';
import '../widgets/animated_message_bubble.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/chat_input.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';
import '../services/e2ee_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      final list = await apiService.getMessages(widget.chatId, limit: 50, offset: 0);
      final messages = list.reversed.map<Message>((m) {
        final typeStr = (m['message_type'] ?? 'text').toString();
        final msgType = MessageType.text; // map other types as needed
        return Message(
          id: m['id'].toString(),
          chatId: widget.chatId,
          senderId: m['sender_id'].toString(),
          content: (m['content'] ?? '').toString(),
          type: msgType,
          timestamp: DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now(),
          isRead: true,
          isEdited: (m['is_edited'] ?? false) == true,
          replyToMessageId: m['reply_to_id']?.toString(),
        );
      }).toList();
      // Try decrypt messages that are encrypted
      final myId = Provider.of<UserProvider>(context, listen: false).currentUser?.id;
      final otherId = chatProvider.getChat(widget.chatId)?.participants.firstWhere((id) => id != myId, orElse: () => '');
      final decrypted = await Future.wait(messages.map((msg) async {
        if (otherId != null && otherId.isNotEmpty) {
          try {
            final clear = await e2eeService.decryptFromUser(senderUserId: msg.senderId, ciphertext: msg.content);
            return msg.copyWith(content: clear);
          } catch (_) {}
        }
        return msg;
      }));
      chatProvider.setMessages(widget.chatId, decrypted.toList());
      chatProvider.markMessagesAsRead(widget.chatId);
    } catch (e) {
      // keep empty on failure
    }
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

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final me = Provider.of<UserProvider>(context, listen: false).currentUser;
    final chat = chatProvider.getChat(widget.chatId);
    String payloadContent = content;
    if (chat != null && chat.type == ChatType.private) {
      final otherId = chat.participants.firstWhere((id) => id != me?.id, orElse: () => '');
      if (otherId.isNotEmpty) {
        try {
          payloadContent = await e2eeService.encryptForUser(recipientUserId: otherId, plaintext: content);
        } catch (e) {}
      }
    }

    try {
      final sent = await apiService.sendMessage(widget.chatId, {
        'content': payloadContent,
        'message_type': 'text',
      });
      final message = Message(
        id: sent['id'].toString(),
        chatId: widget.chatId,
        senderId: sent['sender_id'].toString(),
        content: content, // show clear text locally
        type: MessageType.text,
        timestamp: DateTime.tryParse((sent['created_at'] ?? '').toString()) ?? DateTime.now(),
        isRead: false,
        isEdited: (sent['is_edited'] ?? false) == true,
        replyToMessageId: sent['reply_to_id']?.toString(),
      );
      chatProvider.addMessage(message);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = Provider.of<UserProvider>(context).currentUser;
    final myId = me?.id;
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.getMessages(widget.chatId);
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isLastMessage = index == messages.length - 1;
                    final showDate = _shouldShowDate(message, index > 0 ? messages[index - 1] : null);
                    
                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(message.timestamp),
                        AnimatedMessageBubble(
                          message: message,
                          isMe: myId != null && message.senderId == myId,
                          showAvatar: isLastMessage || 
                              (index < messages.length - 1 && 
                               messages[index + 1].senderId != message.senderId),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chat = chatProvider.getChat(widget.chatId);
    
    return CustomAppBar(
          title: chat?.name ?? 'Чат',
          actions: [
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {},
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'info':
                    break;
                  case 'search':
                    break;
                  case 'clear':
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Text('Информация'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'search',
                  child: Row(
                    children: [
                      Icon(Icons.search),
                      SizedBox(width: 8),
                      Text('Поиск'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('Очистить историю'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
  }

  Widget _buildDateSeparator(DateTime date) {
    final msk = (date.isUtc ? date : date.toUtc()).add(const Duration(hours: 3));
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        DateFormat('dd MMMM yyyy').format(msk),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  bool _shouldShowDate(Message currentMessage, Message? previousMessage) {
    if (previousMessage == null) return true;
    final currentMsk = currentMessage.timestamp.toUtc().add(const Duration(hours: 3));
    final previousMsk = previousMessage.timestamp.toUtc().add(const Duration(hours: 3));
    final currentDate = DateTime(currentMsk.year, currentMsk.month, currentMsk.day);
    final previousDate = DateTime(previousMsk.year, previousMsk.month, previousMsk.day);
    
    return currentDate != previousDate;
  }
}
