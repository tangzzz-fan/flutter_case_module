import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_module/features/chat/data/datasources/socket_connection_manager.dart';
import 'package:flutter_module/features/chat/data/models/message_model.dart';
import 'package:flutter_module/features/chat/data/models/user_model.dart';
import 'package:flutter_module/features/chat/domain/entities/chat_state.dart';
import 'package:flutter_module/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_module/features/chat/domain/entities/message.dart';
import 'package:flutter_module/features/chat/domain/entities/user.dart';
import 'package:flutter_module/features/chat/domain/repositories/chat_repository.dart';

class ChatNotifier extends StateNotifier<ChatState> {
  final SocketConnectionManager _socketManager;
  final ChatRepository _chatRepository;

  // 错误信息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 用于监听socket连接状态的订阅
  StreamSubscription<bool>? _connectionSubscription;

  ChatNotifier(this._socketManager, this._chatRepository)
      : super(ChatState.initial()) {
    // 初始化时设置连接状态监听
    _setupConnectionStatusListener();
    // 初始化时设置事件监听
    _setupEventListeners();
  }

  // 设置连接状态监听
  void _setupConnectionStatusListener() {
    _connectionSubscription =
        _socketManager.connectionStatus.listen((connected) {
      print('收到连接状态更新: $connected');
      _updateConnectionState(connected);
    });
  }

  // 更新连接状态
  void _updateConnectionState(bool connected) {
    if (connected) {
      state = state.copyWith(connectionStatus: ConnectionStatus.connected);
      _errorMessage = null;
    } else {
      state = state.copyWith(connectionStatus: ConnectionStatus.disconnected);
    }
  }

  // 设置事件监听
  void _setupEventListeners() {
    if (!_socketManager.isConnected) return;

    final socket = _socketManager.socket;

    // 用户列表更新
    socket.on('users:list', (data) {
      print('收到用户列表: $data');
      _handleUsersList(data);
    });

    // 添加对聊天室列表的监听
    socket.on('room:list', (data) {
      print('收到聊天室列表: $data');
      _handleRoomList(data);
    });

    // 消息接收
    socket.on('message', (data) {
      print('收到消息: $data');
      _handleNewMessage(data);
    });

    // 用户加入
    socket.on('user_joined', (data) {
      print('用户加入: $data');
      _handleUserJoined(data);
    });

    // 用户离开
    socket.on('user_left', (data) {
      print('用户离开: $data');
      _handleUserLeft(data);
    });

    // 错误处理
    socket.on('error', (data) {
      print('错误: $data');
      _handleError(data);
    });
  }

  // 处理用户列表
  void _handleUsersList(dynamic data) {
    try {
      if (data is List) {
        // 修复：将 UserModel 转换为 User 然后再设置状态
        final users = data
            .map((userData) => UserModel.fromJson(userData).toUser())
            .toList();
        state = state.copyWith(users: users);
      }
    } catch (e) {
      print('处理用户列表时出错: $e');
    }
  }

  // 处理聊天室列表
  void _handleRoomList(dynamic data) {
    try {
      if (data is List) {
        // 解析聊天室数据并更新状态
        final chatRooms =
            data.map((roomData) => ChatRoom.fromJson(roomData)).toList();
        state = state.copyWith(chatRooms: chatRooms);
        print('更新聊天室列表: ${chatRooms.length} 个聊天室');
      }
    } catch (e) {
      print('处理聊天室列表时出错: $e');
    }
  }

  // 处理新消息
  void _handleNewMessage(dynamic data) {
    try {
      // 修复：将 MessageModel 转换为 Message 然后再设置状态
      final messageModel = MessageModel.fromJson(data);
      final message = messageModel.toMessage();
      final updatedMessages = [...state.messages, message];
      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      print('处理消息时出错: $e');
    }
  }

  // 处理用户加入
  void _handleUserJoined(dynamic data) {
    try {
      // 修复：将 UserModel 转换为 User 然后再设置状态
      final userModel = UserModel.fromJson(data);
      final user = userModel.toUser();

      if (!state.users.any((u) => u.id == user.id)) {
        final updatedUsers = [...state.users, user];
        state = state.copyWith(users: updatedUsers);
      }
    } catch (e) {
      print('处理用户加入时出错: $e');
    }
  }

