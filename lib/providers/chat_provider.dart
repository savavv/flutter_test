import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/e2ee_service.dart';
import 'auth_provider.dart';
import 'user_provider.dart';
import 'dart:convert';

class ChatProvider with ChangeNotifier {
  List<Chat> _chats = [];
  Map<String, List<Message>> _messages = {};
  String? _selectedChatId;
  bool _isLoading = false;
  WebSocketChannel? _channel;
  bool get isWsConnected => _channel != null;

  List<Chat> get chats => _chats;
  String? get selectedChatId => _selectedChatId;
  bool get isLoading => _isLoading;

  List<Chat> get pinnedChats => _chats.where((chat) => chat.isPinned).toList();
  List<Chat> get regularChats => _chats.where((chat) => !chat.isPinned && !chat.isArchived).toList();
  List<Chat> get archivedChats => _chats.where((chat) => chat.isArchived).toList();

  List<Message> getMessages(String chatId) {
    return _messages[chatId] ?? [];
  }

  Chat? getChat(String chatId) {
    try {
      return _chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _enrichChatWithOtherUser(BuildContext context, Chat chat) async {
    if (chat.type != ChatType.private) return;
    if (chat.name.isNotEmpty && chat.avatarUrl != null) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final meId = userProvider.currentUser?.id;
    final otherId = chat.participants.firstWhere((id) => id != meId, orElse: () => chat.participants.isNotEmpty ? chat.participants.first : '');
    if (otherId.isEmpty) return;

    // Try from contacts cache
    final fromContacts = userProvider.contacts.firstWhere(
      (u) => u.id == otherId,
      orElse: () => User(id: '', name: '', username: '', lastSeen: DateTime.now()),
    );
    String? name;
    String? avatarUrl;
    if (fromContacts.id.isNotEmpty) {
      name = fromContacts.name;
      avatarUrl = fromContacts.avatarUrl;
    } else {
      // Fetch from API by id
      try {
        final u = await apiService.getUserById(otherId);
        name = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
        avatarUrl = apiService.resolveUrl(u['avatar_url']);
      } catch (_) {}
    }

    if ((name != null && name.isNotEmpty) || avatarUrl != null) {
      final updated = chat.copyWith(
        name: (chat.name.isEmpty && (name != null && name.isNotEmpty)) ? name : chat.name,
        avatarUrl: avatarUrl ?? chat.avatarUrl,
      );
      updateChat(updated);
    }
  }

  Future<void> fetchChats(BuildContext context) async {
    try {
      final list = await apiService.getChats();
      final mapped = list.map<Chat>((c) {
        final typeStr = (c['chat_type'] ?? 'private').toString();
        final type = typeStr == 'group' ? ChatType.group : typeStr == 'channel' ? ChatType.channel : ChatType.private;
        final participants = (c['participants'] as List<dynamic>? ?? [])
            .map((p) => (p['user_id'] ?? '').toString())
            .toList();
        return Chat(
          id: c['id'].toString(),
          name: (c['name'] ?? '').toString(),
          avatarUrl: apiService.resolveUrl(c['avatar_url']),
          type: type,
          participants: participants,
          lastActivity: DateTime.tryParse((c['updated_at'] ?? '').toString()) ?? DateTime.now(),
        );
      }).toList();
      setChats(mapped);
      // Enrich private chats with other user data
      for (final chat in _chats.toList()) {
        await _enrichChatWithOtherUser(context, chat);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch chats: $e');
      }
    }
  }

  Future<void> _handleIncomingMessage(BuildContext context, Map<String, dynamic> msg) async {
    final chatId = (msg['chat_id'] ?? '').toString();
    String content = (msg['content'] ?? '').toString();
    final senderId = (msg['sender_id'] ?? '').toString();
    final createdAt = DateTime.tryParse((msg['created_at'] ?? '').toString()) ?? DateTime.now();
    // Ignore echo of our own messages (мы уже добавили их после успешного POST)
    final meId = Provider.of<UserProvider>(context, listen: false).currentUser?.id;
    if (meId != null && senderId == meId) {
      return;
    }
    final message = Message(
      id: (msg['id'] ?? '').toString(),
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: MessageType.text,
      timestamp: createdAt,
    );
    // Dedupe: do not add if message with same id already present
    final existing = _messages[chatId]?.any((m) => m.id == message.id) ?? false;
    if (existing) {
      return;
    }
    if (getChat(chatId) == null) {
      await fetchChats(context);
      try {
        final list = await apiService.getMessages(chatId, limit: 50, offset: 0);
        final messages = list.reversed.map<Message>((m) => Message(
          id: m['id'].toString(),
          chatId: chatId,
          senderId: m['sender_id'].toString(),
          content: (m['content'] ?? '').toString(),
          type: MessageType.text,
          timestamp: DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now(),
        )).toList();
        setMessages(chatId, messages);
      } catch (_) {
        // try to decrypt if needed
        try {
          content = await e2eeService.decryptFromUser(senderUserId: senderId, ciphertext: content);
        } catch (_) {}
        addMessage(message.copyWith(content: content));
      }
    } else {
      // try to decrypt if needed
      try {
        content = await e2eeService.decryptFromUser(senderUserId: senderId, ciphertext: content);
      } catch (_) {}
      addMessage(message.copyWith(content: content));
    }
    // Unread counter if chat not active
    if (_selectedChatId != chatId) {
      final chat = getChat(chatId);
      if (chat != null) {
        final updated = chat.copyWith(unreadCount: chat.unreadCount + 1);
        updateChat(updated);
      }
    }
  }

  Future<void> connectGlobalWebSocket(BuildContext context) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.accessToken;
      if (token == null) return;
      final url = apiService.getWebSocketUrl(accessToken: token);
      if (kDebugMode) {
        print('Connecting WS: $url');
      }
      _channel?.sink.close(ws_status.goingAway);
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen((event) async {
        if (kDebugMode) {
          print('WS message: $event');
        }
        try {
          final data = json.decode(event);
          final type = data['type'];
          if (type == 'message') {
            final msg = (data['data'] ?? {}) as Map<String, dynamic>;
            await notificationService.showMessageNotification(
              senderName: 'Сообщение',
              message: (msg['content'] ?? '').toString(),
              chatId: (msg['chat_id'] ?? '').toString(),
            );
            await _handleIncomingMessage(context, msg);
          }
        } catch (_) {}
      }, onError: (error) {
        if (kDebugMode) {
          print('WS error: $error');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('WS connect error: $e');
      }
    }
  }

  void disconnectWebSocket() {
    _channel?.sink.close(ws_status.normalClosure);
    _channel = null;
  }

  void setChats(List<Chat> chats) {
    _chats = chats;
    notifyListeners();
  }

  void addChat(Chat chat) {
    if (!_chats.any((c) => c.id == chat.id)) {
      _chats.add(chat);
      _chats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      notifyListeners();
    }
  }

  void updateChat(Chat updatedChat) {
    final index = _chats.indexWhere((chat) => chat.id == updatedChat.id);
    if (index != -1) {
      _chats[index] = updatedChat;
      _chats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      notifyListeners();
    }
  }

  void deleteChat(String chatId) {
    _chats.removeWhere((chat) => chat.id == chatId);
    _messages.remove(chatId);
    if (_selectedChatId == chatId) {
      _selectedChatId = null;
    }
    notifyListeners();
  }

  Future<Chat> createOrGetPrivateChat(String contactId, String contactName, {String? contactAvatar}) async {
    final payload = {
      'chat_type': 'private',
      'participant_ids': [int.tryParse(contactId) ?? contactId],
    };
    final response = await apiService.createChat(payload);
    final chatId = response['id'].toString();
    final avatar = apiService.resolveUrl(response['avatar_url']) ?? contactAvatar;
    final chat = Chat(
      id: chatId,
      name: contactName,
      avatarUrl: avatar,
      type: ChatType.private,
      participants: [contactId],
      lastActivity: DateTime.tryParse(response['updated_at'] ?? '') ?? DateTime.now(),
    );
    _chats.removeWhere((c) => c.type == ChatType.private && c.participants.contains(contactId) && int.tryParse(c.id) == null);
    addChat(chat);
    return chat;
  }

  void selectChat(String? chatId) {
    _selectedChatId = chatId;
    notifyListeners();
  }

  void setMessages(String chatId, List<Message> messages) {
    _messages[chatId] = messages;
    notifyListeners();
  }

  void addMessage(Message message) {
    final chatId = message.chatId;
    if (_messages[chatId] == null) {
      _messages[chatId] = [];
    }
    _messages[chatId]!.add(message);
    final chat = getChat(chatId);
    if (chat != null) {
      final updatedChat = chat.copyWith(
        lastMessage: message,
        lastActivity: message.timestamp,
      );
      updateChat(updatedChat);
    }
    notifyListeners();
  }

  void markMessagesAsRead(String chatId) {
    final messages = _messages[chatId];
    if (messages != null) {
      for (int i = 0; i < messages.length; i++) {
        if (!messages[i].isRead) {
          messages[i] = messages[i].copyWith(isRead: true);
        }
      }
      final chat = getChat(chatId);
      if (chat != null) {
        final updatedChat = chat.copyWith(unreadCount: 0);
        updateChat(updatedChat);
      }
      notifyListeners();
    }
  }

  void togglePin(String chatId) {
    final chat = getChat(chatId);
    if (chat != null) {
      final updatedChat = chat.copyWith(isPinned: !chat.isPinned);
      updateChat(updatedChat);
    }
  }

  void toggleArchive(String chatId) {
    final chat = getChat(chatId);
    if (chat != null) {
      final updatedChat = chat.copyWith(isArchived: !chat.isArchived);
      updateChat(updatedChat);
    }
  }

  void toggleMute(String chatId) {
    final chat = getChat(chatId);
    if (chat != null) {
      final updatedChat = chat.copyWith(isMuted: !chat.isMuted);
      updateChat(updatedChat);
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  List<Chat> searchChats(String query) {
    if (query.isEmpty) return [];
    return _chats.where((chat) =>
        chat.name.toLowerCase().contains(query.toLowerCase()) ||
        (chat.lastMessage?.content.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }
}
