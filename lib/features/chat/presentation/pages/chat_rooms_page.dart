import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/chat_data_providers.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/chat_room_list.dart';
import '../providers/chat_ui_providers.dart';

/// 聊天室列表页面
/// 显示所有可用的聊天室
class ChatRoomsPage extends ConsumerStatefulWidget {
  const ChatRoomsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatRoomsPage> createState() => _ChatRoomsPageState();
}

class _ChatRoomsPageState extends ConsumerState<ChatRoomsPage> {
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      print('初始化聊天连接...');
      // 触发连接
      ref.read(shouldConnectProvider.notifier).state = true;

      final connectionState =
          await ref.read(socketConnectionManagerProvider).connect();
      print('连接状态: $connectionState');
    } catch (e) {
      print('连接初始化异常: $e');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听连接状态
    final connectionState = ref.watch(socketConnectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天室'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _initializeConnection,
          ),
        ],
      ),
      body: Column(
        children: [
          // 连接状态指示器
          const ConnectionStatusIndicator(),

          // 连接状态消息
          connectionState.when(
            data: (isConnected) {
              if (!isConnected) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 48.0,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          '未连接到聊天服务器',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        const Text(
                          '请检查您的网络连接后重试',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _initializeConnection,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48.0,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      '连接错误: $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _initializeConnection,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 聊天室列表
          const Expanded(
            child: ChatRoomList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 创建新聊天室的逻辑
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('创建新聊天室功能即将上线！')),
          );
        },
        child: const Icon(Icons.add),
        tooltip: '创建新聊天室',
      ),
    );
  }
}
