import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../../core/exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:math';
import 'dart:developer';

/// Socket连接管理器
/// 负责创建和管理与Socket.IO服务器的连接
class SocketConnectionManager {
  static SocketConnectionManager? _instance;
  final String serverUrl;
  final Future<Map<String, dynamic>> authInfoFuture;

  // 移除 late 关键字，改为可空类型
  IO.Socket? _socket;
  bool _isConnected = false;
  final _connectionStatusController = StreamController<bool>.broadcast();

  // 添加自动重连逻辑
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  // 添加初始化状态标志
  bool _isInitializing = false;
  Completer<bool>? _connectCompleter;

  // 单例模式
  factory SocketConnectionManager({
    required String serverUrl,
    required Future<Map<String, dynamic>> authInfoFuture,
  }) {
    _instance ??= SocketConnectionManager._internal(
      serverUrl: serverUrl,
      authInfoFuture: authInfoFuture,
    );
    return _instance!;
  }

  SocketConnectionManager._internal({
    required this.serverUrl,
    required this.authInfoFuture,
  }) {
    print('创建 SocketConnectionManager 实例，服务器: $serverUrl');
  }

  /// 初始化Socket连接并返回连接状态
  Future<bool> connect() async {
    print(
        '📞 Socket连接请求开始 - URL: $serverUrl, 已连接: $_isConnected, 初始化中: $_isInitializing');

    // 如果已经连接，直接返回成功
    if (_isConnected && _socket != null) {
      print('Socket已经连接，ID: ${_socket!.id}');
      return true;
    }

    // 如果正在初始化，等待完成
    if (_isInitializing) {
      print('Socket连接正在初始化中，等待...');
      return _connectCompleter?.future ?? Future.value(false);
    }

    _isInitializing = true;
    _connectCompleter = Completer<bool>();

    try {
      print('⚡️ 开始连接到Socket.IO服务器: $serverUrl');

      // 等待认证信息
      final authInfo = await authInfoFuture;
      print('🔑 已获取认证信息，用户名: ${authInfo['username']}');

      // 确保URL正确格式化 - 修改为支持WebSocket URL格式
      final formattedUrl =
          serverUrl.startsWith('http') || serverUrl.startsWith('ws')
              ? serverUrl
              : 'http://$serverUrl';

      print('🔌 使用格式化URL: $formattedUrl');

      // 在创建 Socket 实例之前添加日志
      print('🔧 准备创建 Socket 实例，配置: transport=websocket, autoConnect=false');

      // 在这里初始化 Socket 实例
      _socket = IO.io(
          formattedUrl,
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .disableAutoConnect()
              .enableForceNew()
              .setExtraHeaders({
                'authorization': authInfo['token'] ?? '',
                'content-type': 'application/json',
              })
              .setAuth({
                'username': authInfo['username'] ?? 'guest',
              })
              .setQuery({
                'platform': 'flutter',
                'version': '1.0.0',
                'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
              })
              .setTimeout(10000)
              .setReconnectionAttempts(5)
              .setReconnectionDelay(1000)
              .build());

      // 创建 Socket 后添加日志
      print('✅ Socket 实例已创建，ID: ${_socket?.id ?? '暂无ID'}');

      // 清除可能存在的旧事件监听器
      _socket?.off('connect');
      _socket?.off('disconnect');
      _socket?.off('connect_error');
      _socket?.off('error');

      print('📝 已创建Socket实例，设置事件处理...');

      // 绑定事件前添加日志
      print('📡 正在绑定 Socket 事件处理器');

      // 设置事件处理
      _setupEventHandlers();

      // 连接到服务器
      print('🚀 触发Socket连接...');
      _socket!.connect();

      final completeResult = await _connectCompleter!.future
          .timeout(const Duration(seconds: 15), onTimeout: () {
        print('⚠️ Socket连接超时！');
        _isInitializing = false;
        _onConnectionFailed('连接超时');
        return false;
      });

      return completeResult;
    } catch (e) {
      final errorMsg = '❌ 连接出错: ${e.toString()}';
      print(errorMsg);
      _isInitializing = false;
      _onConnectionFailed(errorMsg);
      if (e is ConnectionException) rethrow;
      throw ConnectionException(errorMsg);
    }
  }

  void _setupEventHandlers() {
    if (_socket == null) {
      print('❌ 无法设置事件处理器：_socket 为 null');
      return;
    }

    print('📌 绑定 connect 事件处理器');
    _socket!.on('connect', (_) {
      print('🟢 Socket已连接！Socket ID: ${_socket!.id}');
      _isConnected = true;
      _connectionStatusController.add(true);
      _isInitializing = false;
      _connectCompleter?.complete(true);
      resetReconnectAttempts();
    });

    // 断开连接事件
    _socket!.on('disconnect', (reason) {
      print('🔴 Socket已断开连接，原因: $reason');
      _isConnected = false;
      _connectionStatusController.add(false);
      _scheduleReconnect();
    });

    // 连接错误
    _socket!.on('connect_error', (error) {
      print('⚠️ Socket连接错误: $error');
      _onConnectionFailed('连接错误: $error');
    });

    // 其他可能的事件
    _socket!.on('error', (error) {
      print('⚠️ Socket错误: $error');
    });
  }

