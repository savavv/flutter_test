import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'package:intl/intl.dart';

class ChatItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatItem({
    super.key,
    required this.chat,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildAvatar(),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.name,
              style: TextStyle(
                fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.isPinned)
            const Icon(
              Icons.push_pin,
              size: 16,
              color: Colors.grey,
            ),
          if (chat.isMuted)
            const Icon(
              Icons.volume_off,
              size: 16,
              color: Colors.grey,
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              chat.lastMessage?.content ?? '',
              style: TextStyle(
                color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(chat.lastActivity),
            style: TextStyle(
              color: chat.unreadCount > 0 ? Colors.blue : Colors.grey[600],
              fontSize: 12,
              fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      trailing: chat.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey[300],
      backgroundImage: chat.avatarUrl != null
          ? NetworkImage(chat.avatarUrl!)
          : null,
      child: chat.avatarUrl == null
          ? Text(
              chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == yesterday) {
      return 'Вчера';
    } else {
      return DateFormat('dd.MM').format(time);
    }
  }
}
