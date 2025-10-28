import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  List<User> _contacts = [];
  List<User> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  List<User> get contacts => _contacts;
  List<User> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    setLoading(true);
    clearError();

    try {
      // Загружаем данные пользователя через API
      final response = await apiService.getCurrentUser();
      
      // Бэкенд возвращает данные напрямую, без обертки 'user'
      final userData = response;
      _currentUser = User(
        id: userData['id']?.toString() ?? '',
        name: '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim(),
        username: userData['username'] ?? '',
        avatarUrl: userData['avatar_url'],
        isOnline: userData['is_online'] ?? false,
        lastSeen: userData['last_seen'] != null 
            ? DateTime.parse(userData['last_seen']) 
            : DateTime.now(),
        phoneNumber: userData['phone_number'] ?? '',
      );
        
      setLoading(false);
      notifyListeners();
      
      if (kDebugMode) {
        print('👤 Данные пользователя загружены: ${_currentUser?.name}');
      }
    } catch (e) {
      setError('Ошибка соединения с сервером: ${e.toString()}');
      setLoading(false);
    }
  }

  Future<bool> updateCurrentUser({
    String? name,
    String? username,
    String? avatarUrl,
  }) async {
    setLoading(true);
    clearError();

    try {
      final userData = <String, dynamic>{};
      if (name != null) userData['name'] = name;
      if (username != null) userData['username'] = username;
      if (avatarUrl != null) userData['avatar_url'] = avatarUrl;

      final response = await apiService.updateUser(userData);

      // Бэкенд может вернуть либо полностью обновленного пользователя,
      // либо success + user. Поддерживаем оба варианта.
      final updated = response['user'] ?? response;
      if (updated != null && (updated is Map<String, dynamic>)) {
        _currentUser = User(
          id: updated['id']?.toString() ?? _currentUser?.id ?? '',
          name: updated['name'] ?? _currentUser?.name ?? '',
          username: updated['username'] ?? _currentUser?.username ?? '',
          avatarUrl: updated['avatar_url'] ?? _currentUser?.avatarUrl,
          isOnline: updated['is_online'] ?? _currentUser?.isOnline ?? false,
          lastSeen: updated['last_seen'] != null
              ? DateTime.parse(updated['last_seen'])
              : _currentUser?.lastSeen ?? DateTime.now(),
          phoneNumber: updated['phone_number'] ?? _currentUser?.phoneNumber ?? '',
        );
        setLoading(false);
        notifyListeners();
        return true;
      }

      setError(response['message'] ?? 'Ошибка обновления данных');
      setLoading(false);
      return false;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    setLoading(true);
    clearError();

    try {
      final response = await apiService.searchUsersByQuery(query);
      
      _searchResults = response.map<User>((userData) => User(
        id: userData['id'].toString(),
        name: userData['name'] ?? '',
        username: userData['username'] ?? '',
        avatarUrl: userData['avatar_url'],
        isOnline: userData['is_online'] ?? false,
        lastSeen: userData['last_seen'] != null 
            ? DateTime.parse(userData['last_seen']) 
            : DateTime.now(),
        phoneNumber: userData['phone_number'] ?? '',
      )).toList();
      
      setLoading(false);
      notifyListeners();
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void setContacts(List<User> contacts) {
    _contacts = contacts;
    notifyListeners();
  }

  void addContact(User contact) {
    if (!_contacts.any((c) => c.id == contact.id)) {
      _contacts.add(contact);
      notifyListeners();
    }
  }

  void removeContact(String contactId) {
    _contacts.removeWhere((contact) => contact.id == contactId);
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  User? getUserById(String id) {
    if (_currentUser?.id == id) return _currentUser;
    return _contacts.firstWhere((user) => user.id == id, orElse: () => User(
      id: '',
      name: 'Unknown User',
      username: '',
      lastSeen: DateTime.now(),
    ));
  }
}
