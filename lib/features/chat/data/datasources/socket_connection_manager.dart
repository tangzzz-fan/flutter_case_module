import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../../core/exceptions.dart';

class SocketConnectionManager {
  static SocketConnectionManager? _instance;
  late IO.Socket _socket;
  bool _isConnected = false;
  final String serverUrl;
  final Map<String, dynamic> authInfo;
  final _connectionStatusController = StreamController<bool>.broadcast();

  // 添加自动重连逻辑
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  // 单例模式
  factory SocketConnectionManager(
      {required String serverUrl, required Map<String, dynamic> authInfo}) {
    _instance ??= SocketConnectionManager._internal(
      serverUrl: serverUrl,
      authInfo: authInfo,
    );
    return _instance!;
  }

  SocketConnectionManager._internal({
    required this.serverUrl,
    required this.authInfo,
  }) {
    _initSocket();
  }

  void _initSocket() {
    // 确保URL正确格式化 - 修改为支持WebSocket URL格式
    final formattedUrl =
        serverUrl.startsWith('http') || serverUrl.startsWith('ws')
            ? serverUrl
            : 'http://$serverUrl';

    print('尝试连接到Socket.IO服务器: $formattedUrl');
    print('认证信息: $authInfo');

    // 改为与TypeScript客户端相似的认证方式
    final Map<String, dynamic> auth = {
      'username': authInfo['username'] ?? 'guest_user',
    };

    // 如果有token，添加到auth而不是query
    if (authInfo.containsKey('token') &&
        authInfo['token'] != null &&
        authInfo['token'].isNotEmpty) {
      auth['token'] = authInfo['token'];
    }

    print('Socket.IO认证参数: $auth');

    // 配置Socket.IO - 与TypeScript客户端保持一致
    _socket = IO.io(
        formattedUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableForceNew()
            .setAuth(auth)
            .setTimeout(20000) // 增加超时时间到20秒
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setExtraHeaders({
              'X-Client-Info':
                  'FlutterClient-${auth["username"]}-${DateTime.now().millisecondsSinceEpoch}'
            })
            .build());

    // 增加更详细的日志记录
    _socket.onConnect((_) {
      print('Socket.IO连接成功: ${_socket.id}');
      try {
        print('Transport: ${_socket.io.engine!.transport!.name}');
      } catch (e) {
        print('无法获取transport信息');
      }
      _isConnected = true;
      _connectionStatusController.add(true);
    });

    _socket.on('connect_error', (error) {
      print('Socket连接错误: $error');
      _scheduleReconnect();
    });

    _socket.on('disconnect', (_) {
      _isConnected = false;
      _connectionStatusController.add(false);
      print('Socket连接断开');
      _scheduleReconnect();
    });

    _socket.on('error', (error) {
      print('Socket错误: $error');

      // 检查是否是认证错误
      if (error is Map &&
          error.containsKey('message') &&
          error['message'].toString().contains('认证失败')) {
        // 认证失败不尝试自动重连
        print('认证失败，停止自动重连');
        resetReconnectAttempts();
      }
    });

    // 添加额外的调试监听，类似TypeScript客户端的调试监听器
    _socket.onAny((event, data) {
      print('收到事件: $event, 数据: $data');
    });

    // 监听所有引擎级别事件
    try {
      _socket.io.engine?.on('packet', (data) {
        print('底层数据包: $data');
      });

      _socket.io.engine?.on('upgrade', (transport) {
        print('连接已升级到: $transport');
      });
    } catch (e) {
      print('无法添加引擎级别监听器: $e');
    }
  }

  void _scheduleReconnect() {
    // 避免重复设置重连定时器
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;

    // 指数退避重连策略
    if (_reconnectAttempts < maxReconnectAttempts) {
      final backoffTime =
          Duration(milliseconds: 1000 * (1 << _reconnectAttempts));
      print(
          '计划 ${backoffTime.inSeconds} 秒后重连 (尝试 ${_reconnectAttempts + 1}/$maxReconnectAttempts)');

      _reconnectTimer = Timer(backoffTime, () {
        _reconnectAttempts++;
        if (!_isConnected) {
          print('正在尝试重连...');
          connect().then((success) {
            if (success) {
              _reconnectAttempts = 0;
              print('重连成功');
            }
          }).catchError((e) {
            print('重连失败: $e');
          });
        }
      });
    } else {
      print('达到最大重连次数限制，停止自动重连');
    }
  }

  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<bool> connect() async {
    if (_isConnected) return true;

    try {
      print('正在连接到Socket.IO服务器: $serverUrl');

      // 由于我们不再使用disableAutoConnect()，
      // 所以只需要在Socket尚未连接时才调用connect()
      if (!_socket.connected) {
        _socket.connect();
      }

      final completer = Completer<bool>();

      // 监听一次性连接事件
      _socket.onConnect((_) {
        print('Socket连接成功，ID: ${_socket.id}');

        // 尝试打印传输方式，与TypeScript客户端保持一致
        try {
          final transport = _socket.io.engine?.transport?.name;
          print('传输方式: $transport');
        } catch (e) {
          print('无法获取传输方式信息: $e');
        }

        _isConnected = true;
        _connectionStatusController.add(true);
        completer.complete(true);
        resetReconnectAttempts();
      });

      _socket.onConnectError((error) {
        final errorMsg = '无法连接到服务器 $serverUrl：${error.toString()}';
        print('连接错误: $errorMsg');
        completer.completeError(ConnectionException(errorMsg));
      });

      _socket.onConnectTimeout((_) {
        final errorMsg = '连接超时: $serverUrl';
        print(errorMsg);
        completer.completeError(ConnectionException(errorMsg));
      });

      return await completer.future
          .timeout(const Duration(seconds: 20), // 增加超时时间
              onTimeout: () {
        print('连接尝试超时');
        throw ConnectionException('连接超时，服务器未响应');
      });
    } catch (e) {
      final errorMsg = '连接出错: ${e.toString()}';
      print(errorMsg);
      if (e is ConnectionException) rethrow;
      throw ConnectionException(errorMsg);
    }
  }

  Future<bool> disconnect() async {
    if (!_isConnected) return true;

    try {
      _socket.disconnect();
      return true;
    } catch (e) {
      throw ServerException();
    }
  }

  // 允许更新认证信息并重新初始化连接
  void updateAuthInfo(Map<String, dynamic> newAuthInfo) {
    // 如果连接中，先断开
    if (_isConnected) {
      _socket.disconnect();
    }

    // 更新认证信息
    _instance = SocketConnectionManager._internal(
      serverUrl: serverUrl,
      authInfo: newAuthInfo,
    );

    // 尝试重新连接
    _instance!.connect();
  }

  bool get isConnected => _isConnected;

  IO.Socket get socket => _socket;

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  void dispose() {
    _reconnectTimer?.cancel();
    _socket.dispose();
    _connectionStatusController.close();
    _instance = null;
  }
}
