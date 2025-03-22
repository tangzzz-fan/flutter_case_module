import 'package:flutter_module/features/chat/data/models/message_model.dart';
import 'package:flutter_module/features/chat/data/models/user_model.dart';

enum ConnectionStatus { initial, connecting, connected, disconnected, error }

class ChatState {
  final ConnectionStatus connectionStatus;
  final List<UserModel> users;
  final List<MessageModel> messages;

  ChatState({
    required this.connectionStatus,
    required this.users,
    required this.messages,
  });

  factory ChatState.initial() {
    return ChatState(
      connectionStatus: ConnectionStatus.initial,
      users: [],
      messages: [],
    );
  }

  ChatState copyWith({
    ConnectionStatus? connectionStatus,
    List<UserModel>? users,
    List<MessageModel>? messages,
  }) {
    return ChatState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      users: users ?? this.users,
      messages: messages ?? this.messages,
    );
  }
}
