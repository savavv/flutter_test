import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../widgets/custom_app_bar.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedAvatar;

  final List<String> _avatarOptions = [
    '👨', '👩', '🧑', '👨‍💼', '👩‍💼', '👨‍🎓', '👩‍🎓',
    '👨‍🚀', '👩‍🚀', '👨‍🍳', '👩‍🍳', '👨‍🎨', '👩‍🎨', '👨‍⚕️',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String _generateUsername(String firstName, String lastName) {
    final baseUsername = '${firstName.toLowerCase()}_${lastName.toLowerCase()}';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '$baseUsername$timestamp';
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Обновляем профиль пользователя через API
    final success = await authProvider.updateProfile(
      name: '${_firstNameController.text} ${_lastNameController.text}',
      username: _usernameController.text.isEmpty
          ? _generateUsername(_firstNameController.text, _lastNameController.text)
          : _usernameController.text,
      avatarUrl: _selectedAvatar,
    );

    if (!success) {
      return; 
    }

    // Загружаем данные пользователя из API после успешного обновления
    await userProvider.loadCurrentUser();

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/main',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Настройка профиля',
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Настройте свой профиль',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Добавьте фото и основную информацию',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                        color: Colors.grey[100],
                      ),
                      child: _selectedAvatar != null
                          ? Center(
                              child: Text(
                                _selectedAvatar!,
                                style: const TextStyle(fontSize: 60),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        _showAvatarPicker();
                      },
                      child: const Text(
                        'Выбрать аватар',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите фамилию';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Имя пользователя (необязательно)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.alternate_email),
                  hintText: 'Будет сгенерировано автоматически',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _completeRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Завершить регистрацию',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Выберите аватар',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _avatarOptions.length,
                  itemBuilder: (context, index) {
                    final avatar = _avatarOptions[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatar = avatar;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedAvatar == avatar
                                ? Colors.blue
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          color: Colors.grey[100],
                        ),
                        child: Center(
                          child: Text(
                            avatar,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
