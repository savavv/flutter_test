import 'user.dart';
import 'message.dart';

enum ChatType {
  private,
  group,
  channel,
}

class Chat {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final ChatType type;
  final List<String> participants;
  final Message? lastMessage;
  final DateTime lastActivity;
  final int unreadCount;
  final bool isPinned;
  final bool isArchived;
  final bool isMuted;
  final Map<String, dynamic>? settings;

  Chat({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.type,
    required this.participants,
    this.lastMessage,
    required this.lastActivity,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.isMuted = false,
    this.settings,
  });

  Chat copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    ChatType? type,
    List<String>? participants,
    Message? lastMessage,
    DateTime? lastActivity,
    int? unreadCount,
    bool? isPinned,
    bool? isArchived,
    bool? isMuted,
    Map<String, dynamic>? settings,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      settings: settings ?? this.settings,
    );
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      avatarUrl: json['avatarUrl'],
      type: ChatType.values[json['type']],
      participants: json['participants'].cast<String>(),
      lastMessage: json['lastMessage'] != null 
          ? Message.fromJson(json['lastMessage']) 
          : null,
      lastActivity: DateTime.parse(json['lastActivity']),
      unreadCount: json['unreadCount'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      isArchived: json['isArchived'] ?? false,
      isMuted: json['isMuted'] ?? false,
      settings: json['settings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'type': type.index,
      'participants': participants,
      'lastMessage': lastMessage?.toJson(),
      'lastActivity': lastActivity.toIso8601String(),
      'unreadCount': unreadCount,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isMuted': isMuted,
      'settings': settings,
    };
  }
}
