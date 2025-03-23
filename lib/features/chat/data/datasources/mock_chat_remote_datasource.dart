import 'dart:async';
import 'dart:math';
import 'package:dartz/dartz.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/user.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../../core/failure.dart';
import 'chat_remote_datasource.dart';

/// 模拟远程数据源实现，用于测试和开发
class MockChatRemoteDataSource implements ChatRemoteDataSource {
  // 模拟用户列表
  final List<UserModel> _mockUsers = List.generate(
    10,
    (index) => UserModel(
      id: 'user_$index',
      username: 'User $index',
      avatar: index % 3 == 0
          ? 'https://randomuser.me/api/portraits/men/$index.jpg'
          : null,
      socketId: 'socket_$index',
      connected: index % 2 == 0,
      lastActive: DateTime.now().subtract(Duration(minutes: index * 10)),
    ),
  );

  // 模拟聊天室列表
  final List<ChatRoom> _mockRooms = List.generate(
    5,
    (index) => ChatRoom(
      id: 'room_$index',
      name: 'Room $index',
      members: List.generate(
        3 + index,
        (userIndex) => User(
          id: 'user_$userIndex',
          name: 'User $userIndex',
          avatar: userIndex % 3 == 0
              ? 'https://randomuser.me/api/portraits/men/$userIndex.jpg'
              : null,
          isOnline: userIndex % 2 == 0,
        ),
      ),
      description: 'This is room description $index',
      createdAt: DateTime.now().subtract(Duration(days: index)),
      isPrivate: index % 2 == 0,
      lastMessage: index > 0
          ? Message(
              id: 'last_msg_$index',
              content: '这是最后一条消息 $index',
              type: MessageType.text,
              senderId: 'user_${index % 5}',
              timestamp: DateTime.now().subtract(Duration(minutes: index * 30)),
              receiverId: 'user_${(index + 1) % 5}',
            )
          : null,
      unreadCount: index,
      isGroup: index > 2,
      creatorId: 'user_0',
    ),
  );

  // 模拟消息映射表 (roomId -> messages)
  final Map<String, List<MessageModel>> _mockMessages = {};

  MockChatRemoteDataSource() {
    // 为每个聊天室生成一些模拟消息
    for (final room in _mockRooms) {
      _generateMockMessages(room.id);
    }
  }

