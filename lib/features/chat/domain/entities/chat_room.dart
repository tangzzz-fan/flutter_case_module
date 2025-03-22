import 'package:freezed_annotation/freezed_annotation.dart';
import 'message.dart';
import 'user.dart';

part 'chat_room.freezed.dart';
part 'chat_room.g.dart';

@freezed
class ChatRoom with _$ChatRoom {
  const factory ChatRoom({
    required String id,
    required String name,
    required List<User> participants,
    Message? lastMessage,
    @Default(0) int unreadCount,
    @Default(false) bool isGroup,
  }) = _ChatRoom;

  factory ChatRoom.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomFromJson(json);
}
