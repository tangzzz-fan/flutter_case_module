import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../domain/entities/message.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../../core/exceptions.dart';
import 'socket_connection_manager.dart';

/// Socket数据源接口，负责实时通信
abstract class ChatSocketDataSource {
  /// 获取连接状态流
  Stream<bool> get connectionStatus;

  /// 获取消息流
  Stream<MessageModel> get messageStream;

  /// 获取用户状态流
  Stream<UserModel> get userStatusStream;

  /// 连接到Socket服务器
  Future<bool> connect();

  /// 断开Socket连接
  Future<bool> disconnect();

  /// 加入聊天室
  void joinRoom(String roomId);

  /// 离开聊天室
  void leaveRoom(String roomId);

  /// 发送消息
  void sendMessage(String roomId, String content, MessageType type);

  /// 更新认证信息
  void updateAuth(Map<String, dynamic> authInfo);

  /// 请求用户列表刷新
  void requestUserListRefresh();

  /// 请求房间列表刷新
  void requestRoomListRefresh();

  /// 标记消息为已读
  void markMessageAsRead(String messageId);

  /// 新增方法
  bool isConnected();
  IO.Socket getSocket();
  String getCurrentUserId();
}

/// Socket数据源实现
class ChatSocketDataSourceImpl implements ChatSocketDataSource {
  final IO.Socket _socket;
  final SocketConnectionManager _manager;

  // 流控制器
  final _messageStreamController = StreamController<MessageModel>.broadcast();
  final _userStatusStreamController = StreamController<UserModel>.broadcast();

  ChatSocketDataSourceImpl(this._socket, this._manager) {
    _setupEventListeners();
  }

  /// 设置事件监听器
  void _setupEventListeners() {
    // 新消息事件
    _socket.on('message', (data) {
      try {
        final message = MessageModel.fromJson(data);
        _messageStreamController.add(message);
      } catch (e) {
        print('处理消息事件时出错: $e');
      }
    });

    // 用户状态变化事件
    _socket.on('user_status', (data) {
      try {
        final user = UserModel.fromJson(data);
        _userStatusStreamController.add(user);
      } catch (e) {
        print('处理用户状态事件时出错: $e');
      }
    });

    // 其他事件可以在这里添加...
  }

  @override
  Stream<bool> get connectionStatus => _manager.connectionStatus;

  @override
  Stream<MessageModel> get messageStream => _messageStreamController.stream;

  @override
  Stream<UserModel> get userStatusStream => _userStatusStreamController.stream;

  @override
  Future<bool> connect() {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  Future<bool> disconnect() {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  void joinRoom(String roomId) {
    _socket.emit('join_room', {'roomId': roomId});
  }

  @override
  void leaveRoom(String roomId) {
    _socket.emit('leave_room', {'roomId': roomId});
  }

  @override
  void sendMessage(String roomId, String content, MessageType type) {
    _socket.emit('send_message', {
      'roomId': roomId,
      'content': content,
      'type': type.toString().split('.').last,
    });
  }

  @override
  void updateAuth(Map<String, dynamic> authInfo) {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  void requestUserListRefresh() {
    _socket.emit('get_users');
  }

  @override
  void requestRoomListRefresh() {
    _socket.emit('get_rooms');
  }

  @override
  void markMessageAsRead(String messageId) {
    _socket.emit('mark_read', {'messageId': messageId});
  }

  @override
  bool isConnected() {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  IO.Socket getSocket() {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  String getCurrentUserId() {
    // Implementation needed
    throw UnimplementedError();
  }

  /// 关闭流
  void dispose() {
    _messageStreamController.close();
    _userStatusStreamController.close();
  }
}