  // 生成模拟网络延迟
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(Duration(milliseconds: 300 + Random().nextInt(700)));
  }

  // 为特定聊天室生成模拟消息
  void _generateMockMessages(String roomId) {
    final List<MessageModel> messages = [];
    final int messageCount = 10 + Random().nextInt(20); // 10-30条消息

    for (int i = 0; i < messageCount; i++) {
      final int senderIndex = Random().nextInt(5); // 随机选择一个发送者
      final DateTime timestamp = DateTime.now().subtract(
        Duration(
          hours: i * 2,
          minutes: Random().nextInt(60),
        ),
      );

      String content;
      MessageType messageType;

      // 随机生成不同类型的消息
      final messageTypeRandom = Random().nextInt(10);
      if (messageTypeRandom < 7) {
        // 70% 是文本消息
        messageType = MessageType.text;
        content = '这是消息 $i 在聊天室 $roomId';
      } else if (messageTypeRandom < 9) {
        // 20% 是图片消息
        messageType = MessageType.image;
        content = 'https://picsum.photos/800/600?random=$i';
      } else {
        // 10% 是文件消息
        messageType = MessageType.file;
        content = 'https://example.com/files/document_$i.pdf';
      }

      messages.add(MessageModel(
        id: 'msg_${roomId}_$i',
        content: content,
        fromUserId: 'user_$senderIndex', // 使用 fromUserId 参数
        timestamp: timestamp,
      ));
    }

    // 按时间排序
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _mockMessages[roomId] = messages;
  }

  @override
  Future<Either<Failure, List<UserModel>>> getUsers() async {
    await _simulateNetworkDelay();

    // 随机模拟失败的情况 (10%概率)
    if (Random().nextInt(10) == 0) {
      return Left(ServerFailure('模拟的网络错误'));
    }

    return Right(_mockUsers);
  }

  @override
  Future<Either<Failure, List<ChatRoom>>> getChatRooms() async {
    await _simulateNetworkDelay();

    // 随机模拟失败的情况 (10%概率)
    if (Random().nextInt(10) == 0) {
      return Left(ServerFailure('模拟的网络错误'));
    }

    return Right(_mockRooms);
  }

  @override
  Future<Either<Failure, List<MessageModel>>> getMessages(
      String chatRoomId) async {
    await _simulateNetworkDelay();

    // 如果没有找到该聊天室的消息，那么生成一些
    if (!_mockMessages.containsKey(chatRoomId)) {
      _generateMockMessages(chatRoomId);
    }

    // 随机模拟失败的情况 (10%概率)
    if (Random().nextInt(10) == 0) {
      return Left(ServerFailure('模拟的网络错误'));
    }

    return Right(_mockMessages[chatRoomId] ?? []);
  }

  @override
  Future<Either<Failure, MessageModel>> sendMessage(
    String chatRoomId,
    String content,
    MessageType type,
    String fromUserId,
  ) async {
    await _simulateNetworkDelay();

    // 随机模拟失败的情况 (10%概率)
    if (Random().nextInt(10) == 0) {
      return Left(ServerFailure('模拟的网络错误'));
    }

    // 创建新消息，确保使用 fromUserId 参数
    final newMessage = MessageModel(
      id: 'new_msg_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      fromUserId: fromUserId,
      timestamp: DateTime.now(),
    );

    // 添加到消息列表
    if (!_mockMessages.containsKey(chatRoomId)) {
      _mockMessages[chatRoomId] = [];
    }
    _mockMessages[chatRoomId]!.add(newMessage);

    // 更新聊天室的最后一条消息
    final roomIndex = _mockRooms.indexWhere((room) => room.id == chatRoomId);
    if (roomIndex >= 0) {
      _mockRooms[roomIndex] = _mockRooms[roomIndex].copyWith(
        lastMessage: newMessage.toMessage(),
        unreadCount: (_mockRooms[roomIndex].unreadCount ?? 0) + 1,
      );
    }

    return Right(newMessage);
  }

  @override
  Future<Either<Failure, bool>> joinChatRoom(String chatRoomId) async {
    await _simulateNetworkDelay();

    // 随机模拟失败的情况 (10%概率)
    if (Random().nextInt(10) == 0) {
      return Left(ServerFailure('模拟的网络错误'));
    }

    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> leaveChatRoom(String chatRoomId) async {
    await _simulateNetworkDelay();

    // 随机模拟失败的情况 (10%概率)
    if (Random().nextInt(10) == 0) {
      return Left(ServerFailure('模拟的网络错误'));
    }

    return const Right(true);
  }

  @override
  Future<Either<Failure, ChatRoom>> createChatRoom(
    String name,
    String description,
    bool isPrivate,
  ) async {
    await _simulateNetworkDelay();

    // 随机模拟失败的情况 (10%概率)
    if (Random().nextInt(10) == 0) {
      return Left(ServerFailure('模拟的网络错误'));
    }

    // 创建新的聊天室
    final newRoom = ChatRoom(
      id: 'room_new_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      members: _mockUsers.take(3).map((u) => u.toUser()).toList(),
      description: description,
      createdAt: DateTime.now(),
      isPrivate: isPrivate,
      isGroup: true,
      creatorId: 'user_0',
    );

    // 添加到聊天室列表
    _mockRooms.add(newRoom);

    // 创建空的消息列表
    _mockMessages[newRoom.id] = [];

    return Right(newRoom);
  }

  // 模拟的消息流
  @override
  Stream<MessageModel> get messageStream {
    // 这个流在实际实现中应该连接到Socket服务器的消息事件
    return Stream<MessageModel>.empty();
  }

  // 模拟的用户状态流
  @override
  Stream<UserModel> get userStatusStream {
    // 这个流在实际实现中应该连接到Socket服务器的用户状态事件
    return Stream<UserModel>.empty();
  }
}