  // 处理用户离开
  void _handleUserLeft(dynamic data) {
    try {
      final userId = data['id'];
      final updatedUsers =
          state.users.where((user) => user.id != userId).toList();
      state = state.copyWith(users: updatedUsers);
    } catch (e) {
      print('处理用户离开时出错: $e');
    }
  }

  // 处理错误
  void _handleError(dynamic data) {
    try {
      _errorMessage = data['message'] ?? '发生未知错误';
      // 不需要调用notifyListeners，StateNotifier会自动通知
    } catch (e) {
      print('处理错误时出错: $e');
    }
  }

  // 发送消息
  Future<bool> sendMessage(String content,
      {String? toUserId, String? toRoomId}) async {
    if (!_socketManager.isConnected) {
      _errorMessage = '未连接到服务器，无法发送消息';
      return false;
    }

    try {
      final event = toRoomId != null ? 'message_room' : 'message_private';
      final data = {
        'content': content,
        if (toUserId != null) 'to': toUserId,
        if (toRoomId != null) 'roomId': toRoomId,
      };

      _socketManager.socket.emit(event, data);
      return true;
    } catch (e) {
      _errorMessage = '发送消息失败: $e';
      return false;
    }
  }

  // 连接到聊天服务器
  Future<bool> connect() async {
    try {
      // 发起连接请求并等待结果
      await _socketManager.connect();

      // 连接成功，更新状态
      state = state.copyWith(connectionStatus: ConnectionStatus.connected);
      return true;
    } catch (error) {
      // 处理错误
      _errorMessage = '连接失败: $error';
      state = state.copyWith(connectionStatus: ConnectionStatus.error);
      return false;
    }
  }

  // 断开连接
  Future<void> disconnect() async {
    try {
      await _socketManager.disconnect();
      state = state.copyWith(connectionStatus: ConnectionStatus.disconnected);
    } catch (e) {
      _errorMessage = '断开连接失败: $e';
    }
  }

  // 更新认证信息并重新连接
  Future<bool> updateAuthAndReconnect(Map<String, dynamic> newAuthInfo) async {
    try {
      _socketManager.updateAuthInfo(newAuthInfo);
      return await connect();
    } catch (e) {
      _errorMessage = '更新认证信息失败: $e';
      return false;
    }
  }

  // 添加 getChatRooms 方法
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      // 检查连接状态
      if (!_socketManager.isConnected) {
        final connected = await connect();
        if (!connected) {
          _errorMessage = '未连接到服务器，无法获取聊天室列表';
          return [];
        }
      }

