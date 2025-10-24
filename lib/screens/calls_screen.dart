import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../widgets/custom_app_bar.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final List<CallHistory> _callHistory = [];

  @override
  void initState() {
    super.initState();
    _loadMockCallHistory();
  }

  void _loadMockCallHistory() {
    setState(() {
      _callHistory.addAll([
        CallHistory(
          id: '1',
          contact: User(
            id: 'user1',
            name: 'Анна Петрова',
            username: 'anna_pet',
            phoneNumber: '+7 (999) 123-45-67',
            isOnline: true,
            lastSeen: DateTime.now(),
          ),
          type: CallType.outgoing,
          duration: const Duration(minutes: 5, seconds: 30),
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        CallHistory(
          id: '2',
          contact: User(
            id: 'user2',
            name: 'Михаил Иванов',
            username: 'mike_ivan',
            phoneNumber: '+7 (999) 234-56-78',
            isOnline: false,
            lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
          type: CallType.incoming,
          duration: const Duration(minutes: 12, seconds: 45),
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        CallHistory(
          id: '3',
          contact: User(
            id: 'user3',
            name: 'Елена Смирнова',
            username: 'elena_sm',
            phoneNumber: '+7 (999) 345-67-89',
            isOnline: true,
            lastSeen: DateTime.now(),
          ),
          type: CallType.missed,
          duration: Duration.zero,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
        CallHistory(
          id: '4',
          contact: User(
            id: 'user4',
            name: 'Дмитрий Козлов',
            username: 'dmitry_koz',
            phoneNumber: '+7 (999) 456-78-90',
            isOnline: false,
            lastSeen: DateTime.now().subtract(const Duration(hours: 5)),
          ),
          type: CallType.outgoing,
          duration: const Duration(minutes: 3, seconds: 15),
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Звонки',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_call),
            onPressed: _showNewCallDialog,
          ),
        ],
      ),
      body: _callHistory.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _callHistory.length,
              itemBuilder: (context, index) {
                final call = _callHistory[index];
                return _buildCallItem(call);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Нет звонков',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'История звонков будет отображаться здесь',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallItem(CallHistory call) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[300],
        backgroundImage: call.contact.avatarUrl != null
            ? NetworkImage(call.contact.avatarUrl!)
            : null,
        child: call.contact.avatarUrl == null
            ? Text(
                call.contact.name.isNotEmpty ? call.contact.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      ),
      title: Text(
        call.contact.name,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _formatCallTimestamp(call.timestamp),
        style: TextStyle(
          color: Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (call.type == CallType.missed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Пропущен',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              call.type == CallType.missed ? Icons.call : Icons.videocam,
              color: Colors.blue,
            ),
            onPressed: () => _makeCall(call.contact, call.type == CallType.missed),
          ),
        ],
      ),
      onTap: () => _showCallDetails(call),
    );
  }

  String _formatCallTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  void _showNewCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый звонок'),
        content: const Text('Введите номер телефона для звонка'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement new call functionality
            },
            child: const Text('Позвонить'),
          ),
        ],
      ),
    );
  }

  void _makeCall(User contact, bool isVideo) {
    // TODO: Implement actual call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Звонок ${isVideo ? 'видео' : 'аудио'} ${contact.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCallDetails(CallHistory call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Детали звонка'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Контакт: ${call.contact.name}'),
            Text('Номер: ${call.contact.phoneNumber}'),
            Text('Тип: ${_getCallTypeText(call.type)}'),
            Text('Длительность: ${_formatDuration(call.duration)}'),
            Text('Время: ${_formatFullTimestamp(call.timestamp)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  String _getCallTypeText(CallType type) {
    switch (type) {
      case CallType.incoming:
        return 'Входящий';
      case CallType.outgoing:
        return 'Исходящий';
      case CallType.missed:
        return 'Пропущенный';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '0 сек';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}ч ${minutes}м ${seconds}с';
    } else if (minutes > 0) {
      return '${minutes}м ${seconds}с';
    } else {
      return '${seconds}с';
    }
  }

  String _formatFullTimestamp(DateTime timestamp) {
    return '${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

enum CallType { incoming, outgoing, missed }

class CallHistory {
  final String id;
  final User contact;
  final CallType type;
  final Duration duration;
  final DateTime timestamp;

  CallHistory({
    required this.id,
    required this.contact,
    required this.type,
    required this.duration,
    required this.timestamp,
  });
}
