import 'package:dartz/dartz.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/user.dart';
import '../../core/failure.dart';
import '../../core/exceptions.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../datasources/chat_remote_datasource.dart';
import '../datasources/chat_local_datasource.dart';
import '../datasources/chat_socket_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDatasource;
  final ChatLocalDataSource localDatasource;
  final ChatSocketDataSource socketDatasource;

  ChatRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
    required this.socketDatasource,
  });

  @override
  Future<Either<Failure, bool>> connect() async {
    try {
      // 直接使用socketDatasource建立实时连接
      final connected = await socketDatasource.connect();
      return Right(connected);
    } on ServerException {
      return Left(const Failure.server());
    } on ConnectionException {
      return Left(const Failure.connection());
    }
  }

  @override
  Future<Either<Failure, bool>> disconnect() async {
    try {
      // 直接使用socketDatasource断开连接
      final disconnected = await socketDatasource.disconnect();
      return Right(disconnected);
    } on ServerException {
      return Left(const Failure.server());
    }
  }

  @override
  Future<Either<Failure, List<ChatRoom>>> getChatRooms() async {
    try {
      // 先尝试从本地获取聊天室列表
      final localRooms = await localDatasource.getChatRooms();

      // 再尝试从远程获取最新列表
      try {
        final remoteResult = await remoteDatasource.getChatRooms();

        return remoteResult.fold(
          (failure) {
            // 远程获取失败时打印错误并使用本地数据
            print('远程获取聊天室失败: ${failure.message}');
            return Right(localRooms);
          },
          (remoteRooms) async {
            // 远程获取成功，保存到本地缓存
            await localDatasource.saveChatRooms(remoteRooms);
            print('成功获取并缓存 ${remoteRooms.length} 个聊天室');
            return Right(remoteRooms);
          },
        );
      } catch (e) {
        // 记录远程获取异常
        print('远程获取聊天室异常: $e');
        return Right(localRooms);
      }
    } on CacheException catch (e) {
      print('本地缓存访问失败: $e');
      // 本地缓存访问失败时，尝试从远程获取
      try {
        final remoteResult = await remoteDatasource.getChatRooms();

        // 如果远程获取成功但无法缓存，仍然返回远程数据
        return remoteResult.fold(
          (failure) => Left(const Failure.cache()),
          (remoteRooms) {
            // 尝试缓存但不等待结果
            localDatasource.saveChatRooms(remoteRooms).catchError((e) {
              print('缓存聊天室失败: $e');
            });
            return Right(remoteRooms);
          },
        );
      } catch (e) {
        print('远程数据获取失败: $e');
        return Left(const Failure.cache());
      }
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(String chatRoomId) async {
    try {
      // 先从本地获取消息
      final localMessages = await localDatasource.getMessages(chatRoomId);

      // 通过Socket加入房间以接收实时消息 (不论是否成功获取远程数据)
      socketDatasource.joinRoom(chatRoomId);

      // 再尝试从远程获取最新消息
      try {
        final remoteResult = await remoteDatasource.getMessages(chatRoomId);

        return remoteResult.fold(
          (failure) {
            // 远程获取失败时打印错误并使用本地数据
            print('远程获取消息失败: ${failure.message}');
            return Right(localMessages);
          },
          (remoteMessages) async {
            final domainMessages =
                remoteMessages.map((m) => m.toMessage()).toList();

            // 保存到本地
            await localDatasource.saveMessages(chatRoomId, domainMessages);
            print('成功获取并缓存 ${domainMessages.length} 条消息');

            return Right(domainMessages);
          },
        );
      } catch (e) {
        // 记录远程获取异常
        print('远程获取消息异常: $e');
        return Right(localMessages);
      }
    } on CacheException catch (e) {
      print('本地缓存访问失败: $e');

      // 通过Socket加入房间以接收实时消息 (即使缓存失败)
      socketDatasource.joinRoom(chatRoomId);

      // 本地缓存访问失败时，尝试从远程获取
      try {
        final remoteResult = await remoteDatasource.getMessages(chatRoomId);

        return remoteResult.fold(
          (failure) => Left(const Failure.cache()),
          (remoteMessages) {
            final domainMessages =
                remoteMessages.map((m) => m.toMessage()).toList();

            // 尝试缓存但不等待结果
            localDatasource
                .saveMessages(chatRoomId, domainMessages)
                .catchError((e) {
              print('缓存消息失败: $e');
            });

            return Right(domainMessages);
          },
        );
      } catch (e) {
        print('远程消息获取失败: $e');
        return Left(const Failure.server());
      }
    } catch (e) {
      print('获取消息时发生未知错误: $e');
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
      // 首先通过HTTP API发送消息
      final messageResult = await remoteDatasource.sendMessage(
        chatRoomId,
        content,
        type,
        senderId,
      );

      return messageResult.fold(
        (remoteFailure) => Left(Failure.server(remoteFailure.message)),
        (messageModel) async {
          final message = messageModel.toMessage();

          // 保存到本地
          await localDatasource.saveMessage(chatRoomId, message);

          // 同时通过Socket发送实时通知
          socketDatasource.sendMessage(
            chatRoomId,
            content,
            type,
          );

          return Right(message);
        },
      );
    } on ServerException {
      // HTTP API失败时使用Socket作为后备
      try {
        socketDatasource.sendMessage(
          chatRoomId,
          content,
          type,
        );

        // 创建临时消息，标记为发送中
        final tempMessage = Message(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          content: content,
          type: type,
          senderId: senderId,
          timestamp: DateTime.now(),
          receiverId: '',
        );

        // 保存到本地
        await localDatasource.saveMessage(chatRoomId, tempMessage);

        return Right(tempMessage);
      } catch (e) {
        return Left(const Failure.server());
      }
    }
  }

  @override
  Future<Either<Failure, bool>> markAsRead(String messageId) async {
    try {
      // 实现将消息标记为已读的逻辑
      // 可能需要调用远程API和更新本地缓存
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
      // 尝试通过HTTP API获取在线用户列表
      final userResult = await remoteDatasource.getUsers();

      return userResult.fold(
        (remoteFailure) => Left(Failure.server(remoteFailure.message)),
        (userModels) {
          final users = userModels.map((model) => model.toUser()).toList();
          return Right(users.where((user) => user.isOnline == true).toList());
        },
      );
    } on ServerException {
      return Left(const Failure.server());
    } catch (e) {
      return Left(const Failure.server());
    }
  }

  @override
  Stream<Message> get messageStream => socketDatasource.messageStream
      .map((messageModel) => messageModel.toMessage());

  @override
  Stream<User> get userStatusStream =>
      socketDatasource.userStatusStream.map((userModel) => userModel.toUser());
}
