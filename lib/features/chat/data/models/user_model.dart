import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';

// 方案1：暂时移除 freezed 相关代码
// part 'user_model.freezed.dart';
// part 'user_model.g.dart';

class UserModel {
  final String id;
  final String username;
  final bool isOnline;
  final String? avatar;

  UserModel({
    required this.id,
    required this.username,
    this.isOnline = false,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      isOnline: json['isOnline'] ?? false,
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'isOnline': isOnline,
      'avatar': avatar,
    };
  }
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
        isOnline: isOnline,
        lastSeen: null,
      );
}
