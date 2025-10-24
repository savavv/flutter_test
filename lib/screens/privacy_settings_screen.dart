import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _showPhoneNumber = true;
  bool _showLastSeen = true;
  bool _showProfilePhoto = true;
  bool _allowCallsFromEveryone = true;
  bool _allowMessagesFromEveryone = true;
  bool _readReceipts = true;
  bool _typingIndicator = true;
  bool _onlineStatus = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Приватность и безопасность',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Кто может видеть мою информацию'),
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            title: 'Номер телефона',
            subtitle: 'Кто может видеть ваш номер телефона',
            value: _showPhoneNumber,
            onChanged: (value) {
              setState(() {
                _showPhoneNumber = value;
              });
            },
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Время последнего посещения',
            subtitle: 'Кто может видеть, когда вы были в сети',
            value: _showLastSeen,
            onChanged: (value) {
              setState(() {
                _showLastSeen = value;
              });
            },
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Фото профиля',
            subtitle: 'Кто может видеть ваше фото профиля',
            value: _showProfilePhoto,
            onChanged: (value) {
              setState(() {
                _showProfilePhoto = value;
              });
            },
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Кто может звонить мне'),
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            title: 'Все пользователи',
            subtitle: 'Любой может позвонить вам',
            value: _allowCallsFromEveryone,
            onChanged: (value) {
              setState(() {
                _allowCallsFromEveryone = value;
              });
            },
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Кто может писать мне'),
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            title: 'Все пользователи',
            subtitle: 'Любой может написать вам сообщение',
            value: _allowMessagesFromEveryone,
            onChanged: (value) {
              setState(() {
                _allowMessagesFromEveryone = value;
              });
            },
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Уведомления о прочтении'),
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            title: 'Отправлять уведомления о прочтении',
            subtitle: 'Отправитель увидит, когда вы прочитали сообщение',
            value: _readReceipts,
            onChanged: (value) {
              setState(() {
                _readReceipts = value;
              });
            },
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Показывать статус "печатает"',
            subtitle: 'Другие увидят, когда вы печатаете сообщение',
            value: _typingIndicator,
            onChanged: (value) {
              setState(() {
                _typingIndicator = value;
              });
            },
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Статус онлайн'),
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            title: 'Показывать статус онлайн',
            subtitle: 'Другие увидят, когда вы в сети',
            value: _onlineStatus,
            onChanged: (value) {
              setState(() {
                _onlineStatus = value;
              });
            },
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Блокировка'),
          const SizedBox(height: 16),
          
          _buildActionTile(
            title: 'Заблокированные пользователи',
            subtitle: 'Управление заблокированными контактами',
            icon: Icons.block,
            onTap: () {
              _showBlockedUsers();
            },
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            title: 'Скрытые чаты',
            subtitle: 'Управление скрытыми чатами',
            icon: Icons.visibility_off,
            onTap: () {
              _showHiddenChats();
            },
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Безопасность'),
          const SizedBox(height: 16),
          
          _buildActionTile(
            title: 'Двухфакторная аутентификация',
            subtitle: 'Дополнительная защита аккаунта',
            icon: Icons.security,
            onTap: () {
              _showTwoFactorAuth();
            },
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            title: 'Активные сессии',
            subtitle: 'Управление устройствами',
            icon: Icons.devices,
            onTap: () {
              _showActiveSessions();
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showBlockedUsers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заблокированные пользователи'),
        content: const Text('Здесь будут отображаться заблокированные контакты.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showHiddenChats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрытые чаты'),
        content: const Text('Здесь будут отображаться скрытые чаты.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorAuth() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Двухфакторная аутентификация'),
        content: const Text('Настройте дополнительную защиту для вашего аккаунта.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement 2FA setup
            },
            child: const Text('Настроить'),
          ),
        ],
      ),
    );
  }

  void _showActiveSessions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Активные сессии'),
        content: const Text('Здесь будут отображаться все устройства, на которых вы вошли в аккаунт.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
