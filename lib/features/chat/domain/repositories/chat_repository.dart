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
      String chatRoomId, String content, MessageType type);

  /// 标记消息为已读
  Future<Either<Failure, bool>> markAsRead(String messageId);

  /// 获取在线用户
  Future<Either<Failure, List<User>>> getOnlineUsers();

  /// 监听新消息
  Stream<Message> get messageStream;

  /// 监听用户状态变化
  Stream<User> get userStatusStream;
}
