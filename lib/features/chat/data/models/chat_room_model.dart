import '../../domain/entities/chat_room.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/message.dart';
import 'message_model.dart';
import 'user_model.dart';

class ChatRoomModel {
  final String id;
  final String name;
  final List<User> members;
  final String? description;
  final DateTime? createdAt;
  final bool? isPrivate;
  final Message? lastMessage;
  final int? unreadCount;
  final bool? isGroup;
  final String? creatorId;

  ChatRoomModel({
    required this.id,
    required this.name,
    required this.members,
    required this.description,
    required this.createdAt,
    required this.isPrivate,
    this.lastMessage,
    this.unreadCount = 0,
    this.isGroup = false,
    this.creatorId,
  });

  // 从 JSON 创建 ChatRoomModel
  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      members: _membersFromJson(json['members'] as List<dynamic>),
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      isPrivate: json['isPrivate'] as bool? ?? false,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isGroup: json['isGroup'] as bool? ?? false,
      creatorId: json['creatorId'] as String?,
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'members': _membersToJson(members),
      'description': description,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'isPrivate': isPrivate,
      if (lastMessage != null) 'lastMessage': lastMessage!.toJson(),
      'unreadCount': unreadCount,
      'isGroup': isGroup,
      'creatorId': creatorId,
    };
  }

  // 从领域实体创建
  factory ChatRoomModel.fromChatRoom(ChatRoom chatRoom) => ChatRoomModel(
        id: chatRoom.id,
        name: chatRoom.name,
        members: chatRoom.members,
        description: chatRoom.description,
        createdAt: chatRoom.createdAt,
        isPrivate: chatRoom.isPrivate,
        lastMessage: chatRoom.lastMessage,
        unreadCount: chatRoom.unreadCount,
        isGroup: chatRoom.isGroup,
        creatorId: chatRoom.creatorId,
      );

  // 转换为领域实体
  ChatRoom toChatRoom() => ChatRoom(
        id: id,
        name: name,
        members: members,
        description: description,
        createdAt: createdAt,
        isPrivate: isPrivate ?? false,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        isGroup: isGroup,
        creatorId: creatorId,
      );

  // 创建副本并更新部分属性
  ChatRoomModel copyWith({
    String? id,
    String? name,
    List<User>? members,
    String? description,
    DateTime? createdAt,
    bool? isPrivate,
    Message? lastMessage,
    int? unreadCount,
    bool? isGroup,
    String? creatorId,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isGroup: isGroup ?? this.isGroup,
      creatorId: creatorId ?? this.creatorId,
    );
  }
}

// JSON转换帮助方法
List<User> _membersFromJson(List<dynamic> json) {
  return json.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
}

List<Map<String, dynamic>> _membersToJson(List<User> members) {
  return members.map((e) => e.toJson()).toList();
}
