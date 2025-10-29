import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/e2ee_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentPhoneNumber;
  String? _verificationCode;
  bool _isLoading = false;
  String? _errorMessage;
  String? _accessToken;
  String? _refreshToken;
  bool _useOfflineMode = false; // Отключаем режим имитации, работаем только через API

  bool get isAuthenticated => _isAuthenticated;
  String? get currentPhoneNumber => _currentPhoneNumber;
  String? get verificationCode => _verificationCode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get accessToken => _accessToken;
  bool get useOfflineMode => _useOfflineMode;

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

  void toggleOfflineMode() {
    _useOfflineMode = !_useOfflineMode;
    notifyListeners();
  }

  void _setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    apiService.setAuthToken(accessToken);
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _accessToken = null;
    _refreshToken = null;
    _currentPhoneNumber = null;
    _verificationCode = null;
    apiService.clearAuthToken();
    notifyListeners();
  }

  Future<bool> sendSmsCode(String phoneNumber) async {
    setLoading(true);
    clearError();

    try {
      if (phoneNumber.isEmpty) {
        setError('Введите номер телефона');
        setLoading(false);
        return false;
      }
      if (phoneNumber.length < 10 || phoneNumber.length > 20) {
        setError('Номер телефона должен содержать от 10 до 20 символов');
        setLoading(false);
        return false;
      }

      final response = await apiService.sendSmsCode(phoneNumber);
      
      if (response['success'] == true) {
        _currentPhoneNumber = phoneNumber;
        _verificationCode = response['code']?.toString();

        // Симулируем пуш-уведомление с кодом
        if (_verificationCode != null) {
          await notificationService.showSmsCodeNotification(
            phoneNumber: phoneNumber,
            code: _verificationCode!,
          );
        }
        
        if (kDebugMode) {
          print('SMS код отправлен на $phoneNumber. Код: $_verificationCode');
        }
        
        setLoading(false);
        return true;
      } else {
        setError(response['message'] ?? response['detail'] ?? 'Ошибка отправки SMS');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Ошибка соединения с сервером: ${e.toString()}');
      setLoading(false);
      return false;
    }
  }

  Future<bool> verifySmsCode(String code) async {
    if (_isAuthenticated) {
      return true;
    }

    if (_currentPhoneNumber == null) {
      setError('Номер телефона не найден');
      return false;
    }

    if (_isLoading) {
      return false;
    }

    setLoading(true);
    clearError();

    try {
      final response = await apiService.verifySmsCode(_currentPhoneNumber!, code);

      final hasTokens = response['access_token'] != null && response['refresh_token'] != null;
      final isSuccess = response['success'] == true || hasTokens;

      if (isSuccess) {
        if (hasTokens) {
          _setTokens(response['access_token'], response['refresh_token']);
          try {
            await e2eeService.publishPublicKey();
          } catch (e) {
            if (kDebugMode) {
              print('Failed to publish public key: $e');
            }
          }
        }
        setLoading(false);
        if (kDebugMode) {
          print('SMS код подтвержден');
        }
        return true;
      }

      setError(response['message'] ?? response['detail'] ?? 'Неверный код подтверждения');
      setLoading(false);
      return false;
    } catch (e) {
      setError('Ошибка соединения с сервером: ${e.toString()}');
      setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String username,
    String? avatarUrl,
  }) async {
    if (!_isAuthenticated) {
      setError('Необходима авторизация');
      return false;
    }

    if (name.isEmpty) {
      setError('Введите имя');
      return false;
    }
    if (username.isEmpty) {
      setError('Введите username');
      return false;
    }

    setLoading(true);
    clearError();

    try {
      final userData = {
        'first_name': name.split(' ').first,
        'last_name': name.split(' ').length > 1 ? name.split(' ').last : null,
        'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

      final response = await apiService.updateUser(userData);
      
      if (response['success'] == true || response['id'] != null) {
        setLoading(false);
        if (kDebugMode) {
          print('✅ Профиль обновлен: $name');
        }
        return true;
      } else {
        setError(response['message'] ?? response['detail'] ?? 'Ошибка обновления профиля');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Ошибка соединения с сервером: ${e.toString()}');
      setLoading(false);
      return false;
    }
  }

  Future<bool> login(String phoneNumber, String password) async {
    setLoading(true);
    clearError();

    try {
      if (_useOfflineMode) {
        await Future.delayed(const Duration(seconds: 1));
        _accessToken = 'offline_token_${DateTime.now().millisecondsSinceEpoch}';
        _refreshToken = 'offline_refresh_${DateTime.now().millisecondsSinceEpoch}';
        _currentPhoneNumber = phoneNumber;
        _isAuthenticated = true;
        setLoading(false);
        if (kDebugMode) {
          print('🔐 Пользователь авторизован');
        }
        return true;
      } else {
        final response = await apiService.login(phoneNumber, password);
        
        if (response['success'] == true) {
          if (response['access_token'] != null && response['refresh_token'] != null) {
            _setTokens(response['access_token'], response['refresh_token']);
            try {
              await e2eeService.publishPublicKey();
            } catch (e) {
              if (kDebugMode) {
                print('Failed to publish public key: $e');
              }
            }
          }
          
          _currentPhoneNumber = phoneNumber;
          setLoading(false);
          
          if (kDebugMode) {
            print('Пользователь авторизован');
          }
          
          return true;
        } else {
          setError(response['message'] ?? 'Неверные учетные данные');
          setLoading(false);
          return false;
        }
      }
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) {
      return false;
    }

    try {
      if (_useOfflineMode) {
        _accessToken = 'offline_token_${DateTime.now().millisecondsSinceEpoch}';
        return true;
      } else {
        final response = await apiService.refreshToken(_refreshToken!);
        
        if (response['success'] == true && response['access_token'] != null) {
          _accessToken = response['access_token'];
          apiService.setAuthToken(_accessToken!);
          
          if (response['refresh_token'] != null) {
            _refreshToken = response['refresh_token'];
          }
          
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка обновления токена: $e');
      }
    }
    
    logout();
    return false;
  }

  String _generateVerificationCode() {
    return (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
  }

  void resendCode() {
    if (_currentPhoneNumber != null) {
      sendSmsCode(_currentPhoneNumber!);
    }
  }
}