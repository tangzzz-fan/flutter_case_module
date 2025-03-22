import 'package:dartz/dartz.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/user.dart';
import '../datasources/chat_socket_datasource.dart';
import '../datasources/chat_local_datasource.dart';
import '../../core/failure.dart';
import '../../core/exceptions.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatSocketDatasource remoteDatasource;
  final ChatLocalDatasource localDatasource;

  ChatRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, bool>> connect() async {
    try {
      final result = await remoteDatasource.connect();
      return Right(result);
    } on ServerException {
      return Left(const Failure.server());
    }
  }

  @override
  Future<Either<Failure, bool>> disconnect() async {
    try {
      final result = await remoteDatasource.disconnect();
      return Right(result);
    } on ServerException {
      return Left(const Failure.server());
    }
  }

  @override
  Future<Either<Failure, List<ChatRoom>>> getChatRooms() async {
    try {
      final chatRooms = await localDatasource.getChatRooms();
      return Right(chatRooms);
    } on CacheException {
      return Left(const Failure.cache());
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(String chatRoomId) async {
    try {
      // 首先从本地获取消息
      final localMessages = await localDatasource.getMessages(chatRoomId);

      // 检查网络连接
      try {
        // 尝试连接
        await remoteDatasource.connect();

        // 然后尝试从远程获取最新消息
        try {
          final remoteMessages = await remoteDatasource.getMessages(chatRoomId);
          final domainMessages =
              remoteMessages.map((m) => m.toMessage()).toList();

          // 保存到本地
          await localDatasource.saveMessages(chatRoomId, domainMessages);

          return Right(domainMessages);
        } on ServerException {
          // 如果远程获取失败，则返回本地消息
          return Right(localMessages);
        }
      } on ConnectionException {
        // 连接失败，返回本地消息
        return Right(localMessages);
      } on ServerException {
        // 服务器错误，返回本地消息
        return Right(localMessages);
      }
    } on CacheException {
      return Left(const Failure.cache());
    } catch (e) {
      return Left(const Failure.server());
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage(
    String chatRoomId,
    String content,
    MessageType type,
    String senderId,
  ) async {
    try {
      final messageModel = await remoteDatasource.sendMessage(
        chatRoomId,
        content,
        type,
        senderId,
      );
      final message = messageModel.toMessage();

      // 保存到本地
      await localDatasource.saveMessage(chatRoomId, message);

      return Right(message);
    } on ServerException {
      return Left(const Failure.server());
    }
  }

  @override
  Future<Either<Failure, bool>> markAsRead(String messageId) async {
    try {
      // 实现将消息标记为已读的逻辑
      // 这里暂时模拟成功操作
      await Future.delayed(const Duration(milliseconds: 200));
      return const Right(true);
    } on ServerException {
      return Left(const Failure.server());
    } catch (e) {
      return Left(const Failure.server());
    }
  }

  @override
  Future<Either<Failure, List<User>>> getOnlineUsers() async {
    try {
      // 实现获取在线用户的逻辑
      // 这里暂时返回空列表
      return const Right([]);
    } on ServerException {
      return Left(const Failure.server());
    } catch (e) {
      return Left(const Failure.server());
    }
  }

  @override
  Stream<Message> get messageStream => remoteDatasource.messageStream
      .map((messageModel) => messageModel.toMessage());

  @override
  Stream<User> get userStatusStream =>
      remoteDatasource.userStatusStream.map((userModel) => userModel.toUser());
}
