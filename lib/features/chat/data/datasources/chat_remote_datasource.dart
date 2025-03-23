import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_room.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'package:dartz/dartz.dart';
import '../../core/failure.dart';

/// 远程数据源接口，用于处理获取历史数据的HTTP请求
abstract class ChatRemoteDataSource {
  /// 获取用户列表
  Future<Either<Failure, List<UserModel>>> getUsers();

  /// 获取聊天室列表
  Future<Either<Failure, List<ChatRoom>>> getChatRooms();

  /// 获取特定聊天室的消息历史
  Future<Either<Failure, List<MessageModel>>> getMessages(String chatRoomId);

  /// 发送一条新消息
  Future<Either<Failure, MessageModel>> sendMessage(
    String chatRoomId,
    String content,
    MessageType type,
    String senderId,
  );

  /// 加入聊天室
  Future<Either<Failure, bool>> joinChatRoom(String chatRoomId);

  /// 离开聊天室
  Future<Either<Failure, bool>> leaveChatRoom(String chatRoomId);

  /// 创建新聊天室
  Future<Either<Failure, ChatRoom>> createChatRoom(
    String name,
    String description,
    bool isPrivate,
  );
}

/// 基于Socket.IO的远程数据源实现
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final IO.Socket _socket;

  ChatRemoteDataSourceImpl(this._socket);

  /// 使用Socket.IO发起请求并等待响应的通用方法
  Future<Either<Failure, T>> _emitWithAck<T>(
    String event,
    dynamic data,
    T Function(dynamic) mapper,
  ) async {
    try {
      // 创建一个Completer来处理异步操作
      final completer = Completer<Either<Failure, T>>();

      // 明确定义超时函数的返回类型
      Future<Either<Failure, T>> timeoutFuture = Future.delayed(
        const Duration(seconds: 10),
        () {
          if (!completer.isCompleted) {
            completer.complete(Left(ServerFailure('请求超时')));
          }
          return Left<Failure, T>(ServerFailure('请求超时'));
        },
      );

      // 发送事件并等待响应
      _socket.emitWithAck(event, data, ack: (response) {
        if (response == null) {
          completer.complete(Left(ServerFailure('服务器未响应')));
          return;
        }

        if (response is Map && response['error'] != null) {
          completer.complete(Left(ServerFailure(response['error'])));
          return;
        }

        try {
          final result = mapper(response);
          completer.complete(Right(result));
        } catch (e) {
          completer.complete(Left(ServerFailure('数据解析错误: $e')));
        }
      });

      // 等待响应或超时 - 现在两个Future都是明确的Either<Failure, T>类型
      return await Future.any<Either<Failure, T>>([
        completer.future,
        timeoutFuture,
      ]);
    } catch (e) {
      return Left(ServerFailure('远程数据源错误: $e'));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getUsers() async {
    return _emitWithAck('get_users', {}, (response) {
      if (response is List) {
        return response.map((data) => UserModel.fromJson(data)).toList();
      }
      throw FormatException('预期响应为列表，但收到: $response');
    });
  }

  @override
  Future<Either<Failure, List<ChatRoom>>> getChatRooms() async {
    return _emitWithAck('get_rooms', {}, (response) {
      if (response is List) {
        return response.map((data) => ChatRoom.fromJson(data)).toList();
      }
      throw FormatException('预期响应为列表，但收到: $response');
    });
  }

  @override
  Future<Either<Failure, List<MessageModel>>> getMessages(
      String chatRoomId) async {
    return _emitWithAck('get_messages', {'roomId': chatRoomId}, (response) {
      if (response is List) {
        return response.map((data) => MessageModel.fromJson(data)).toList();
      }
      throw FormatException('预期响应为列表，但收到: $response');
    });
  }

  @override
  Future<Either<Failure, MessageModel>> sendMessage(
    String chatRoomId,
    String content,
    MessageType type,
    String senderId,
  ) async {
    return _emitWithAck('send_message', {
      'roomId': chatRoomId,
      'content': content,
      'type': type.toString().split('.').last,
      'senderId': senderId,
    }, (response) {
      return MessageModel.fromJson(response);
    });
  }

  @override
  Future<Either<Failure, bool>> joinChatRoom(String chatRoomId) async {
    return _emitWithAck('join_room', {'roomId': chatRoomId}, (response) {
      return response['success'] == true;
    });
  }

  @override
  Future<Either<Failure, bool>> leaveChatRoom(String chatRoomId) async {
    return _emitWithAck('leave_room', {'roomId': chatRoomId}, (response) {
      return response['success'] == true;
    });
  }

  @override
  Future<Either<Failure, ChatRoom>> createChatRoom(
    String name,
    String description,
    bool isPrivate,
  ) async {
    return _emitWithAck('create_room', {
      'name': name,
      'description': description,
      'isPrivate': isPrivate,
    }, (response) {
      return ChatRoom.fromJson(response);
    });
  }
}
