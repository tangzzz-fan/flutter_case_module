import 'package:flutter_module/features/chat/data/models/message_model.dart';
import 'package:flutter_module/features/chat/data/models/user_model.dart';
import 'package:flutter_module/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_module/features/chat/domain/entities/message.dart';
import 'package:flutter_module/features/chat/domain/entities/user.dart';

enum ConnectionStatus { initial, connecting, connected, disconnected, error }

enum ChatStatus { initial, loading, success, error }

class ChatState {
  final List<ChatRoom> chatRooms;
  final List<Message> messages;
  final List<User> users;
  final ConnectionStatus connectionStatus;
  final ChatStatus status;
  final String? errorMessage;

  const ChatState({
    required this.chatRooms,
    required this.messages,
    required this.users,
    required this.connectionStatus,
    this.status = ChatStatus.initial,
    this.errorMessage,
  });

  factory ChatState.initial() {
    return const ChatState(
      chatRooms: [],
      messages: [],
      users: [],
      connectionStatus: ConnectionStatus.initial,
      status: ChatStatus.initial,
    );
  }

  ChatState copyWith({
    List<ChatRoom>? chatRooms,
    List<Message>? messages,
    List<User>? users,
    ConnectionStatus? connectionStatus,
    ChatStatus? status,
    String? errorMessage,
  }) {
    return ChatState(
      chatRooms: chatRooms ?? this.chatRooms,
      messages: messages ?? this.messages,
      users: users ?? this.users,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