  // 处理连接失败
  void _onConnectionFailed(String reason) {
    _isConnected = false;
    _connectionStatusController.add(false);
    _isInitializing = false;
    _connectCompleter?.completeError(ConnectionException(reason));
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    // 避免重复设置重连定时器
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;

    // 指数退避重连策略
    if (_reconnectAttempts < maxReconnectAttempts) {
      final backoffTime =
          Duration(milliseconds: 1000 * (1 << _reconnectAttempts));
      print(
          '🔄 计划 ${backoffTime.inSeconds} 秒后重连 (尝试 ${_reconnectAttempts + 1}/$maxReconnectAttempts)');

      _reconnectTimer = Timer(backoffTime, () {
        _reconnectAttempts++;
        if (!_isConnected && !_isInitializing) {
          print('🔄 正在尝试自动重连...');
          connect().then((success) {
            if (success) {
              _reconnectAttempts = 0;
              print('✅ 自动重连成功');
            }
          }).catchError((e) {
            print('❌ 自动重连失败: $e');
          });
        }
      });
    } else {
      print('⛔ 达到最大重连次数限制，停止自动重连');
    }
  }

  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<bool> disconnect() async {
    if (!_isConnected || _socket == null) return true;

    try {
      _socket!.disconnect();
      _isConnected = false;
      _connectionStatusController.add(false);
      return true;
    } catch (e) {
      print('断开连接时出错: $e');
      throw ServerException();
    }
  }

  // 允许更新认证信息并重新初始化连接
  void updateAuthInfo(Map<String, dynamic> newAuthInfo) {
    if (_isConnected && _socket != null) {
      disconnect();
    }
  }

  bool get isConnected => _isConnected;

  IO.Socket get socket {
    if (_socket == null) {
      throw StateError('Socket 尚未连接，应先调用 connect() 方法');
    }
    return _socket!;
  }

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  void dispose() {
    _reconnectTimer?.cancel();
    if (_isConnected && _socket != null) {
      _socket!.disconnect();
    }
    _connectionStatusController.close();
    _isInitializing = false;
    _connectCompleter = null;
    _instance = null;
  }

  // 添加显式的初始化方法
  Future<void> initialize() async {
    print('🚀 初始化 SocketConnectionManager');
    // 预加载认证信息
    try {
      final authInfo = await authInfoFuture;
      print('🔑 预加载认证信息成功: ${authInfo['username']}');
    } catch (e) {
      print('⚠️ 预加载认证信息失败: $e');
    }
  }

  // 添加应用前台/后台状态监听
  void handleAppLifecycleState(AppLifecycleState state) {
    print('📱 应用生命周期状态变更: $state');
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isConnected && !_isInitializing) {
          print('📱 应用回到前台，尝试重新连接');
          connect();
        }
        break;
      case AppLifecycleState.paused:
        print('📱 应用进入后台');
        // 可以选择断开连接或保持连接
        break;
      default:
        break;
    }
  }

  // 添加诊断方法
  Map<String, dynamic> getDiagnosticInfo() {
    return {
      'socketInitialized': _socket != null,
      'socketId': _socket?.id,
      'isConnected': _isConnected,
      'isInitializing': _isInitializing,
      'reconnectAttempts': _reconnectAttempts,
      'serverUrl': serverUrl,
      'transportType': _socket?.io?.engine?.transport?.name,
      'engineState': _socket?.io?.engine?.readyState,
      'hasListeners': _connectionStatusController.hasListener,
    };
  }

  // 添加测试连接方法
  Future<Map<String, dynamic>> testConnection() async {
    final stopwatch = Stopwatch()..start();

    // 如果已经连接，直接返回当前连接信息
    if (_isConnected && _socket != null) {
      stopwatch.stop();
      return {
        'success': true,
        'socketId': _socket!.id,
        'timeTaken': 0,
        'fromExistingConnection': true,
      };
    }

    final Completer<Map<String, dynamic>> completer = Completer();

    try {
      // 创建一个临时 socket 只用于测试
      final testSocket = IO.io(
        serverUrl,
        IO.OptionBuilder().setTransports(['websocket']).setAuth(
                {'username': 'test-user'}) // 添加最基本的认证信息
            .build(),
      );

      // 设置 5 秒超时
      Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          testSocket.disconnect();
          completer.complete({
            'success': false,
            'error': '连接超时',
            'timeTaken': stopwatch.elapsedMilliseconds,
          });
        }
      });

      testSocket.on('connect', (_) {
        stopwatch.stop();
        testSocket.disconnect();
        completer.complete({
          'success': true,
          'socketId': testSocket.id,
          'timeTaken': stopwatch.elapsedMilliseconds,
        });
      });

      testSocket.on('connect_error', (error) {
        stopwatch.stop();
        testSocket.disconnect();
        completer.complete({
          'success': false,
          'error': error.toString(),
          'timeTaken': stopwatch.elapsedMilliseconds,
        });
      });

      testSocket.connect();
    } catch (e) {
      stopwatch.stop();
      completer.complete({
        'success': false,
        'error': e.toString(),
        'timeTaken': stopwatch.elapsedMilliseconds,
      });
    }

    return completer.future;
  }
}
