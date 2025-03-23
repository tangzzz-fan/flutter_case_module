import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/user.dart';
import '../models/message_model.dart';
import '../models/chat_room_model.dart';
import '../models/user_model.dart';
import '../../core/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

abstract class ChatLocalDataSource {
  Future<void> cacheUsers(List<UserModel> users);
  Future<List<UserModel>> getCachedUsers();

  Future<void> cacheMessages(String chatRoomId, List<MessageModel> messages);
  Future<List<MessageModel>> getCachedMessages(String chatRoomId);

  Future<void> cacheChatRooms(List<ChatRoom> chatRooms);
  Future<List<ChatRoom>> getCachedChatRooms();

  Future<void> cacheCurrentUser(UserModel user);
  Future<UserModel?> getCachedCurrentUser();

  Future<void> clearCache();

  /// 获取本地缓存的聊天室列表
  Future<List<ChatRoom>> getChatRooms();

  /// 保存聊天室列表到本地
  Future<void> saveChatRooms(List<ChatRoom> rooms);

  /// 获取特定聊天室的消息列表
  Future<List<Message>> getMessages(String chatRoomId);

  /// 保存消息列表到本地
  Future<void> saveMessages(String chatRoomId, List<Message> messages);

  /// 保存单条消息到本地
  Future<void> saveMessage(String chatRoomId, Message message);

  /// 获取最后一次同步时间
  Future<DateTime?> getLastSyncTime();

  /// 保存同步时间
  Future<void> saveLastSyncTime(DateTime time);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final SharedPreferences _prefs;
  static const String _USERS_KEY = 'cached_users';
  static const String _MESSAGES_PREFIX = 'cached_messages_';
  static const String _CHATROOMS_KEY = 'cached_chatrooms';
  static const String _CURRENT_USER_KEY = 'current_user';
  static const String _chatRoomsKey = 'chat_rooms';
  static const String _messagesKeyPrefix = 'messages_';
  static const String _lastSyncKey = 'last_sync_time';

  ChatLocalDataSourceImpl(this._prefs);

  @override
  Future<void> cacheUsers(List<UserModel> users) async {
    final jsonString = json.encode(users.map((user) => user.toJson()).toList());
    await _prefs.setString(_USERS_KEY, jsonString);
  }

