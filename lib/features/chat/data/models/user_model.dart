import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';

// 方案1：暂时移除 freezed 相关代码
// part 'user_model.freezed.dart';
// part 'user_model.g.dart';

class UserModel {
  final String id;
  final String username;
  final String? avatar;
  final String socketId;
  final bool connected;
  final DateTime lastActive;

  const UserModel({
    required this.id,
    required this.username,
    this.avatar,
    required this.socketId,
    required this.connected,
    required this.lastActive,
  });

  // 从 JSON 创建 UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String?,
      socketId: json['socketId'] as String,
      connected: json['connected'] as bool? ?? false,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'] as String)
          : DateTime.now(),
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'socketId': socketId,
      'connected': connected,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  // 创建一个新的 UserModel，但更新某些字段
  UserModel copyWith({
    String? id,
    String? username,
    String? avatar,
    String? socketId,
    bool? connected,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      socketId: socketId ?? this.socketId,
      connected: connected ?? this.connected,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  // 转换为领域实体
  User toEntity() => User(
        id: id,
        name: username,
        avatar: avatar,
        isOnline: connected,
        lastSeen: lastActive,
      );

  // 从领域实体创建
  factory UserModel.fromEntity(
    User user, {
    required String socketId,
    bool connected = false,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: user.id,
      username: user.name,
      avatar: user.avatar,
      socketId: socketId,
      connected: connected,
      lastActive: lastActive ?? DateTime.now(),
    );
  }
}

// 扩展方法，便于集合转换
extension UserModelListExtension on List<UserModel> {
  List<User> toEntityList() => map((model) => model.toEntity()).toList();
}

extension UserListExtension on List<User> {
  List<UserModel> toModelList({
    required String Function(User) getSocketId,
    bool Function(User)? getConnected,
    DateTime? Function(User)? getLastActive,
  }) =>
      map((entity) => UserModel.fromEntity(
            entity,
            socketId: getSocketId(entity),
            connected: getConnected?.call(entity) ?? false,
            lastActive: getLastActive?.call(entity),
          )).toList();
}

// JSON转换帮助方法
DateTime? _dateTimeFromJson(String? json) {
  if (json == null) return null;
  return DateTime.parse(json);
}

String? _dateTimeToJson(DateTime? dateTime) {
  if (dateTime == null) return null;
  return dateTime.toIso8601String();
}

extension UserModelExtension on UserModel {
  User toUser() => User(
        id: id,
        name: username,
        avatar: avatar,
        isOnline: connected,
        lastSeen: lastActive,
      );
}
