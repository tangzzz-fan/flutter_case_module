import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/message.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String senderId,
    required String receiverId,
    required String content,
    required DateTime timestamp,
    @Default(false) bool isRead,
    @Default(MessageType.text) MessageType type,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  factory MessageModel.fromMessage(Message message) => MessageModel(
        id: message.id,
        senderId: message.senderId,
        receiverId: message.receiverId,
        content: message.content,
        timestamp: message.timestamp,
        isRead: message.isRead,
        type: message.type,
      );
}

extension MessageModelExtension on MessageModel {
  Message toMessage() => Message(
        id: id,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: timestamp,
        isRead: isRead,
        type: type,
      );
}
