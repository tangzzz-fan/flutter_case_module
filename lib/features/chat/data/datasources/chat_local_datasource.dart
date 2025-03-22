import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/user.dart';
import '../models/message_model.dart';
import '../models/chat_room_model.dart';
import '../models/user_model.dart';
import '../../core/exceptions.dart';

abstract class ChatLocalDatasource {
  /// 获取本地保存的聊天室列表
  Future<List<ChatRoom>> getChatRooms();

  /// 获取特定聊天室的消息记录
  Future<List<Message>> getMessages(String chatRoomId);

  /// 保存消息列表到本地
  Future<void> saveMessages(String chatRoomId, List<Message> messages);

  /// 保存单条消息到本地
  Future<void> saveMessage(String chatRoomId, Message message);

  /// 保存聊天室列表到本地
  Future<void> saveChatRooms(List<ChatRoom> chatRooms);
}

class ChatLocalDatasourceImpl implements ChatLocalDatasource {
  @override
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      // 这里应该从SQLite或其他本地存储获取聊天室列表
      // 暂时返回模拟数据
      final chatRoomModels = await Future.delayed(
        const Duration(milliseconds: 500),
        () => [
          ChatRoomModel(
            id: '1',
            name: '张三',
            participants: [
              UserModel(
                id: '1',
                username: '张三',
                avatar: 'https://randomuser.me/api/portraits/men/1.jpg',
                isOnline: true,
              ).toUser(),
            ],
            unreadCount: 2,
          ),
          ChatRoomModel(
            id: '2',
            name: '李四',
            participants: [
              UserModel(
                id: '2',
                username: '李四',
                avatar: 'https://randomuser.me/api/portraits/women/2.jpg',
              ).toUser(),
            ],
          ),
          ChatRoomModel(
            id: '3',
            name: '项目组',
            participants: [
              UserModel(id: '3', username: '王五', avatar: '').toUser(),
              UserModel(id: '4', username: '赵六', avatar: '').toUser(),
              UserModel(id: '5', username: '孙七', avatar: '').toUser(),
            ],
            isGroup: true,
            unreadCount: 5,
          ),
        ],
      );

      // 将模型转换为领域实体
      return chatRoomModels.map((model) => model.toChatRoom()).toList();
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<List<Message>> getMessages(String chatRoomId) async {
    try {
      // 从本地存储读取消息历史
      // 暂时返回模拟数据
      final now = DateTime.now();
      final messageModels = await Future.delayed(
        const Duration(milliseconds: 500),
        () => [
          MessageModel(
            id: '1',
            fromUserId: chatRoomId,
            toUserId: 'me',
            content:
                '你好，我是${chatRoomId == '1' ? '张三' : chatRoomId == '2' ? '李四' : '项目组'}',
            timestamp: now.subtract(const Duration(minutes: 5)),
          ),
          MessageModel(
            id: '2',
            fromUserId: 'me',
            toUserId: chatRoomId,
            content: '你好，很高兴认识你',
            timestamp: now.subtract(const Duration(minutes: 4)),
          ),
          if (chatRoomId == '1')
            MessageModel(
              id: '3',
              fromUserId: chatRoomId,
              toUserId: 'me',
              content: '我们明天见面讨论项目进展吧',
              timestamp: now.subtract(const Duration(minutes: 3)),
            ),
          if (chatRoomId == '1')
            MessageModel(
              id: '4',
              fromUserId: 'me',
              toUserId: chatRoomId,
              content: '好的，下午两点公司会议室',
              timestamp: now.subtract(const Duration(minutes: 2)),
            ),
        ],
      );

      // 将模型转换为领域实体
      return messageModels.map((model) => model.toMessage()).toList();
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> saveMessages(String chatRoomId, List<Message> messages) async {
    // 实现保存消息列表的逻辑
    // 此处应该使用SQLite或其他本地存储技术
    return Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> saveMessage(String chatRoomId, Message message) async {
    // 实现保存单条消息的逻辑
    return Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> saveChatRooms(List<ChatRoom> chatRooms) async {
    // 实现保存聊天室列表的逻辑
    return Future.delayed(const Duration(milliseconds: 200));
  }
}
