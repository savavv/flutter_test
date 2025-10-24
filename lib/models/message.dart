import 'user.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  sticker,
  location,
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final bool isEdited;
  final String? replyToMessageId;
  final List<String>? attachments;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.isEdited = false,
    this.replyToMessageId,
    this.attachments,
    this.metadata,
  });

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    bool? isEdited,
    String? replyToMessageId,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      content: json['content'],
      type: MessageType.values[json['type']],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      isEdited: json['isEdited'] ?? false,
      replyToMessageId: json['replyToMessageId'],
      attachments: json['attachments']?.cast<String>(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isEdited': isEdited,
      'replyToMessageId': replyToMessageId,
      'attachments': attachments,
      'metadata': metadata,
    };
  }
}