      // 调用仓库获取聊天室列表
      final result = await _chatRepository.getChatRooms();
      return result.fold(
        (failure) {
          _errorMessage = '获取聊天室失败: ${failure.message}';
          return [];
        },
        (rooms) {
          // 更新状态
          state = state.copyWith(chatRooms: rooms);
          return rooms;
        },
      );
    } catch (e) {
      _errorMessage = '获取聊天室出错: $e';
      return [];
    }
  }

  // 处理加入聊天室
  Future<bool> joinRoom(String roomId) async {
    try {
      if (!_socketManager.isConnected) {
        _errorMessage = '未连接到服务器，无法加入聊天室';
        return false;
      }

      _socketManager.socket.emit('join_room', {'roomId': roomId});
      return true;
    } catch (e) {
      _errorMessage = '加入聊天室失败: $e';
      return false;
    }
  }

  /// 创建新的聊天室
  ///
  /// [roomName] 聊天室名称
  /// [isPrivate] 是否为私有房间
  /// [members] 初始成员ID列表
  /// 返回值：成功时返回创建的聊天室，失败时返回null
  Future<ChatRoom?> createChatRoom({
    required String roomName,
    bool isPrivate = false,
    List<String>? members,
  }) async {
    try {
      // 更新状态为加载中
      state = state.copyWith(status: ChatStatus.loading);

      if (!_socketManager.isConnected) {
        _errorMessage = '未连接到服务器，无法创建聊天室';
        state = state.copyWith(
          status: ChatStatus.error,
          errorMessage: '未连接到服务器，无法创建聊天室',
        );
        return null;
      }

      // 根据文档创建房间数据
      final roomData = {
        'roomName': roomName,
        'isPrivate': isPrivate,
        if (members != null && members.isNotEmpty) 'members': members,
      };

      // 发送创建房间事件
      _socketManager.socket.emit('room_created', roomData);

      // 创建临时聊天室对象
      final tempRoom = ChatRoom(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: roomName,
        description: '新建聊天室',
        isPrivate: isPrivate,
        creatorId: await _socketManager.getCurrentUserId(),
        members: members != null
            ? members
                .map((id) => User(id: id, name: '', isOnline: false))
                .toList()
            : [
                User(
                    id: await _socketManager.getCurrentUserId(),
                    name: '',
                    isOnline: true)
              ],
        createdAt: DateTime.now(),
      );

      // 将临时聊天室添加到状态中
      final updatedRooms = [...state.chatRooms, tempRoom];
      state = state.copyWith(
        status: ChatStatus.success,
        chatRooms: updatedRooms,
        errorMessage: null,
      );

      // 临时解决方案：等待一段时间后重新获取聊天室列表
      // 实际应用中应该使用Socket.IO的回调或事件监听
      Future.delayed(const Duration(milliseconds: 500), () {
        getChatRooms();
      });

      return tempRoom;
    } catch (e) {
      // 处理错误
      _errorMessage = '创建聊天室失败: ${e.toString()}';
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: '创建聊天室失败: ${e.toString()}',
      );
      return null;
    }
  }

  // 重命名原来的方法以区分 Socket 创建和 API 创建
  Future<void> createChatRoomViaAPI({
    required String name,
    required List<String> participants,
    required bool isGroup,
    String? description,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      state = state.copyWith(status: ChatStatus.loading);

      final result = await _chatRepository.createChatRoom(
        name: name,
        participants: participants,
        isGroup: isGroup,
        description: description,
        avatarUrl: avatarUrl,
        metadata: metadata,
      );

      // 处理成功创建聊天室后的逻辑
      final updatedRooms = [...state.chatRooms, result];
      state = state.copyWith(
        status: ChatStatus.success,
        chatRooms: updatedRooms,
      );
    } catch (e) {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: '创建聊天室失败: ${e.toString()}',
      );
    }
  }

  /// 发送私聊消息
  Future<bool> sendPrivateMessage({
    required String recipientId,
    required String content,
  }) async {
    try {
      final result = await _chatRepository.sendPrivateMessage(
        recipientId: recipientId,
        content: content,
      );

      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (message) {
          // 添加消息到本地状态
          final updatedMessages = [...state.messages, message];
          state = state.copyWith(messages: updatedMessages);
          return true;
        },
      );
    } catch (e) {
      _errorMessage = '发送私聊消息失败: $e';
      return false;
    }
  }

  /// 发送群聊消息
  Future<bool> sendRoomMessage({
    required String roomId,
    required String content,
  }) async {
    try {
      final result = await _chatRepository.sendRoomMessage(
        roomId: roomId,
        content: content,
      );

      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (message) {
          // 添加消息到本地状态
          final updatedMessages = [...state.messages, message];
          state = state.copyWith(messages: updatedMessages);
          return true;
        },
      );
    } catch (e) {
      _errorMessage = '发送群聊消息失败: $e';
      return false;
    }
  }

  /// 标记消息为已读
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      final result = await _chatRepository.markMessageAsRead(messageId);

      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (success) => success,
      );
    } catch (e) {
      _errorMessage = '标记消息已读失败: $e';
      return false;
    }
  }

  /// 离开聊天室
  Future<bool> leaveRoom(String roomId) async {
    try {
      final result = await _chatRepository.leaveRoom(roomId);

      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (success) => success,
      );
    } catch (e) {
      _errorMessage = '离开聊天室失败: $e';
      return false;
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
