import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Добавляем интерцептор для логирования в debug режиме
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }

    // Интерцептор для обработки ошибок
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        if (kDebugMode) {
          print('API Error: ${error.message}');
          print('Response: ${error.response?.data}');
        }
        handler.next(error);
      },
    ));
  }

  // Установка токена авторизации
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Удаление токена авторизации
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Аутентификация
  Future<Map<String, dynamic>> sendSmsCode(String phoneNumber) async {
    try {
      // Валидация длины номера телефона
      if (phoneNumber.length < 10 || phoneNumber.length > 20) {
        throw Exception('Номер телефона должен содержать от 10 до 20 символов');
      }

      final response = await _dio.post('/auth/send-verification', data: {
        'phone_number': phoneNumber,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifySmsCode(String phoneNumber, String code) async {
  try {
    // Валидация кода подтверждения - теперь 4 символа
    if (code.isEmpty || code.length != 4) {
      throw Exception('Код подтверждения должен содержать 4 символа');
    }
    if (!code.contains(RegExp(r'^[0-9]+$'))) {
      throw Exception('Код подтверждения должен содержать только цифры');
    }

    final response = await _dio.post('/auth/verify-code', data: {
      'phone_number': phoneNumber,
      'verification_code': code,
    });
    return response.data;
  } catch (e) {
    throw _handleError(e);
  }
 }

  // registerUser method removed - registration happens in verify_code endpoint

  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'phone_number': phoneNumber,
        'password': password,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Пользователи
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/users/me');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.put('/users/me', data: userData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Контакты
  Future<List<dynamic>> searchUsersByQuery(String query) async {
    try {
      final response = await _dio.get('/users/search', queryParameters: { 'query': query });
      return response.data as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserByUsername(String username) async {
    try {
      final response = await _dio.get('/users/by-username/$username');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserByPhone(String phone) async {
    try {
      final response = await _dio.get('/users/by-phone', queryParameters: { 'phone_number': phone });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getContacts() async {
    try {
      final response = await _dio.get('/users/contacts');
      return response.data as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> searchUsers(String query) async {
    try {
      final response = await _dio.get('/users/search', queryParameters: {
        'q': query,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Чаты
  Future<List<dynamic>> getChats() async {
    try {
      final response = await _dio.get('/chats');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createChat(Map<String, dynamic> chatData) async {
    try {
      final response = await _dio.post('/chats', data: chatData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getChat(String chatId) async {
    try {
      final response = await _dio.get('/chats/$chatId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Сообщения
  Future<List<dynamic>> getMessages(String chatId, {int? limit, int? offset}) async {
    try {
      final response = await _dio.get('/chats/$chatId/messages', queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> sendMessage(String chatId, Map<String, dynamic> messageData) async {
    try {
      final response = await _dio.post('/chats/$chatId/messages', data: messageData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Файлы
  Future<Map<String, dynamic>> uploadFile(String filePath, String fileType) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'file_type': fileType,
      });
      
      final response = await _dio.post('/files/upload', data: formData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // WebSocket соединение с токеном (и опциональным chatId)
  String getWebSocketUrl({required String accessToken, int? chatId}) {
    final baseWs = 'ws://127.0.0.1:8000/api/v1/ws';
    if (chatId != null) {
      return '$baseWs/chat/$chatId/$accessToken';
    }
    return '$baseWs/$accessToken';
  }

  // Обработка ошибок
  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Ошибка соединения с сервером';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final data = error.response?.data;
          
          if (statusCode == 401) {
            return 'Неверные учетные данные';
          } else if (statusCode == 403) {
            return 'Доступ запрещен';
          } else if (statusCode == 404) {
            return 'Ресурс не найден';
          } else if (statusCode == 422) {
            // Ошибки валидации
            if (data is Map<String, dynamic> && data.containsKey('detail')) {
              if (data['detail'] is List) {
                return data['detail'].join(', ');
              } else {
                return data['detail'].toString();
              }
            }
            return 'Ошибка валидации данных';
          } else if (statusCode == 500) {
            return 'Внутренняя ошибка сервера';
          } else {
            return 'Ошибка сервера: $statusCode';
          }
        case DioExceptionType.cancel:
          return 'Запрос отменен';
        case DioExceptionType.connectionError:
          return 'Ошибка подключения к серверу';
        case DioExceptionType.badCertificate:
          return 'Ошибка сертификата';
        case DioExceptionType.unknown:
        default:
          return 'Неизвестная ошибка: ${error.message}';
      }
    }
    return 'Ошибка: ${error.toString()}';
  }
}

// Глобальный экземпляр API сервиса
final ApiService apiService = ApiService();
