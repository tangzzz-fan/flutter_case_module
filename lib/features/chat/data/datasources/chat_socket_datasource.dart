import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../domain/entities/message.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../../core/exceptions.dart';

abstract class ChatSocketDatasource {
  Future<bool> connect();
  Future<bool> disconnect();
  Future<List<MessageModel>> getMessages(String chatRoomId);
  Future<MessageModel> sendMessage(
      String chatRoomId, String content, MessageType type);
  Stream<MessageModel> get messageStream;
  Stream<UserModel> get userStatusStream;
}

class ChatSocketDatasourceImpl implements ChatSocketDatasource {
  final String serverUrl;
  late IO.Socket _socket;
  final _messageController = StreamController<MessageModel>.broadcast();
  final _userStatusController = StreamController<UserModel>.broadcast();

  ChatSocketDatasourceImpl({required this.serverUrl}) {
    _initSocket();
  }

  void _initSocket() {
    _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build());

    // 添加消息监听
    _socket.on('message', (data) {
      final message = MessageModel.fromJson(data);
      _messageController.add(message);
    });

    // 用户状态变更
    _socket.on('user_status', (data) {
      final user = UserModel.fromJson(data);
      _userStatusController.add(user);
    });
  }

  @override
  Future<bool> connect() async {
    try {
      _socket.connect();
      return true;
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      _socket.disconnect();
      return true;
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String chatRoomId) async {
    try {
      final completer = Completer<List<dynamic>>();

      _socket.emitWithAck('get_messages', {'chatRoomId': chatRoomId},
          ack: (data) {
        completer.complete(data);
      });

      final result = await completer.future.timeout(const Duration(seconds: 5));
      return result.map((e) => MessageModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<MessageModel> sendMessage(
      String chatRoomId, String content, MessageType type) async {
    try {
      final completer = Completer<Map<String, dynamic>>();

      _socket.emitWithAck('send_message', {
        'chatRoomId': chatRoomId,
        'content': content,
        'type': type.toString().split('.').last
      }, ack: (data) {
        completer.complete(data);
      });

      final result = await completer.future.timeout(const Duration(seconds: 5));
      return MessageModel.fromJson(result);
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Stream<MessageModel> get messageStream => _messageController.stream;

  @override
  Stream<UserModel> get userStatusStream => _userStatusController.stream;
}
