import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';

class ChatProvider with ChangeNotifier {
  List<Chat> _chats = [];
  Map<String, List<Message>> _messages = {};
  String? _selectedChatId;
  bool _isLoading = false;

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
    
    // Update chat's last message and activity
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
      
      // Update chat unread count
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

  // Search functionality
  List<Chat> searchChats(String query) {
    if (query.isEmpty) return [];
    
    return _chats.where((chat) =>
        chat.name.toLowerCase().contains(query.toLowerCase()) ||
        (chat.lastMessage?.content.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }
}
