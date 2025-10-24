import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentPhoneNumber;
  String? _verificationCode;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentPhoneNumber => _currentPhoneNumber;
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

  Future<bool> sendSmsCode(String phoneNumber) async {
    setLoading(true);
    clearError();

    try {
      // Имитация отправки SMS
      await Future.delayed(const Duration(seconds: 2));
      
      // Генерируем случайный 4-значный код
      _verificationCode = _generateVerificationCode();
      _currentPhoneNumber = phoneNumber;
      
      setLoading(false);
      
      // В реальном приложении здесь был бы API вызов
      if (kDebugMode) {
        print('SMS код отправлен на $phoneNumber: $_verificationCode');
      }
      
      return true;
    } catch (e) {
      setError('Ошибка отправки SMS: ${e.toString()}');
      setLoading(false);
      return false;
    }
  }

  Future<bool> verifySmsCode(String code) async {
    setLoading(true);
    clearError();

    try {
      // Имитация проверки кода
      await Future.delayed(const Duration(seconds: 1));
      
      if (code == _verificationCode) {
        setLoading(false);
        return true;
      } else {
        setError('Неверный код подтверждения');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Ошибка проверки кода: ${e.toString()}');
      setLoading(false);
      return false;
    }
  }

  void login() {
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _currentPhoneNumber = null;
    _verificationCode = null;
    _errorMessage = null;
    notifyListeners();
  }

  String _generateVerificationCode() {
    // Генерируем 4-значный код
    return (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
  }

  void resendCode() {
    if (_currentPhoneNumber != null) {
      sendSmsCode(_currentPhoneNumber!);
    }
  }
}
