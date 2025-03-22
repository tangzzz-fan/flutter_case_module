import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    String? avatar,
    @Default(false) bool isOnline,
    @JsonKey(
      fromJson: _dateTimeFromJson,
      toJson: _dateTimeToJson,
    )
    DateTime? lastSeen,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromUser(User user) => UserModel(
        id: user.id,
        name: user.name,
        avatar: user.avatar,
        isOnline: user.isOnline,
        lastSeen: user.lastSeen,
      );
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
        name: name,
        avatar: avatar,
        isOnline: isOnline,
        lastSeen: lastSeen,
      );
}
