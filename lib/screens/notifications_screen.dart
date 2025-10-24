import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _enableNotifications = true;
  bool _enableSound = true;
  bool _enableVibration = true;
  bool _enablePreview = true;
  bool _enableInAppSounds = true;
  bool _enableInAppVibration = true;
  bool _enableInAppPreview = true;
  bool _enableCalls = true;
  bool _enableMessages = true;
  bool _enableGroups = true;
  bool _enableChannels = true;
  bool _enableContacts = true;
  bool _enableCallsNotifications = true;
  bool _enableMessagesNotifications = true;
  bool _enableGroupsNotifications = true;
  bool _enableChannelsNotifications = true;
  bool _enableContactsNotifications = true;

  String _selectedSound = 'По умолчанию';
  String _selectedVibration = 'По умолчанию';

  final List<String> _soundOptions = [
    'По умолчанию',
    'Классический',
    'Современный',
    'Мягкий',
    'Громкий',
    'Тихий',
  ];

  final List<String> _vibrationOptions = [
    'По умолчанию',
    'Короткая',
    'Длинная',
    'Двойная',
    'Тройная',
    'Выключена',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Уведомления',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Общие настройки'),
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            title: 'Включить уведомления',
            subtitle: 'Получать push-уведомления',
            value: _enableNotifications,
            onChanged: (value) {
              setState(() {
                _enableNotifications = value;
              });
            },
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Звук',
            subtitle: 'Воспроизводить звук при получении уведомления',
            value: _enableSound,
            onChanged: (value) {
              setState(() {
                _enableSound = value;
              });
            },
            enabled: _enableNotifications,
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Вибрация',
            subtitle: 'Вибрация при получении уведомления',
            value: _enableVibration,
            onChanged: (value) {
              setState(() {
                _enableVibration = value;
              });
            },
            enabled: _enableNotifications,
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Превью сообщений',
            subtitle: 'Показывать содержимое сообщений в уведомлениях',
            value: _enablePreview,
            onChanged: (value) {
              setState(() {
                _enablePreview = value;
              });
            },
            enabled: _enableNotifications,
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Настройки звука'),
          const SizedBox(height: 16),
          
          _buildSelectionTile(
            title: 'Звук уведомлений',
            subtitle: _selectedSound,
            onTap: () => _showSoundPicker(),
            enabled: _enableSound && _enableNotifications,
          ),
          const SizedBox(height: 8),
          
          _buildSelectionTile(
            title: 'Вибрация',
            subtitle: _selectedVibration,
            onTap: () => _showVibrationPicker(),
            enabled: _enableVibration && _enableNotifications,
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('В приложении'),
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            title: 'Звук в приложении',
            subtitle: 'Воспроизводить звук при получении сообщений',
            value: _enableInAppSounds,
            onChanged: (value) {
              setState(() {
                _enableInAppSounds = value;
              });
            },
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Вибрация в приложении',
            subtitle: 'Вибрация при получении сообщений',
            value: _enableInAppVibration,
            onChanged: (value) {
              setState(() {
                _enableInAppVibration = value;
              });
            },
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Превью в приложении',
            subtitle: 'Показывать содержимое сообщений',
            value: _enableInAppPreview,
            onChanged: (value) {
              setState(() {
                _enableInAppPreview = value;
              });
            },
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Типы уведомлений'),
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            title: 'Звонки',
            subtitle: 'Уведомления о входящих звонках',
            value: _enableCalls,
            onChanged: (value) {
              setState(() {
                _enableCalls = value;
              });
            },
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Сообщения',
            subtitle: 'Уведомления о новых сообщениях',
            value: _enableMessages,
            onChanged: (value) {
              setState(() {
                _enableMessages = value;
              });
            },
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Группы',
            subtitle: 'Уведомления из групповых чатов',
            value: _enableGroups,
            onChanged: (value) {
              setState(() {
                _enableGroups = value;
              });
            },
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Каналы',
            subtitle: 'Уведомления из каналов',
            value: _enableChannels,
            onChanged: (value) {
              setState(() {
                _enableChannels = value;
              });
            },
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Контакты',
            subtitle: 'Уведомления о новых контактах',
            value: _enableContacts,
            onChanged: (value) {
              setState(() {
                _enableContacts = value;
              });
            },
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Время тишины'),
          const SizedBox(height: 16),
          
          _buildActionTile(
            title: 'Не беспокоить',
            subtitle: 'Настроить время тишины',
            icon: Icons.schedule,
            onTap: () {
              _showDoNotDisturbSettings();
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
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled ? Colors.grey[600] : Colors.grey,
            fontSize: 14,
          ),
        ),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildSelectionTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled ? Colors.grey[600] : Colors.grey,
            fontSize: 14,
          ),
        ),
        trailing: enabled ? const Icon(Icons.chevron_right) : null,
        onTap: enabled ? onTap : null,
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

  void _showSoundPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Выберите звук',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _soundOptions.length,
                itemBuilder: (context, index) {
                  final sound = _soundOptions[index];
                  return ListTile(
                    title: Text(sound),
                    trailing: _selectedSound == sound
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSound = sound;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVibrationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Выберите вибрацию',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _vibrationOptions.length,
                itemBuilder: (context, index) {
                  final vibration = _vibrationOptions[index];
                  return ListTile(
                    title: Text(vibration),
                    trailing: _selectedVibration == vibration
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedVibration = vibration;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDoNotDisturbSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Не беспокоить'),
        content: const Text('Настройте время, когда вы не хотите получать уведомления.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement do not disturb settings
            },
            child: const Text('Настроить'),
          ),
        ],
      ),
    );
  }
}
