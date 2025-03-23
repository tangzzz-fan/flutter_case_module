import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_module/features/chat/data/datasources/socket_connection_manager.dart';
import 'package:flutter_module/features/chat/data/models/message_model.dart';
import 'package:flutter_module/features/chat/data/models/user_model.dart';
import 'package:flutter_module/features/chat/domain/entities/chat_state.dart';
import 'package:flutter_module/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_module/features/chat/domain/repositories/chat_repository.dart';

// ChatProvider 改为 StateNotifier
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
        final users =
            data.map((userData) => UserModel.fromJson(userData)).toList();
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
      final message = MessageModel.fromJson(data);
      final updatedMessages = [...state.messages, message];
      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      print('处理消息时出错: $e');
    }
  }

  // 处理用户加入
  void _handleUserJoined(dynamic data) {
    try {
      final user = UserModel.fromJson(data);
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

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
