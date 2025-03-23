import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, audio, file, system }

class Message extends Equatable {
  final String id;
  final String content;
  final String senderId;
  final String receiverId;
  final DateTime timestamp;
  final MessageType type;
  final bool isRead;
  final bool isSent;
  final bool isDelivered;

  const Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    this.type = MessageType.text,
    this.isRead = false,
    this.isSent = true,
    this.isDelivered = false,
  });

  @override
  List<Object?> get props => [
        id,
        content,
        senderId,
        receiverId,
        timestamp,
        type,
        isRead,
        isSent,
        isDelivered,
      ];

  // 添加 toJson 方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'isRead': isRead,
      'isSent': isSent,
      'isDelivered': isDelivered,
    };
  }

  // 添加 fromJson 方法
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      senderId: json['senderId'] ?? json['fromUserId'] ?? '',
      receiverId: json['receiverId'] ?? json['toUserId'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      type: MessageType.values[json['type'] ?? 0],
      isRead: json['isRead'] ?? false,
      isSent: json['isSent'] ?? true,
      isDelivered: json['isDelivered'] ?? false,
    );
  }

  // 添加拷贝方法
  Message copyWith({
    String? id,
    String? content,
    String? senderId,
    String? receiverId,
    DateTime? timestamp,
    MessageType? type,
    bool? isRead,
    bool? isSent,
    bool? isDelivered,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      isSent: isSent ?? this.isSent,
      isDelivered: isDelivered ?? this.isDelivered,
    );
  }
}
