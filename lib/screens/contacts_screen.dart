import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../widgets/custom_app_bar.dart';
import 'chat_screen.dart';
import '../services/api_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchContacts();
    });
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
    final userProvider = Provider.of<UserProvider>(context);
    final allContacts = [...userProvider.contacts];
    final filteredContacts = _searchController.text.isEmpty
        ? allContacts
        : allContacts.where((contact) {
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
        children: const [
          Icon(Icons.more_vert),
        ],
      ),
      onTap: () => _startChat(contact),
    );
  }

  Future<void> _startChat(User contact) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final chat = await chatProvider.createOrGetPrivateChat(contact.id, contact.name, contactAvatar: contact.avatarUrl);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chat.id),
      ),
    );
  }

  void _showAddContactDialog() {
    final queryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить контакт'),
        content: TextField(
          controller: queryController,
          decoration: const InputDecoration(
            labelText: 'Телефон или @username',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final query = queryController.text.trim();
              if (query.isEmpty) return;
              Navigator.pop(context);
              await _addContactViaApi(query);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _addContactViaApi(String query) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final normalized = query.startsWith('@') ? query.substring(1) : query;
      final results = await apiService.searchUsersByQuery(normalized);
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь не найден'), backgroundColor: Colors.orange),
        );
        return;
      }
      final userJson = results.first as Map<String, dynamic>;
      final userId = userJson['id'].toString();
      final ok = await userProvider.addContactById(userId);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Контакт добавлен'), backgroundColor: Colors.green),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось добавить контакт'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось добавить: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
