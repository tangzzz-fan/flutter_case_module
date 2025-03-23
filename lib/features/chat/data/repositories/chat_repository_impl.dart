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

// 添加消息状态枚举
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

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

  @override
  Future<Either<Failure, Message>> sendPrivateMessage({
    required String recipientId,
    required String content,
    int? timestamp,
  }) async {
    try {
      // 检查连接状态 - 修复 isConnected 属性
      if (!socketDatasource.isConnected()) {
        // 修改为方法调用
        return Left(const Failure.connection('未连接到聊天服务器'));
      }

      // 创建消息数据
      final messageData = {
        'recipientId': recipientId,
        'content': content,
        'timestamp': timestamp ?? DateTime.now().millisecondsSinceEpoch,
      };

      // 通过Socket发送私聊消息 - 修复 socket 属性
      socketDatasource
          .getSocket()
          .emit('message_private', messageData); // 修改为方法调用

      // 创建一个临时消息对象 - 修复 MessageModel 构造函数参数
      final tempMessageModel = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        fromUserId: socketDatasource.getCurrentUserId(), // 修改为方法调用
        toUserId: recipientId, // 使用正确的参数名
        timestamp: DateTime.now(),
        messageType: MessageType.text, // 使用正确的参数名
        messageStatus: MessageStatus.sending, // 使用正确的状态枚举
      );

      // 保存到本地缓存
      final tempMessage = tempMessageModel.toMessage();
      try {
        await localDatasource.saveMessage('private_$recipientId', tempMessage);
      } catch (e) {
        print('缓存私聊消息失败: $e');
      }

      return Right(tempMessage);
    } on ServerException catch (e) {
      return Left(Failure.server(e.message));
    } catch (e) {
      return Left(Failure.server(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendRoomMessage({
    required String roomId,
    required String content,
    int? timestamp,
  }) async {
    try {
      if (!socketDatasource.isConnected()) {
        // 修改为方法调用
        return Left(const Failure.connection('未连接到聊天服务器'));
      }

      // 创建消息数据
      final messageData = {
        'roomId': roomId,
        'content': content,
        'timestamp': timestamp ?? DateTime.now().millisecondsSinceEpoch,
      };

      // 通过Socket发送房间消息
      socketDatasource.getSocket().emit('message_room', messageData); // 修改为方法调用

      // 创建一个临时消息对象 - 修复 MessageModel 构造函数参数
      final tempMessageModel = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        fromUserId: socketDatasource.getCurrentUserId(), // 修改为方法调用
        toRoomId: roomId, // 使用正确的参数名
        timestamp: DateTime.now(),
        messageType: MessageType.text, // 使用正确的参数名
        messageStatus: MessageStatus.sending, // 使用正确的状态枚举
      );

      // 保存到本地缓存
      final tempMessage = tempMessageModel.toMessage();
      try {
        await localDatasource.saveMessage(roomId, tempMessage);
      } catch (e) {
        print('缓存房间消息失败: $e');
      }

      return Right(tempMessage);
    } on ServerException catch (e) {
      return Left(Failure.server(e.message));
    } catch (e) {
      return Left(Failure.server(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> markMessageAsRead(String messageId) async {
    try {
      if (!socketDatasource.isConnected()) {
        // 修改为方法调用
        return Left(const Failure.connection('未连接到聊天服务器'));
      }

      // 直接发送消息ID作为参数
      socketDatasource.getSocket().emit('message_read', messageId); // 修改为方法调用

      // 更新本地消息状态
      try {
        // 此处应该有逻辑来更新本地缓存中的消息状态
        // 但需要知道消息所在的聊天室ID才能精确更新
        // 目前简化处理，假设成功
      } catch (e) {
        print('更新本地消息已读状态失败: $e');
      }

      return const Right(true);
    } on ServerException catch (e) {
      return Left(Failure.server(e.message));
    } catch (e) {
      return Left(Failure.server(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> joinRoom(String roomId) async {
    try {
      if (!socketDatasource.isConnected()) {
        // 修改为方法调用
        return Left(const Failure.connection('未连接到聊天服务器'));
      }

      // 发送加入房间事件
      socketDatasource
          .getSocket()
          .emit('room_joined', {'roomId': roomId}); // 修改为方法调用

      // 记录用户已加入的房间
      try {
        // 这里可以添加逻辑来记录用户已加入的房间
        // 例如保存到本地存储或更新状态
      } catch (e) {
        print('记录用户加入房间信息失败: $e');
      }

      return const Right(true);
    } on ServerException catch (e) {
      return Left(Failure.server(e.message));
    } catch (e) {
      return Left(Failure.server(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> leaveRoom(String roomId) async {
    try {
      if (!socketDatasource.isConnected()) {
        // 修改为方法调用
        return Left(const Failure.connection('未连接到聊天服务器'));
      }

      // 发送离开房间事件
      socketDatasource
          .getSocket()
          .emit('room_left', {'roomId': roomId}); // 修改为方法调用

      // 更新本地记录
      try {
        // 这里可以添加逻辑来更新用户已离开的房间记录
        // 例如从本地存储中移除或更新状态
      } catch (e) {
        print('更新用户离开房间信息失败: $e');
      }

      return const Right(true);
    } on ServerException catch (e) {
      return Left(Failure.server(e.message));
    } catch (e) {
      return Left(Failure.server(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatRoom>> createRoom({
    required String roomName,
    bool isPrivate = false,
    List<String>? members,
  }) async {
    try {
      if (!socketDatasource.isConnected()) {
        // 修改为方法调用
        return Left(const Failure.connection('未连接到聊天服务器'));
      }

      // 创建房间数据
      final roomData = {
        'roomName': roomName,
        'isPrivate': isPrivate,
        if (members != null && members.isNotEmpty) 'members': members,
      };

      // 发送创建房间事件
      socketDatasource.getSocket().emit('room_created', roomData); // 修改为方法调用

      // 创建一个临时房间对象 - 修复 ChatRoom 构造函数参数
      final tempRoom = ChatRoom(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: roomName,
        isPrivate: isPrivate,
        description: '新建聊天室', // 添加必需的描述参数
        creatorId: socketDatasource.getCurrentUserId(), // 修改为方法调用
        members: members != null
            ? members
                .map((id) => User(id: id, name: '', isOnline: false))
                .toList()
            : [
                User(
                    id: socketDatasource.getCurrentUserId(),
                    name: '',
                    isOnline: true)
              ],
        createdAt: DateTime.now(),
      );

      // 添加到本地缓存
      try {
        final existingRooms = await localDatasource.getChatRooms();
        await localDatasource.saveChatRooms([...existingRooms, tempRoom]);
      } catch (e) {
        print('缓存新建房间失败: $e');
      }

      return Right(tempRoom);
    } on ServerException catch (e) {
      return Left(Failure.server(e.message));
    } catch (e) {
      return Left(Failure.server(e.toString()));
    }
  }

  @override
  Future<ChatRoom> createChatRoom({
    required String name,
    required List<String> participants,
    required bool isGroup,
    String? description,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 尝试使用HTTP API创建聊天室
      final result = await remoteDatasource.createChatRoom(
        name,
        description ?? '新建聊天室',
        false,
      );

      // 从Either中提取ChatRoom对象
      final chatRoom = result.fold(
        (failure) => throw ServerException(failure.message),
        (chatRoom) => chatRoom, // 这里不再调用toChatRoom()方法
      );

      // 保存到本地缓存
      try {
        final existingRooms = await localDatasource.getChatRooms();
        await localDatasource.saveChatRooms([...existingRooms, chatRoom]);
      } catch (e) {
        print('缓存新建聊天室失败: $e');
      }

      return chatRoom;
    } on ServerException catch (e) {
      // 使用Socket作为备选
      final eitherResult = await createRoom(
        roomName: name,
        isPrivate: !isGroup,
        members: participants,
      );

      return eitherResult.fold(
        (failure) => throw ChatException(failure.message ?? ''),
        (chatRoom) => chatRoom,
      );
    } catch (e) {
      throw ChatException(e.toString());
    }
  }
}

// 添加缺少的异常类
class ChatException implements Exception {
  final String message;

  ChatException(this.message);

  @override
  String toString() => 'ChatException: $message';
}
