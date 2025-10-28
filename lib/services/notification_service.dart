import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (kDebugMode) {
      print('NotificationService initialized (simulation mode)');
    }
  }

  Future<bool> requestPermissions() async {
    // В режиме симуляции всегда возвращаем true
    return true;
  }

  Future<void> showSmsCodeNotification({
    required String phoneNumber,
    required String code,
  }) async {
    await initialize();
    
    if (kDebugMode) {
      print('📱 SMS УВЕДОМЛЕНИЕ:');
      print('   Номер: $phoneNumber');
      print('   Код: $code');
      print('   Время: ${DateTime.now().toString()}');
      print('   ────────────────────────────────');
    }
  }

  Future<void> showWelcomeNotification({
    required String userName,
  }) async {
    await initialize();

    if (kDebugMode) {
      print('🎉 ПРИВЕТСТВЕННОЕ УВЕДОМЛЕНИЕ:');
      print('   Добро пожаловать, $userName!');
      print('   Ваш аккаунт успешно создан.');
      print('   Время: ${DateTime.now().toString()}');
      print('   ────────────────────────────────');
    }
  }

  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    await initialize();

    if (kDebugMode) {
      print('💬 УВЕДОМЛЕНИЕ О СООБЩЕНИИ:');
      print('   От: $senderName');
      print('   Сообщение: $message');
      print('   Время: ${DateTime.now().toString()}');
      print('   ────────────────────────────────');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kDebugMode) {
      print('🗑️ Все уведомления отменены');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (kDebugMode) {
      print('🗑️ Уведомление $id отменено');
    }
  }
}

// Глобальный экземпляр сервиса уведомлений
final NotificationService notificationService = NotificationService();
