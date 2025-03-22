import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/message.dart';
import 'message_model.dart';
import 'user_model.dart';

part 'chat_room_model.freezed.dart';
part 'chat_room_model.g.dart';

@freezed
class ChatRoomModel with _$ChatRoomModel {
  const factory ChatRoomModel({
    required String id,
    required String name,
    @JsonKey(
      fromJson: _participantsFromJson,
      toJson: _participantsToJson,
    )
    required List<User> participants,
    @JsonKey(
      fromJson: _messageFromJson,
      toJson: _messageToJson,
    )
    Message? lastMessage,
    @Default(0) int unreadCount,
    @Default(false) bool isGroup,
  }) = _ChatRoomModel;

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomModelFromJson(json);

  factory ChatRoomModel.fromChatRoom(ChatRoom chatRoom) => ChatRoomModel(
        id: chatRoom.id,
        name: chatRoom.name,
        participants: chatRoom.participants,
        lastMessage: chatRoom.lastMessage,
        unreadCount: chatRoom.unreadCount,
        isGroup: chatRoom.isGroup,
      );
}

// JSON转换帮助方法
Message? _messageFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return Message.fromJson(json);
}

Map<String, dynamic>? _messageToJson(Message? message) {
  if (message == null) return null;
  return message.toJson();
}

List<User> _participantsFromJson(List<dynamic> json) {
  return json.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
}

List<Map<String, dynamic>> _participantsToJson(List<User> participants) {
  return participants.map((e) => e.toJson()).toList();
}

extension ChatRoomModelExtension on ChatRoomModel {
  ChatRoom toChatRoom() => ChatRoom(
        id: id,
        name: name,
        participants: participants,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        isGroup: isGroup,
      );
}
