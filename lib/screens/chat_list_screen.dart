import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/chat/domain/entities/chat_room.dart';
import 'chat_detail_screen.dart';
import '../features/chat/data/providers/chat_data_providers.dart';
import '../features/chat/data/providers/auth_providers.dart';
import '../features/chat/presentation/widgets/connection_status_indicator.dart';
import 'dart:async';

/// 聊天会话列表页面
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  static const platform = MethodChannel('com.example.swiftflutter/channel');

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  bool _isTesting = false;
  Map<String, dynamic>? _testResult;

  @override
  void initState() {
    super.initState();
    // 初始化连接
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    final socketManager = ref.read(socketConnectionManagerProvider);
    try {
      await socketManager.connect();
      print('初始化Socket连接成功');
    } catch (e) {
      print('初始化Socket连接失败: $e');
    }
  }

  // 测试连接方法
  Future<void> _testConnection() async {
    final manager = ref.read(socketConnectionManagerProvider);

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      // 获取诊断信息
      final diagnosticInfo = manager.getDiagnosticInfo();
      print('💻 诊断信息: $diagnosticInfo');

      // 测试连接
      final result = await manager.testConnection();
      print('🔍 连接测试结果: $result');

      setState(() {
        _testResult = result;
        _isTesting = false;
      });

      // 显示测试结果
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['success']
                ? '连接测试成功！Socket ID: ${result['socketId']}'
                : '连接测试失败: ${result['error']}',
          ),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: '详情',
            textColor: Colors.white,
            onPressed: () {
              _showConnectionDetails(result);
            },
          ),
        ),
      );
    } catch (e) {
      print('❌ 测试连接时出错: $e');
      setState(() {
        _testResult = {
          'success': false,
          'error': '测试过程异常: $e',
          'timeTaken': 0,
        };
        _isTesting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('测试连接时出错: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 显示连接详情对话框
  void _showConnectionDetails(Map<String, dynamic> result) {
    final manager = ref.read(socketConnectionManagerProvider);
    final info = manager.getDiagnosticInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('连接详情'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('连接状态: ${result['success'] ? '成功' : '失败'}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (result['socketId'] != null)
                Text('Socket ID: ${result['socketId']}'),
              if (result['error'] != null)
                Text('错误: ${result['error']}',
                    style: TextStyle(color: Colors.red)),
              Text('耗时: ${result['timeTaken']}ms'),
              Divider(),
              Text('诊断信息:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _buildDiagnosticInfoList(info),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 构建诊断信息列表
  Widget _buildDiagnosticInfoList(Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Socket初始化: ${info['socketInitialized']}'),
        Text('Socket ID: ${info['socketId'] ?? '无'}'),
        Text('连接状态: ${info['isConnected']}'),
        Text('初始化中: ${info['isInitializing']}'),
        Text('重连尝试: ${info['reconnectAttempts']}'),
        Text('服务器URL: ${info['serverUrl']}'),
        Text('传输类型: ${info['transportType'] ?? '未知'}'),
        Text('引擎状态: ${info['engineState'] ?? '未知'}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 获取用户名
    final userInfo = ref.watch(authInfoProvider);
    final username = userInfo.whenOrNull(
          data: (data) => data['username'] as String?,
        ) ??
        '加载中...';

    // 监听连接状态
    final connectionState = ref.watch(socketConnectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('会话列表'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.clear),
          onPressed: () {
            _returnToNative();
          },
        ),
        actions: [
          // 显示连接状态的小指示器
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connectionState.maybeWhen(
                data: (connected) => connected ? Colors.green : Colors.red,
                orElse: () => Colors.grey,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 实现搜索功能
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // 实现新建聊天功能
            },
          ),
          // 测试连接按钮
          IconButton(
            icon: _isTesting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(Icons.network_check),
            tooltip: '测试连接',
            onPressed: _isTesting ? null : _testConnection,
          ),
          // 用户信息按钮
          IconButton(
            icon: Icon(Icons.account_circle),
            tooltip: '用户信息',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('当前用户: $username')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 连接状态指示器
          const ConnectionStatusIndicator(),

          // 显示测试结果（如果有）
          if (_testResult != null)
            Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _testResult!['success']
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _testResult!['success'] ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('连接测试结果:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('状态: ${_testResult!['success'] ? '成功' : '失败'}'),
                  if (_testResult!['socketId'] != null)
                    Text('Socket ID: ${_testResult!['socketId']}'),
                  if (_testResult!['error'] != null)
                    Text('错误: ${_testResult!['error']}',
                        style: TextStyle(color: Colors.red)),
                  Text('响应时间: ${_testResult!['timeTaken']}ms'),

                  // 查看详情按钮
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showConnectionDetails(_testResult!),
                      child: Text('查看详情'),
                    ),
                  ),
                ],
              ),
            ),

          // 内容区域
          Expanded(
            child: connectionState.when(
              data: (isConnected) {
                if (isConnected) {
                  // 显示聊天室列表或导航到聊天室页面
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('已连接到聊天服务器', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            // 导航到聊天室页面
                            Navigator.pushNamed(context, '/chat_rooms');
                          },
                          child: Text('进入聊天室'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // 显示未连接状态
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('未连接到聊天服务器',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('请检查网络连接后重试'),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _initializeConnection,
                          child: Text('重新连接'),
                        ),
                      ],
                    ),
                  );
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('连接错误',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('$error'),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _initializeConnection,
                      child: Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChatDetail(
      BuildContext context, WidgetRef ref, ChatRoom chatRoom) {
    // 导航到聊天详情页面
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chatRoom.id,
            chatName: chatRoom.name,
          ),
        ));
  }

  void _returnToNative() async {
    // try {
    //   await platform.invokeMethod('willCloseFlutterView');
    //   SystemNavigator.pop();
    // } catch (e) {
    //   print('关闭页面时出错: $e');
    //   SystemNavigator.pop();
    // }
  }
}
