class User {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime lastSeen;
  final String? phoneNumber;

  User({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.isOnline = false,
    required this.lastSeen,
    this.phoneNumber,
  });

  User copyWith({
    String? id,
    String? name,
    String? username,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    String? phoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      avatarUrl: json['avatarUrl'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: DateTime.parse(json['lastSeen']),
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'phoneNumber': phoneNumber,
    };
  }
}
