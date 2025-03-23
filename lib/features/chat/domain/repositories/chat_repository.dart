import 'package:dartz/dartz.dart';
import '../entities/message.dart';
import '../entities/chat_room.dart';
import '../entities/user.dart';
import '../../core/failure.dart';

abstract class ChatRepository {
  /// 连接到聊天服务器
  Future<Either<Failure, bool>> connect();

  /// 断开与聊天服务器的连接
  Future<Either<Failure, bool>> disconnect();

  /// 获取聊天室列表
  Future<Either<Failure, List<ChatRoom>>> getChatRooms();

  /// 获取指定聊天室的消息历史
  Future<Either<Failure, List<Message>>> getMessages(String chatRoomId);

  /// 发送消息
  Future<Either<Failure, Message>> sendMessage(
      String chatRoomId, String content, MessageType type, String senderId);

  /// 标记消息为已读
  Future<Either<Failure, bool>> markAsRead(String messageId);

  /// 获取在线用户
  Future<Either<Failure, List<User>>> getOnlineUsers();

  /// 监听新消息
  Stream<Message> get messageStream;

  /// 监听用户状态变化
  Stream<User> get userStatusStream;

  /// 发送私聊消息
  Future<Either<Failure, Message>> sendPrivateMessage({
    required String recipientId,
    required String content,
    int? timestamp,
  });

  /// 发送房间消息
  Future<Either<Failure, Message>> sendRoomMessage({
    required String roomId,
    required String content,
    int? timestamp,
  });

  /// 标记消息已读
  Future<Either<Failure, bool>> markMessageAsRead(String messageId);

  /// 加入房间
  Future<Either<Failure, bool>> joinRoom(String roomId);

  /// 离开房间
  Future<Either<Failure, bool>> leaveRoom(String roomId);

  /// 创建房间
  Future<Either<Failure, ChatRoom>> createRoom({
    required String roomName,
    bool isPrivate = false,
    List<String>? members,
  });

  /// 与现有方法整合的创建聊天室方法
  Future<ChatRoom> createChatRoom({
    required String name,
    required List<String> participants,
    required bool isGroup,
    String? description,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  });
}
