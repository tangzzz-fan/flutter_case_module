import 'package:equatable/equatable.dart';
import 'message.dart';
import 'user.dart';

// part 'chat_room.freezed.dart';
// part 'chat_room.g.dart';

class ChatRoom extends Equatable {
  final String id;
  final String name;
  final List<User> members;
  final Message? lastMessage;
  final int? unreadCount;
  final bool? isGroup;
  final String? description;
  final DateTime? createdAt;
  final bool? isPrivate;
  final String? creatorId;
  final List<Message>? messages;

  const ChatRoom({
    required this.id,
    required this.name,
    required this.members,
    required this.description,
    required this.createdAt,
    required this.isPrivate,
    this.lastMessage,
    this.unreadCount,
    this.isGroup,
    this.creatorId,
    this.messages,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        members,
        lastMessage,
        unreadCount,
        isGroup,
        description,
        createdAt,
        isPrivate,
        creatorId,
        messages,
      ];

  // 从JSON创建实例
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      isPrivate: json['isPrivate'] as bool? ?? false,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int?,
      isGroup: json['isGroup'] as bool?,
      creatorId: json['creatorId'] as String?,
      messages: json['messages'] != null
          ? (json['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'members': members.map((e) => e.toJson()).toList(),
      'description': description,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'isPrivate': isPrivate,
      if (lastMessage != null) 'lastMessage': lastMessage!.toJson(),
      if (unreadCount != null) 'unreadCount': unreadCount,
      if (isGroup != null) 'isGroup': isGroup,
      'creatorId': creatorId,
      if (messages != null)
        'messages': messages!.map((e) => e.toJson()).toList(),
    };
  }

  // 创建新的实例，但可以更新某些字段
  ChatRoom copyWith({
    String? id,
    String? name,
    List<User>? members,
    Message? lastMessage,
    int? unreadCount,
    bool? isGroup,
    String? description,
    DateTime? createdAt,
    bool? isPrivate,
    String? creatorId,
    List<Message>? messages,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isGroup: isGroup ?? this.isGroup,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
      creatorId: creatorId ?? this.creatorId,
      messages: messages ?? this.messages,
    );
  }

  // 便于调试的字符串表示
  @override
  String toString() {
    return 'ChatRoom{id: $id, name: $name, members: ${members.length}}';
  }
}
