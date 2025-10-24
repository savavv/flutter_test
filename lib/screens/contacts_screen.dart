import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../widgets/custom_app_bar.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _mockContacts = [];

  @override
  void initState() {
    super.initState();
    _loadMockContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMockContacts() {
    setState(() {
      _mockContacts = [
        User(
          id: 'contact1',
          name: 'Анна Петрова',
          username: 'anna_pet',
          phoneNumber: '+7 (999) 123-45-67',
          isOnline: true,
          lastSeen: DateTime.now(),
          avatarUrl: null,
        ),
        User(
          id: 'contact2',
          name: 'Михаил Иванов',
          username: 'mike_ivan',
          phoneNumber: '+7 (999) 234-56-78',
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
          avatarUrl: null,
        ),
        User(
          id: 'contact3',
          name: 'Елена Смирнова',
          username: 'elena_sm',
          phoneNumber: '+7 (999) 345-67-89',
          isOnline: true,
          lastSeen: DateTime.now(),
          avatarUrl: null,
        ),
        User(
          id: 'contact4',
          name: 'Дмитрий Козлов',
          username: 'dmitry_koz',
          phoneNumber: '+7 (999) 456-78-90',
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(hours: 5)),
          avatarUrl: null,
        ),
        User(
          id: 'contact5',
          name: 'Ольга Волкова',
          username: 'olga_volk',
          phoneNumber: '+7 (999) 567-89-01',
          isOnline: true,
          lastSeen: DateTime.now(),
          avatarUrl: null,
        ),
        User(
          id: 'contact6',
          name: 'Сергей Морозов',
          username: 'sergey_mor',
          phoneNumber: '+7 (999) 678-90-12',
          isOnline: false,
          lastSeen: DateTime.now().subtract(const Duration(days: 1)),
          avatarUrl: null,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Контакты',
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddContactDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск контактов',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: _buildContactsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    final filteredContacts = _searchController.text.isEmpty
        ? _mockContacts
        : _mockContacts.where((contact) {
            final query = _searchController.text.toLowerCase();
            return contact.name.toLowerCase().contains(query) ||
                   contact.username.toLowerCase().contains(query) ||
                   (contact.phoneNumber?.toLowerCase().contains(query) ?? false);
          }).toList();

    if (filteredContacts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = filteredContacts[index];
        return _buildContactItem(contact);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty ? Icons.contacts_outlined : Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? 'Нет контактов' : 'Ничего не найдено',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty 
                ? 'Добавьте контакты для начала общения'
                : 'Попробуйте изменить запрос',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(User contact) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[300],
        backgroundImage: contact.avatarUrl != null
            ? NetworkImage(contact.avatarUrl!)
            : null,
        child: contact.avatarUrl == null
            ? Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      ),
      title: Text(
        contact.name,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        contact.phoneNumber ?? contact.username,
        style: TextStyle(
          color: Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (contact.isOnline)
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) => _handleContactAction(value, contact),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'message',
                child: Row(
                  children: [
                    Icon(Icons.message, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Написать'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'call',
                child: Row(
                  children: [
                    Icon(Icons.call, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Позвонить'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'video',
                child: Row(
                  children: [
                    Icon(Icons.videocam, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Видеозвонок'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Подробности'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
      onTap: () => _showContactDetails(contact),
    );
  }

  void _handleContactAction(String action, User contact) {
    switch (action) {
      case 'message':
        _startChat(contact);
        break;
      case 'call':
        _makeCall(contact, false);
        break;
      case 'video':
        _makeCall(contact, true);
        break;
      case 'details':
        _showContactDetails(contact);
        break;
    }
  }

  void _startChat(User contact) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Check if chat already exists
    final existingChat = chatProvider.chats.firstWhere(
      (chat) => chat.participants.contains(contact.id),
      orElse: () => Chat(
        id: '',
        name: '',
        type: ChatType.private,
        participants: [],
        lastActivity: DateTime.now(),
      ),
    );

    if (existingChat.id.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatId: existingChat.id),
        ),
      );
    } else {
      // Create new chat
      final newChat = Chat(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: contact.name,
        avatarUrl: contact.avatarUrl,
        type: ChatType.private,
        participants: ['current_user', contact.id],
        lastActivity: DateTime.now(),
      );

      chatProvider.addChat(newChat);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatId: newChat.id),
        ),
      );
    }
  }

  void _makeCall(User contact, bool isVideo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${isVideo ? 'Видео' : 'Аудио'} звонок ${contact.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showContactDetails(User contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Информация о контакте'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                backgroundImage: contact.avatarUrl != null
                    ? NetworkImage(contact.avatarUrl!)
                    : null,
                child: contact.avatarUrl == null
                    ? Text(
                        contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text('Имя: ${contact.name}'),
            Text('Username: @${contact.username}'),
            Text('Телефон: ${contact.phoneNumber}'),
            Text('Статус: ${contact.isOnline ? 'Онлайн' : 'Был(а) в сети ${_formatLastSeen(contact.lastSeen)}'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startChat(contact);
            },
            child: const Text('Написать'),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить контакт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Номер телефона',
                hintText: '+7 (999) 123-45-67',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addContact(phoneController.text);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _addContact(String phoneNumber) {
    if (phoneNumber.isEmpty) return;
    
    final newContact = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Новый контакт',
      username: 'new_contact_${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: phoneNumber,
      isOnline: false,
      lastSeen: DateTime.now(),
      avatarUrl: null,
    );

    setState(() {
      _mockContacts.add(newContact);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Контакт добавлен'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'только что';
    }
  }
}
