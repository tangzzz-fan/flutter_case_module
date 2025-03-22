import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../domain/entities/message.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../../core/exceptions.dart';
import 'socket_connection_manager.dart';

abstract class ChatSocketDatasource {
  Future<bool> connect();
  Future<bool> disconnect();
  Future<List<MessageModel>> getMessages(String chatRoomId);
  Future<MessageModel> sendMessage(
    String chatRoomId,
    String content,
    MessageType type,
    String senderId,
  );
  Stream<MessageModel> get messageStream;
  Stream<UserModel> get userStatusStream;
}

class ChatSocketDatasourceImpl implements ChatSocketDatasource {
  final SocketConnectionManager _connectionManager;
  final _messageController = StreamController<MessageModel>.broadcast();
  final _userStatusController = StreamController<UserModel>.broadcast();

  ChatSocketDatasourceImpl({required String serverUrl})
      : _connectionManager = SocketConnectionManager(
            serverUrl: serverUrl, authInfo: {'username': 'guest_user'}) {
    _initListeners();
  }

  void _initListeners() {
    final socket = _connectionManager.socket;

    // 消息事件监听
    socket.on('message', (data) {
      try {
        final message = MessageModel.fromJson(data);
        _messageController.add(message);
      } catch (e) {
        print('解析消息失败: $e');
      }
    });

    // 用户状态变更监听
    socket.on('user_status', (data) {
      try {
        final user = UserModel.fromJson(data);
        _userStatusController.add(user);
      } catch (e) {
        print('解析用户状态失败: $e');
      }
    });
  }

  @override
  Future<bool> connect() => _connectionManager.connect();

  @override
  Future<bool> disconnect() => _connectionManager.disconnect();

  @override
  Future<List<MessageModel>> getMessages(String chatRoomId) async {
    await connect(); // 确保连接

    try {
      final completer = Completer<List<dynamic>>();
      final socket = _connectionManager.socket;

      socket.emitWithAck('get_messages', {'chatRoomId': chatRoomId},
          ack: (data) {
        if (data is List) {
          completer.complete(data);
        } else {
          completer.completeError(ServerException());
        }
      });

      final result = await completer.future.timeout(const Duration(seconds: 5),
          onTimeout: () {
        throw ServerException();
      });

      return result.map((e) => MessageModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<MessageModel> sendMessage(
    String chatRoomId,
    String content,
    MessageType type,
    String senderId,
  ) async {
    await connect(); // 确保连接

    try {
      final completer = Completer<Map<String, dynamic>>();
      final socket = _connectionManager.socket;

      socket.emitWithAck('send_message', {
        'chatRoomId': chatRoomId,
        'content': content,
        'type': type.toString().split('.').last,
        'senderId': senderId,
      }, ack: (data) {
        if (data is Map<String, dynamic>) {
          completer.complete(data);
        } else {
          completer.completeError(ServerException());
        }
      });

      final result = await completer.future.timeout(const Duration(seconds: 5),
          onTimeout: () {
        throw ServerException();
      });

      return MessageModel.fromJson(result);
    } catch (e) {
      throw ServerException();
    }
  }

  void dispose() {
    _messageController.close();
    _userStatusController.close();
  }

  @override
  Stream<MessageModel> get messageStream => _messageController.stream;

  @override
  Stream<UserModel> get userStatusStream => _userStatusController.stream;
}
