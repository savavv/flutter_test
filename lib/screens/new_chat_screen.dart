import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../widgets/custom_app_bar.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterContacts);
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadContacts() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _filteredContacts = userProvider.contacts;
    });
  }

  void _filterContacts() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = userProvider.contacts;
      } else {
        _filteredContacts = userProvider.contacts.where((contact) {
          return contact.name.toLowerCase().contains(query) ||
                 contact.username.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _startChat(User contact) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
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
      // Navigate to existing chat
      Navigator.of(context).pop(existingChat.id);
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
      Navigator.of(context).pop(newChat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Новый чат',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
              autofocus: true,
            ),
          ),
          Expanded(
            child: _filteredContacts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return _buildContactItem(contact);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Нет контактов',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Добавьте контакты для начала общения',
            style: TextStyle(
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
      trailing: contact.isOnline
          ? Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () => _startChat(contact),
    );
  }
}
