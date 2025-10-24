import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'Русский';

  final List<LanguageOption> _languages = [
    LanguageOption(
      name: 'Русский',
      nativeName: 'Русский',
      code: 'ru',
      flag: '🇷🇺',
    ),
    LanguageOption(
      name: 'English',
      nativeName: 'English',
      code: 'en',
      flag: '🇺🇸',
    ),
    LanguageOption(
      name: 'Español',
      nativeName: 'Español',
      code: 'es',
      flag: '🇪🇸',
    ),
    LanguageOption(
      name: 'Français',
      nativeName: 'Français',
      code: 'fr',
      flag: '🇫🇷',
    ),
    LanguageOption(
      name: 'Deutsch',
      nativeName: 'Deutsch',
      code: 'de',
      flag: '🇩🇪',
    ),
    LanguageOption(
      name: 'Italiano',
      nativeName: 'Italiano',
      code: 'it',
      flag: '🇮🇹',
    ),
    LanguageOption(
      name: 'Português',
      nativeName: 'Português',
      code: 'pt',
      flag: '🇵🇹',
    ),
    LanguageOption(
      name: '中文',
      nativeName: '中文',
      code: 'zh',
      flag: '🇨🇳',
    ),
    LanguageOption(
      name: '日本語',
      nativeName: '日本語',
      code: 'ja',
      flag: '🇯🇵',
    ),
    LanguageOption(
      name: '한국어',
      nativeName: '한국어',
      code: 'ko',
      flag: '🇰🇷',
    ),
    LanguageOption(
      name: 'العربية',
      nativeName: 'العربية',
      code: 'ar',
      flag: '🇸🇦',
    ),
    LanguageOption(
      name: 'हिन्दी',
      nativeName: 'हिन्दी',
      code: 'hi',
      flag: '🇮🇳',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Язык',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Выберите язык'),
          const SizedBox(height: 16),
          
          ..._languages.map((language) => _buildLanguageOption(language)).toList(),
          
          const SizedBox(height: 32),
          
          _buildSectionTitle('Дополнительные настройки'),
          const SizedBox(height: 16),
          
          _buildActionTile(
            title: 'Автоматическое определение языка',
            subtitle: 'Определять язык по настройкам системы',
            icon: Icons.auto_awesome,
            onTap: () {
              _showAutoLanguageDialog();
            },
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            title: 'Перевод сообщений',
            subtitle: 'Автоматически переводить сообщения',
            icon: Icons.translate,
            onTap: () {
              _showTranslationSettings();
            },
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Предварительный просмотр'),
          const SizedBox(height: 16),
          
          _buildLanguagePreview(),
          
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

  Widget _buildLanguageOption(LanguageOption language) {
    final isSelected = _selectedLanguage == language.name;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Text(
          language.flag,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          language.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blue : Colors.black,
          ),
        ),
        subtitle: Text(
          language.nativeName,
          style: TextStyle(
            color: isSelected ? Colors.blue.withOpacity(0.8) : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : const Icon(Icons.radio_button_unchecked),
        onTap: () {
          setState(() {
            _selectedLanguage = language.name;
          });
        },
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

  Widget _buildLanguagePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Анна Петрова',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'В сети',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Привет! Как дела?',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Все хорошо, спасибо! А у тебя как?',
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAutoLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Автоматическое определение языка'),
        content: const Text(
          'Приложение будет автоматически определять язык интерфейса на основе настроек вашего устройства.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedLanguage = 'Автоматически';
              });
            },
            child: const Text('Включить'),
          ),
        ],
      ),
    );
  }

  void _showTranslationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Перевод сообщений'),
        content: const Text(
          'Настройте автоматический перевод сообщений на ваш язык.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement translation settings
            },
            child: const Text('Настроить'),
          ),
        ],
      ),
    );
  }
}

class LanguageOption {
  final String name;
  final String nativeName;
  final String code;
  final String flag;

  LanguageOption({
    required this.name,
    required this.nativeName,
    required this.code,
    required this.flag,
  });
}
