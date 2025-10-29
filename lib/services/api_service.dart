import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.111:8000/api/v1';
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

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }

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

  String get _origin {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80)}';
  }

  String? resolveUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final u = Uri.parse(trimmed);
        // normalize dev hosts to current origin
        if (u.host == '0.0.0.0' || u.host == '127.0.0.1' || u.host == 'localhost') {
          final base = Uri.parse(_origin);
          final normalized = Uri(
            scheme: base.scheme,
            host: base.host,
            port: base.port,
            path: u.path,
            query: u.query,
          );
          return normalized.toString();
        }
        return trimmed;
      } catch (_) {
        return trimmed;
      }
    }
    if (trimmed.startsWith('/files') || trimmed.startsWith('/static') || trimmed.startsWith('/uploads')) {
      return '$_origin$trimmed';
    }
    final lower = trimmed.toLowerCase();
    final isFileLike = lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp') || lower.endsWith('.gif');
    if (isFileLike) {
      return trimmed.startsWith('/') ? '$_origin$trimmed' : '$_origin/$trimmed';
    }
    return null;
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> sendSmsCode(String phoneNumber) async {
    try {
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

  Future<Map<String, dynamic>> getUserById(String id) async {
    try {
      final response = await _dio.get('/users/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> setPublicKey(String publicKey) async {
    try {
      await _dio.put('/users/me/public-key', data: { 'public_key': publicKey });
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

  Future<void> addContact(int userId) async {
    try {
      await _dio.post('/users/contacts/$userId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeContact(int userId) async {
    try {
      await _dio.delete('/users/contacts/$userId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getChats() async {
    try {
      final response = await _dio.get('/chats/');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createChat(Map<String, dynamic> chatData) async {
    try {
      final response = await _dio.post('/chats/', data: chatData);
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

  Future<List<dynamic>> getMessages(String chatId, {int? limit, int? offset}) async {
    try {
      final response = await _dio.get('/messages/chat/$chatId', queryParameters: {
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
      final payload = {
        'chat_id': int.tryParse(chatId) ?? chatId,
        ...messageData,
      };
      final response = await _dio.post('/messages/', data: payload);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

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

  String getWebSocketUrl({required String accessToken, int? chatId}) {
    final baseWs = 'ws://192.168.0.111:8000/api/v1/ws';
    if (chatId != null) {
      return '$baseWs/chat/$chatId/$accessToken';
    }
    return '$baseWs/$accessToken';
  }

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

final ApiService apiService = ApiService();
