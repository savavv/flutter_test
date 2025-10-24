import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../widgets/chat_item.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/animated_fab.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'new_chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Mock users
    final mockUsers = [
      User(
        id: '1',
        name: 'Александр Иванов',
        username: 'alex_ivanov',
        avatarUrl: 'https://via.placeholder.com/150',
        isOnline: true,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
        phoneNumber: '+7 (999) 123-45-67',
      ),
      User(
        id: '2',
        name: 'Мария Петрова',
        username: 'maria_petrova',
        avatarUrl: 'https://via.placeholder.com/150',
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
        phoneNumber: '+7 (999) 234-56-78',
      ),
      User(
        id: '3',
        name: 'Дмитрий Сидоров',
        username: 'dmitry_sidorov',
        avatarUrl: 'https://via.placeholder.com/150',
        isOnline: true,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
        phoneNumber: '+7 (999) 345-67-89',
      ),
    ];

    userProvider.setContacts(mockUsers);

    // Mock chats
    final mockChats = [
      Chat(
        id: '1',
        name: 'Александр Иванов',
        avatarUrl: 'https://via.placeholder.com/150',
        type: ChatType.private,
        participants: ['current_user', '1'],
        lastMessage: Message(
          id: '1',
          chatId: '1',
          senderId: '1',
          content: 'Привет! Как дела?',
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 2,
      ),
      Chat(
        id: '2',
        name: 'Мария Петрова',
        avatarUrl: 'https://via.placeholder.com/150',
        type: ChatType.private,
        participants: ['current_user', '2'],
        lastMessage: Message(
          id: '2',
          chatId: '2',
          senderId: 'current_user',
          content: 'Спасибо за помощь!',
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
        unreadCount: 0,
        isPinned: true,
      ),
      Chat(
        id: '3',
        name: 'Дмитрий Сидоров',
        avatarUrl: 'https://via.placeholder.com/150',
        type: ChatType.private,
        participants: ['current_user', '3'],
        lastMessage: Message(
          id: '3',
          chatId: '3',
          senderId: '3',
          content: 'Отлично! Встречаемся в 18:00',
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 1,
      ),
    ];

    chatProvider.setChats(mockChats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Чаты',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'new_chat':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NewChatScreen(),
                    ),
                  ).then((chatId) {
                    if (chatId != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(chatId: chatId),
                        ),
                      );
                    }
                  });
                  break;
                case 'new_group':
                  // TODO: Implement new group
                  break;
                case 'new_channel':
                  // TODO: Implement new channel
                  break;
                case 'contacts':
                  // TODO: Implement contacts
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'new_chat',
                child: Row(
                  children: [
                    Icon(Icons.chat),
                    SizedBox(width: 8),
                    Text('Новый чат'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'new_group',
                child: Row(
                  children: [
                    Icon(Icons.group_add),
                    SizedBox(width: 8),
                    Text('Новая группа'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'new_channel',
                child: Row(
                  children: [
                    Icon(Icons.tv),
                    SizedBox(width: 8),
                    Text('Новый канал'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'contacts',
                child: Row(
                  children: [
                    Icon(Icons.contacts),
                    SizedBox(width: 8),
                    Text('Контакты'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final chats = chatProvider.chats;
          
          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Нет чатов',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatItem(
                chat: chat,
                onTap: () {
                  chatProvider.selectChat(chat.id);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chatId: chat.id),
                    ),
                  );
                },
                onLongPress: () {
                  _showChatOptions(context, chat);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: AnimatedFab(
        icon: Icons.edit,
        tooltip: 'Новый чат',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NewChatScreen(),
            ),
          ).then((chatId) {
            if (chatId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(chatId: chatId),
                ),
              );
            }
          });
        },
      ),
    );
  }

  void _showChatOptions(BuildContext context, Chat chat) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(chat.isPinned ? 'Открепить' : 'Закрепить'),
                onTap: () {
                  Provider.of<ChatProvider>(context, listen: false).togglePin(chat.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(chat.isMuted ? Icons.volume_off : Icons.volume_up),
                title: Text(chat.isMuted ? 'Включить звук' : 'Отключить звук'),
                onTap: () {
                  Provider.of<ChatProvider>(context, listen: false).toggleMute(chat.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(chat.isArchived ? Icons.unarchive : Icons.archive),
                title: Text(chat.isArchived ? 'Разархивировать' : 'Архивировать'),
                onTap: () {
                  Provider.of<ChatProvider>(context, listen: false).toggleArchive(chat.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Provider.of<ChatProvider>(context, listen: false).deleteChat(chat.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
