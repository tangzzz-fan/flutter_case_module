import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_room.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'package:dartz/dartz.dart';
import '../../core/failure.dart';
import 'chat_remote_datasource.dart'; // 确保正确导入接口

/// 基于HTTP的远程数据源实现
class ChatRemoteHttpDataSourceImpl implements ChatRemoteDataSource {
  final String baseUrl;
  final http.Client httpClient;
  final Map<String, String> Function() getHeaders;

  ChatRemoteHttpDataSourceImpl({
    required this.baseUrl,
    required this.httpClient,
    required this.getHeaders,
  });

  /// 通用HTTP GET请求方法
  Future<Either<Failure, T>> _get<T>(
    String endpoint,
    T Function(dynamic) mapper,
  ) async {
    try {
      final response = await httpClient
          .get(
            Uri.parse('$baseUrl/$endpoint'),
            headers: getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Right(mapper(jsonData));
      } else {
        return Left(Failure.server('服务器返回错误: ${response.statusCode}'));
      }
    } on TimeoutException {
      return Left(Failure.connection('请求超时'));
    } catch (e) {
      return Left(Failure.server('HTTP请求错误: $e'));
    }
  }

  /// 通用HTTP POST请求方法
  Future<Either<Failure, T>> _post<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(dynamic) mapper,
  ) async {
    try {
      final response = await httpClient
          .post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: getHeaders(),
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return Right(mapper(jsonData));
      } else {
        return Left(Failure.server('服务器返回错误: ${response.statusCode}'));
      }
    } on TimeoutException {
      return Left(Failure.connection('请求超时'));
    } catch (e) {
      return Left(Failure.server('HTTP请求错误: $e'));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getUsers() {
    return _get('users', (data) {
      if (data is List) {
        return data.map((item) => UserModel.fromJson(item)).toList();
      }
      return <UserModel>[];
    });
  }

  @override
  Future<Either<Failure, List<ChatRoom>>> getChatRooms() {
    return _get('rooms', (data) {
      if (data is List) {
        return data.map((item) => ChatRoom.fromJson(item)).toList();
      }
      return <ChatRoom>[];
    });
  }

  @override
  Future<Either<Failure, List<MessageModel>>> getMessages(String chatRoomId) {
    return _get('rooms/$chatRoomId/messages', (data) {
      if (data is List) {
        return data.map((item) => MessageModel.fromJson(item)).toList();
      }
      return <MessageModel>[];
    });
  }

  @override
  Future<Either<Failure, MessageModel>> sendMessage(
    String chatRoomId,
    String content,
    MessageType type,
    String senderId,
  ) {
    return _post(
      'rooms/$chatRoomId/messages',
      {
        'content': content,
        'type': type.toString().split('.').last,
        'senderId': senderId,
      },
      (data) => MessageModel.fromJson(data),
    );
  }

  @override
  Future<Either<Failure, bool>> joinChatRoom(String chatRoomId) {
    return _post(
      'rooms/$chatRoomId/join',
      {},
      (data) => true,
    );
  }

  @override
  Future<Either<Failure, bool>> leaveChatRoom(String chatRoomId) {
    return _post(
      'rooms/$chatRoomId/leave',
      {},
      (data) => true,
    );
  }

  @override
  Future<Either<Failure, ChatRoom>> createChatRoom(
    String name,
    String description,
    bool isPrivate,
  ) {
    return _post(
      'rooms',
      {
        'name': name,
        'description': description,
        'isPrivate': isPrivate,
      },
      (data) => ChatRoom.fromJson(data),
    );
  }

  // 这些方法不应该在HTTP版本中实现，它们应该是Socket版本的职责
  @override
  Future<Either<Failure, bool>> connect() async {
    // 由于HTTP不维护连接，这个方法没有实际意义
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> disconnect() async {
    // 由于HTTP不维护连接，这个方法没有实际意义
    return const Right(true);
  }

  // 这些流在HTTP版本中不可用
  @override
  Stream<MessageModel> get messageStream => Stream.empty();

  @override
  Stream<UserModel> get userStatusStream => Stream.empty();
}