  @override
  Future<List<UserModel>> getCachedUsers() async {
    final jsonString = _prefs.getString(_USERS_KEY);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => UserModel.fromJson(item)).toList();
    } catch (e) {
      print('解析缓存用户出错: $e');
      return [];
    }
  }

  @override
  Future<void> cacheMessages(
      String chatRoomId, List<MessageModel> messages) async {
    final jsonString =
        json.encode(messages.map((msg) => msg.toJson()).toList());
    await _prefs.setString('${_MESSAGES_PREFIX}$chatRoomId', jsonString);
  }

  @override
  Future<List<MessageModel>> getCachedMessages(String chatRoomId) async {
    final jsonString = _prefs.getString('${_MESSAGES_PREFIX}$chatRoomId');
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => MessageModel.fromJson(item)).toList();
    } catch (e) {
      print('解析缓存消息出错: $e');
      return [];
    }
  }

  @override
  Future<void> cacheChatRooms(List<ChatRoom> chatRooms) async {
    final jsonString =
        json.encode(chatRooms.map((room) => room.toJson()).toList());
    await _prefs.setString(_CHATROOMS_KEY, jsonString);
  }

  @override
  Future<List<ChatRoom>> getCachedChatRooms() async {
    final jsonString = _prefs.getString(_CHATROOMS_KEY);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => ChatRoom.fromJson(item)).toList();
    } catch (e) {
      print('解析缓存聊天室出错: $e');
      return [];
    }
  }

  @override
  Future<void> cacheCurrentUser(UserModel user) async {
    final jsonString = json.encode(user.toJson());
    await _prefs.setString(_CURRENT_USER_KEY, jsonString);
  }

  @override
  Future<UserModel?> getCachedCurrentUser() async {
    final jsonString = _prefs.getString(_CURRENT_USER_KEY);
    if (jsonString == null) return null;

    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return UserModel.fromJson(jsonMap);
    } catch (e) {
      print('解析缓存当前用户出错: $e');
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    // 获取所有键
    final keys = _prefs.getKeys();

    // 筛选相关键
    final chatKeys = keys
        .where((key) =>
            key == _USERS_KEY ||
            key == _CHATROOMS_KEY ||
            key == _CURRENT_USER_KEY ||
            key.startsWith(_MESSAGES_PREFIX))
        .toList();

    // 移除相关缓存
    for (final key in chatKeys) {
      await _prefs.remove(key);
    }
  }

  // 辅助方法：将存储的域实体转换为数据模型
  List<UserModel> _convertUsersToModels(List<User> users) {
    return users
        .map((user) => UserModel.fromEntity(
              user,
              socketId: 'local-${user.id}', // 本地存储时使用特殊前缀，表示非实时连接
              connected: false,
              lastActive: user.lastSeen,
            ))
        .toList();
  }

  // 辅助方法：将数据模型转换为域实体
  List<User> _convertModelsToUsers(List<UserModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final jsonString = _prefs.getString(_chatRoomsKey);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => ChatRoom.fromJson(item)).toList();
    } catch (e) {
      print('获取本地聊天室失败: $e');
      throw CacheException();
    }
  }

  @override
  Future<void> saveChatRooms(List<ChatRoom> rooms) async {
    try {
      final jsonList = rooms.map((room) => room.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _prefs.setString(_chatRoomsKey, jsonString);
      print('保存了 ${rooms.length} 个聊天室到本地缓存');
    } catch (e) {
      print('保存聊天室失败: $e');
      throw CacheException();
    }
  }

  @override
  Future<List<Message>> getMessages(String chatRoomId) async {
    try {
      final key = '$_messagesKeyPrefix$chatRoomId';
      final jsonString = _prefs.getString(key);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => Message.fromJson(item)).toList();
    } catch (e) {
      print('获取本地消息失败: $e');
      throw CacheException();
    }
  }

  @override
  Future<void> saveMessages(String chatRoomId, List<Message> messages) async {
    try {
      final key = '$_messagesKeyPrefix$chatRoomId';
      final jsonList = messages.map((message) => message.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _prefs.setString(key, jsonString);
      print('保存了 ${messages.length} 条消息到本地缓存 (房间: $chatRoomId)');
    } catch (e) {
      print('保存消息列表失败: $e');
      throw CacheException();
    }
  }

  @override
  Future<void> saveMessage(String chatRoomId, Message message) async {
    try {
      // 获取现有消息
      final messages = await getMessages(chatRoomId);

      // 检查消息是否已存在
      final existingIndex = messages.indexWhere((m) => m.id == message.id);

      if (existingIndex >= 0) {
        // 更新现有消息
        messages[existingIndex] = message;
      } else {
        // 添加新消息
        messages.add(message);
      }

      // 保存更新后的消息列表
      await saveMessages(chatRoomId, messages);
      print('保存/更新消息 ${message.id} 到本地缓存 (房间: $chatRoomId)');
    } catch (e) {
      print('保存单条消息失败: $e');
      throw CacheException();
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    try {
      final timestamp = _prefs.getInt(_lastSyncKey);
      if (timestamp == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('获取同步时间失败: $e');
      throw CacheException();
    }
  }

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    try {
      final timestamp = time.millisecondsSinceEpoch;
      await _prefs.setInt(_lastSyncKey, timestamp);
    } catch (e) {
      print('保存同步时间失败: $e');
      throw CacheException();
    }
  }

  // 辅助方法：清除特定聊天室的缓存
  Future<void> clearChatRoomCache(String chatRoomId) async {
    try {
      final key = '$_messagesKeyPrefix$chatRoomId';
      await _prefs.remove(key);
      print('清除了聊天室 $chatRoomId 的缓存');
    } catch (e) {
      print('清除聊天室缓存失败: $e');
      throw CacheException();
    }
  }

  // 辅助方法：清除所有聊天相关缓存
  Future<void> clearAllChatCache() async {
    try {
      // 获取所有键
      final keys = _prefs.getKeys();

      // 筛选聊天相关的键
      final chatKeys = keys
          .where((key) =>
              key == _USERS_KEY ||
              key == _CHATROOMS_KEY ||
              key == _CURRENT_USER_KEY ||
              key.startsWith(_messagesKeyPrefix) ||
              key == _lastSyncKey)
          .toList();

      // 删除键
      for (final key in chatKeys) {
        await _prefs.remove(key);
      }

      print('清除了所有聊天缓存 (${chatKeys.length} 个键)');
    } catch (e) {
      print('清除所有聊天缓存失败: $e');
      throw CacheException();
    }
  }
}
