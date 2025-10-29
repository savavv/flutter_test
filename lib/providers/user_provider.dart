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
      final response = await apiService.getCurrentUser();
      final userData = response;
      final avatar = apiService.resolveUrl(userData['avatar_url']);
      _currentUser = User(
        id: userData['id']?.toString() ?? '',
        name: '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim(),
        username: userData['username'] ?? '',
        avatarUrl: avatar,
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
      final updated = response['user'] ?? response;
      if (updated != null && (updated is Map<String, dynamic>)) {
        final avatar = apiService.resolveUrl(updated['avatar_url']);
        _currentUser = User(
          id: updated['id']?.toString() ?? _currentUser?.id ?? '',
          name: updated['name'] ?? _currentUser?.name ?? '',
          username: updated['username'] ?? _currentUser?.username ?? '',
          avatarUrl: avatar,
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

  Future<void> fetchContacts() async {
    try {
      final list = await apiService.getContacts();
      _contacts = list.map<User>((userData) {
        final avatar = apiService.resolveUrl(userData['avatar_url']);
        return User(
          id: userData['id'].toString(),
          name: '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim(),
          username: userData['username'] ?? '',
          avatarUrl: avatar,
          isOnline: userData['is_online'] ?? false,
          lastSeen: userData['last_seen'] != null
              ? DateTime.parse(userData['last_seen'])
              : DateTime.now(),
          phoneNumber: userData['phone_number'] ?? '',
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch contacts: $e');
      }
    }
  }

  Future<bool> addContactById(String userId) async {
    try {
      final id = int.tryParse(userId) ?? -1;
      if (id <= 0) return false;
      await apiService.addContact(id);
      await fetchContacts();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to add contact: $e');
      }
      return false;
    }
  }

  Future<bool> removeContactById(String userId) async {
    try {
      final id = int.tryParse(userId) ?? -1;
      if (id <= 0) return false;
      await apiService.removeContact(id);
      await fetchContacts();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to remove contact: $e');
      }
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
        avatarUrl: apiService.resolveUrl(userData['avatar_url']),
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
