import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  String _selectedTheme = 'Системная';
  String _selectedAccentColor = 'Синий';
  bool _useMaterial3 = true;
  bool _useDynamicColors = false;

  final List<ThemeOption> _themes = [
    ThemeOption(
      name: 'Светлая',
      description: 'Светлая тема с белым фоном',
      icon: Icons.light_mode,
      color: Colors.orange,
    ),
    ThemeOption(
      name: 'Темная',
      description: 'Темная тема с черным фоном',
      icon: Icons.dark_mode,
      color: Colors.purple,
    ),
    ThemeOption(
      name: 'Системная',
      description: 'Следует настройкам системы',
      icon: Icons.settings,
      color: Colors.blue,
    ),
  ];

  final List<ColorOption> _accentColors = [
    ColorOption(name: 'Синий', color: Colors.blue),
    ColorOption(name: 'Зеленый', color: Colors.green),
    ColorOption(name: 'Красный', color: Colors.red),
    ColorOption(name: 'Оранжевый', color: Colors.orange),
    ColorOption(name: 'Фиолетовый', color: Colors.purple),
    ColorOption(name: 'Розовый', color: Colors.pink),
    ColorOption(name: 'Бирюзовый', color: Colors.teal),
    ColorOption(name: 'Коричневый', color: Colors.brown),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Темы',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Основная тема'),
          const SizedBox(height: 16),
          
          ..._themes.map((theme) => _buildThemeOption(theme)).toList(),
          
          const SizedBox(height: 32),
          
          _buildSectionTitle('Цвет акцента'),
          const SizedBox(height: 16),
          
          _buildAccentColorGrid(),
          
          const SizedBox(height: 32),
          
          _buildSectionTitle('Дополнительные настройки'),
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            title: 'Material 3',
            subtitle: 'Использовать новый дизайн Material 3',
            value: _useMaterial3,
            onChanged: (value) {
              setState(() {
                _useMaterial3 = value;
              });
            },
          ),
          const SizedBox(height: 8),
          
          _buildSwitchTile(
            title: 'Динамические цвета',
            subtitle: 'Автоматически адаптировать цвета под обои',
            value: _useDynamicColors,
            onChanged: (value) {
              setState(() {
                _useDynamicColors = value;
              });
            },
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Предварительный просмотр'),
          const SizedBox(height: 16),
          
          _buildThemePreview(),
          
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

  Widget _buildThemeOption(ThemeOption theme) {
    final isSelected = _selectedTheme == theme.name;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? theme.color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? theme.color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          theme.icon,
          color: isSelected ? theme.color : Colors.grey[600],
        ),
        title: Text(
          theme.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? theme.color : Colors.black,
          ),
        ),
        subtitle: Text(
          theme.description,
          style: TextStyle(
            color: isSelected ? theme.color.withOpacity(0.8) : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: theme.color)
            : const Icon(Icons.radio_button_unchecked),
        onTap: () {
          setState(() {
            _selectedTheme = theme.name;
          });
        },
      ),
    );
  }

  Widget _buildAccentColorGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _accentColors.length,
      itemBuilder: (context, index) {
        final colorOption = _accentColors[index];
        final isSelected = _selectedAccentColor == colorOption.name;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAccentColor = colorOption.name;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: colorOption.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey[300]!,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Center(
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    )
                  : null,
            ),
          ),
        );
      },
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

  Widget _buildThemePreview() {
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
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeOption {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  ThemeOption({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class ColorOption {
  final String name;
  final Color color;

  ColorOption({
    required this.name,
    required this.color,
  });
}
