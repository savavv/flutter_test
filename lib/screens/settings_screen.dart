import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import 'edit_profile_screen.dart';
import 'privacy_settings_screen.dart';
import 'notifications_screen.dart';
import 'theme_settings_screen.dart';
import 'language_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Настройки'),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final currentUser = userProvider.currentUser;
          
          return ListView(
            children: [
              // Profile section
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: (currentUser?.avatarUrl != null &&
                              (currentUser!.avatarUrl!.startsWith('http://') ||
                               currentUser.avatarUrl!.startsWith('https://')))
                          ? NetworkImage(currentUser.avatarUrl!)
                          : null,
                      child: (currentUser?.avatarUrl == null ||
                              !(currentUser!.avatarUrl!.startsWith('http://') ||
                                currentUser.avatarUrl!.startsWith('https://')))
                          ? (currentUser?.avatarUrl != null && currentUser!.avatarUrl!.isNotEmpty)
                              ? Text(
                                  currentUser.avatarUrl!,
                                  style: const TextStyle(fontSize: 32),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentUser?.name ?? 'Пользователь',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentUser?.phoneNumber ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Settings sections
              _buildSettingsSection(
                title: 'Учетная запись',
                items: [
                  _buildSettingsItem(
                    icon: Icons.person,
                    title: 'Изменить профиль',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.security,
                    title: 'Приватность и безопасность',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PrivacySettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.data_usage,
                    title: 'Данные и память',
                    onTap: () {
                      // TODO: Implement data settings
                    },
                  ),
                ],
              ),
              
              _buildSettingsSection(
                title: 'Чат',
                items: [
                  _buildSettingsItem(
                    icon: Icons.chat,
                    title: 'Темы',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ThemeSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.notifications,
                    title: 'Уведомления',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.language,
                    title: 'Язык',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LanguageScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              _buildSettingsSection(
                title: 'Дополнительно',
                items: [
                  _buildSettingsItem(
                    icon: Icons.help_outline,
                    title: 'Помощь',
                    onTap: () {
                      // TODO: Implement help
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.info_outline,
                    title: 'О приложении',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              _buildSettingsSection(
                title: 'Выход',
                items: [
                  _buildSettingsItem(
                    icon: Icons.logout,
                    title: 'Выйти из аккаунта',
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(children: items),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выйти из аккаунта'),
          content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                authProvider.logout();
                Navigator.pop(context);
              },
              child: const Text(
                'Выйти',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
