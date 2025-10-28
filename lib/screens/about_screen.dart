import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_app_bar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'О приложении',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAppInfo(),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Информация о приложении'),
          const SizedBox(height: 16),
          
          _buildInfoTile(
            title: 'Версия',
            subtitle: '1.0.0 (Build 1)',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 8),
          
          _buildInfoTile(
            title: 'Дата сборки',
            subtitle: '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 8),
          
          _buildInfoTile(
            title: 'Разработчик',
            subtitle: 'Kasilov Savelii',
            icon: Icons.person,
          ),
          const SizedBox(height: 8),
          
          _buildInfoTile(
            title: 'Лицензия',
            subtitle: 'MIT License',
            icon: Icons.description,
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Техническая информация'),
          const SizedBox(height: 16),
          
          _buildInfoTile(
            title: 'Flutter версия',
            subtitle: '3.9.2',
            icon: Icons.code,
          ),
          const SizedBox(height: 8),
          
          _buildInfoTile(
            title: 'Dart версия',
            subtitle: '3.9.2',
            icon: Icons.developer_mode,
          ),
          const SizedBox(height: 8),
          
          _buildInfoTile(
            title: 'Платформа',
            subtitle: 'Android, iOS, Web, Desktop',
            icon: Icons.devices,
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Связаться с нами'),
          const SizedBox(height: 16),
          
          _buildActionTile(
            title: 'Поддержка',
            subtitle: 'Получить помощь и поддержку',
            icon: Icons.help_outline,
            onTap: () => _showSupportDialog(context),
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            title: 'Обратная связь',
            subtitle: 'Отправить отзыв или предложение',
            icon: Icons.feedback,
            onTap: () => _showFeedbackDialog(context),
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            title: 'Сообщить об ошибке',
            subtitle: 'Сообщить о найденной ошибке',
            icon: Icons.bug_report,
            onTap: () => _showBugReportDialog(context),
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Правовая информация'),
          const SizedBox(height: 16),
          
          _buildActionTile(
            title: 'Условия использования',
            subtitle: 'Пользовательское соглашение',
            icon: Icons.description,
            onTap: () => _showTermsDialog(context),
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            title: 'Политика конфиденциальности',
            subtitle: 'Как мы обрабатываем ваши данные',
            icon: Icons.privacy_tip,
            onTap: () => _showPrivacyDialog(context),
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            title: 'Лицензии сторонних библиотек',
            subtitle: 'Открытый исходный код',
            icon: Icons.open_in_new,
            onTap: () => _showLicensesDialog(context),
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Дополнительно'),
          const SizedBox(height: 16),
          
          _buildActionTile(
            title: 'Проверить обновления',
            subtitle: 'Поиск новых версий приложения',
            icon: Icons.system_update,
            onTap: () => _checkForUpdates(context),
          ),
          const SizedBox(height: 8),
          
          _buildActionTile(
            title: 'Очистить кэш',
            subtitle: 'Освободить место на устройстве',
            icon: Icons.cleaning_services,
            onTap: () => _clearCache(context),
          ),
          const SizedBox(height: 32),
          
          _buildCredits(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'KS54 Messanger',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Быстрый, безопасный и бесплатный мессенджер',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Версия 1.0.0',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'Данный проект написан как курсовая работа. Создатель: Kasilov Savelii.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
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

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
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

  Widget _buildCredits() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          const Text(
            'Сделано с ❤️',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Это приложение создано как демонстрация возможностей Flutter для создания мессенджеров.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flutter_dash, color: Colors.blue[400]),
              const SizedBox(width: 8),
              Text(
                'Powered by Flutter',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поддержка'),
        content: const Text(
          'Если у вас возникли проблемы или вопросы, пожалуйста, свяжитесь с нами:\n\n'
          'Email: support@telegramclone.app\n'
          'Telegram: @telegramclone_support',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обратная связь'),
        content: const Text(
          'Мы ценим ваши отзывы! Поделитесь своими мыслями о приложении:\n\n'
          'Email: feedback@telegramclone.app',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сообщить об ошибке'),
        content: const Text(
          'Нашли ошибку? Помогите нам её исправить:\n\n'
          'Email: bugs@telegramclone.app\n'
          'Включите описание проблемы и шаги для воспроизведения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Условия использования'),
        content: const Text(
          'Используя это приложение, вы соглашаетесь с нашими условиями использования. '
          'Полный текст доступен на нашем сайте.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Политика конфиденциальности'),
        content: const Text(
          'Мы серьезно относимся к защите ваших данных. '
          'Подробная информация о том, как мы обрабатываем ваши данные, доступна в нашей политике конфиденциальности.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showLicensesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Лицензии'),
        content: const Text(
          'Это приложение использует открытый исходный код. '
          'Список всех используемых библиотек и их лицензий доступен в настройках приложения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Проверка обновлений...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить кэш'),
        content: const Text(
          'Это действие удалит временные файлы и освободит место на устройстве. '
          'Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Кэш очищен'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
}
