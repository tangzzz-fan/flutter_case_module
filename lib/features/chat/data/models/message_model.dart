import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/message.dart';

// 暂时移除 freezed 相关代码
// part 'message_model.freezed.dart';
// part 'message_model.g.dart';

class MessageModel {
  final String id;
  final String content;
  final String fromUserId;
  final String? fromUsername;
  final String? toUserId;
  final String? toRoomId;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.content,
    required this.fromUserId,
    this.fromUsername,
    this.toUserId,
    this.toRoomId,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      content: json['content'],
      fromUserId: json['fromUserId'],
      fromUsername: json['fromUsername'],
      toUserId: json['toUserId'],
      toRoomId: json['toRoomId'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'toUserId': toUserId,
      'toRoomId': toRoomId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

extension MessageModelExtension on MessageModel {
  Message toMessage() => Message(
        id: id,
        senderId: fromUserId,
        receiverId: toUserId ?? '',
        content: content,
        timestamp: timestamp,
        isRead: false,
        type: MessageType.text,
      );
}
