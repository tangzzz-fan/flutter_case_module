import 'package:flutter_module/features/chat/data/models/message_model.dart';
import 'package:flutter_module/features/chat/data/models/user_model.dart';
import 'package:flutter_module/features/chat/domain/entities/message.dart';
import 'package:flutter_module/features/chat/domain/entities/user.dart';
import 'package:flutter_module/features/chat/domain/entities/chat_room.dart';

enum ConnectionStatus { initial, connecting, connected, disconnected, error }

class ChatState {
  final ConnectionStatus connectionStatus;
  final List<UserModel> users;
  final List<MessageModel> messages;
  final List<ChatRoom> chatRooms;

  const ChatState({
    required this.connectionStatus,
    required this.users,
    required this.messages,
    required this.chatRooms,
  });

  factory ChatState.initial() {
    return const ChatState(
      connectionStatus: ConnectionStatus.initial,
      users: [],
      messages: [],
      chatRooms: [],
    );
  }

  ChatState copyWith({
    ConnectionStatus? connectionStatus,
    List<UserModel>? users,
    List<MessageModel>? messages,
    List<ChatRoom>? chatRooms,
  }) {
    return ChatState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      users: users ?? this.users,
      messages: messages ?? this.messages,
      chatRooms: chatRooms ?? this.chatRooms,
    );
  }
}
