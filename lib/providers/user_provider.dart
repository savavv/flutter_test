import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  List<User> _contacts = [];
  List<User> _searchResults = [];

  User? get currentUser => _currentUser;
  List<User> get contacts => _contacts;
  List<User> get searchResults => _searchResults;

  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateCurrentUser(User user) {
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

  void searchUsers(String query) {
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _contacts.where((user) =>
          user.name.toLowerCase().contains(query.toLowerCase()) ||
          user.username.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
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
