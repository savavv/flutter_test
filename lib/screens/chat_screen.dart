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

  void _loadMessages() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Mock messages for demonstration
    final mockMessages = [
      Message(
        id: const Uuid().v4(),
        chatId: widget.chatId,
        senderId: widget.chatId == '1' ? '1' : widget.chatId == '2' ? '2' : '3',
        content: 'Привет! Как дела?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: true,
      ),
      Message(
        id: const Uuid().v4(),
        chatId: widget.chatId,
        senderId: 'current_user',
        content: 'Привет! Все хорошо, спасибо! А у тебя как?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        isRead: true,
      ),
      Message(
        id: const Uuid().v4(),
        chatId: widget.chatId,
        senderId: widget.chatId == '1' ? '1' : widget.chatId == '2' ? '2' : '3',
        content: 'Тоже все отлично! Работаю над новым проектом.',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        isRead: true,
      ),
      Message(
        id: const Uuid().v4(),
        chatId: widget.chatId,
        senderId: 'current_user',
        content: 'Здорово! Расскажи подробнее, если не секрет.',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: true,
      ),
      Message(
        id: const Uuid().v4(),
        chatId: widget.chatId,
        senderId: widget.chatId == '1' ? '1' : widget.chatId == '2' ? '2' : '3',
        content: 'Конечно! Это мобильное приложение на Flutter. Очень интересный проект!',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isRead: true,
      ),
      Message(
        id: const Uuid().v4(),
        chatId: widget.chatId,
        senderId: 'current_user',
        content: 'Круто! Flutter - отличная платформа. Удачи в разработке!',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
    ];

    chatProvider.setMessages(widget.chatId, mockMessages);
    chatProvider.markMessagesAsRead(widget.chatId);
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

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    final message = Message(
      id: const Uuid().v4(),
      chatId: widget.chatId,
      senderId: 'current_user',
      content: content,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    chatProvider.addMessage(message);
    _messageController.clear();
    
    // Simulate typing and reply
    setState(() {
      _isTyping = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final replyMessage = Message(
          id: const Uuid().v4(),
          chatId: widget.chatId,
          senderId: widget.chatId == '1' ? '1' : widget.chatId == '2' ? '2' : '3',
          content: 'Спасибо за сообщение! Отличный день для общения.',
          type: MessageType.text,
          timestamp: DateTime.now(),
          isRead: false,
        );

        chatProvider.addMessage(replyMessage);
        setState(() {
          _isTyping = false;
        });
      }
    });

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
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
                  itemCount: messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    
                    final message = messages[index];
                    final isLastMessage = index == messages.length - 1;
                    final showDate = _shouldShowDate(message, index > 0 ? messages[index - 1] : null);
                    
                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(message.timestamp),
                        AnimatedMessageBubble(
                          message: message,
                          isMe: message.senderId == 'current_user',
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
              onPressed: () {
                // TODO: Implement video call
              },
            ),
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {
                // TODO: Implement voice call
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'info':
                    // TODO: Show chat info
                    break;
                  case 'search':
                    // TODO: Search in chat
                    break;
                  case 'clear':
                    // TODO: Clear chat
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        DateFormat('dd MMMM yyyy').format(date),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'печатает',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDate(Message currentMessage, Message? previousMessage) {
    if (previousMessage == null) return true;
    
    final currentDate = DateTime(currentMessage.timestamp.year, 
                                currentMessage.timestamp.month, 
                                currentMessage.timestamp.day);
    final previousDate = DateTime(previousMessage.timestamp.year, 
                                 previousMessage.timestamp.month, 
                                 previousMessage.timestamp.day);
    
    return currentDate != previousDate;
  }
}
