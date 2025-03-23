import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/chat_data_providers.dart';
import '../../data/providers/auth_providers.dart';
import '../widgets/connection_status_indicator.dart';
import 'dart:async';
import '../providers/chat_ui_providers.dart';
import '../../domain/entities/chat_room.dart';
import 'chat_page.dart';

/// 聊天会话列表页面
class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  static const platform = MethodChannel('com.example.swiftflutter/channel');

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage>
    with WidgetsBindingObserver {
  bool _isTesting = false;
  Map<String, dynamic>? _testResult;
  bool _isCreatingRoom = false;
  // 添加一个焦点节点来检测页面焦点变化
  final FocusNode _pageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 初始化连接
    _initializeConnection();

    // 注册页面生命周期观察者
    WidgetsBinding.instance.addObserver(this);

    // 设置焦点监听器
    _pageFocusNode.addListener(_onFocusChange);
  }

  // 焦点变化回调
  void _onFocusChange() {
    if (_pageFocusNode.hasFocus) {
      // 当页面获得焦点时重新加载聊天室列表
      _refreshChatRooms();
    }
  }

  // 覆盖生命周期方法，检测页面恢复
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用恢复前台时刷新列表
      _refreshChatRooms();
    }
  }

  // 当依赖变化时（如提供者状态变化）
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 此处也可以考虑刷新，但要注意避免过于频繁的刷新
  }

  // 从导航返回时刷新聊天室列表
  void _refreshChatRooms() {
    // 刷新聊天室列表提供者
    ref.refresh(chatRoomsProvider);

    // 此外还可以通过 ChatNotifier 获取最新聊天室
    ref.read(chatNotifierProvider.notifier).getChatRooms();
  }

  @override
  void dispose() {
    // 清理资源
    WidgetsBinding.instance.removeObserver(this);
    _pageFocusNode.removeListener(_onFocusChange);
    _pageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeConnection() async {
    final socketManager = ref.read(socketConnectionManagerProvider);
    try {
      await socketManager.connect();
      print('初始化Socket连接成功');

      // 显示连接成功消息并自动消失
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已连接到聊天服务器'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('初始化Socket连接失败: $e');

      // 显示连接失败消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: _initializeConnection,
            ),
          ),
        );
      }
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
        title: const Text('连接详情'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('连接状态: ${result['success'] ? '成功' : '失败'}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (result['socketId'] != null)
                Text('Socket ID: ${result['socketId']}'),
              if (result['error'] != null)
                Text('错误: ${result['error']}',
                    style: const TextStyle(color: Colors.red)),
              Text('耗时: ${result['timeTaken']}ms'),
              const Divider(),
              const Text('诊断信息:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildDiagnosticInfoList(info),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
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

  // 创建新聊天室
  void _createNewChatRoom() async {
    // 显示创建聊天室对话框
    final TextEditingController nameController = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建新聊天室'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '聊天室名称',
                hintText: '请输入聊天室名称',
              ),
            ),
            // 可以添加更多选项，如是否私有、选择成员等
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop({
                'name': nameController.text,
                'isPrivate': false,
                'members': <String>[], // 默认空成员列表
              });
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result != null && result['name'].isNotEmpty) {
      final chatNotifier = ref.read(chatNotifierProvider.notifier);

      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 调用创建聊天室
      final newRoom = await chatNotifier.createChatRoom(
        roomName: result['name'],
        isPrivate: result['isPrivate'] ?? false,
        members: result['members'] ?? [],
      );

      // 移除加载指示器
      Navigator.of(context).pop();

      // 处理结果
      if (newRoom != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('聊天室 "${newRoom.name}" 创建成功！')),
        );

        // 修改导航方式并添加返回监听
        final route = MaterialPageRoute(
          builder: (context) =>
              ChatPage(chatRoomId: newRoom.id, chatRoomName: newRoom.name),
        );

        Navigator.push(context, route).then((_) {
          // 当从聊天页面返回时，刷新聊天室列表
          _refreshChatRooms();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建聊天室失败：${chatNotifier.errorMessage}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取用户名
    final userInfo = ref.watch(authInfoProvider);
    final username = userInfo.whenOrNull(
          data: (data) => data['username'] as String?,
        ) ??
        '加载中...';

    // 监听连接状态（仅用于图标显示）
    final connectionState = ref.watch(socketConnectionStatusProvider);
    final isConnected = connectionState.maybeWhen(
      data: (connected) => connected,
      orElse: () => false,
    );

    // 将页面包装在 Focus 小部件中以检测焦点变化
    return Focus(
      focusNode: _pageFocusNode,
      child: Scaffold(
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
                color: isConnected ? Colors.green : Colors.red,
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
              onPressed: _createNewChatRoom,
            ),
            // 测试连接按钮
            IconButton(
              icon: _isTesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.network_check),
              tooltip: '测试连接',
              onPressed: _isTesting ? null : _testConnection,
            ),
            // 用户信息按钮
            IconButton(
              icon: const Icon(Icons.account_circle),
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
            // 显示测试结果（如果有）
            if (_testResult != null)
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
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
                    const Text('连接测试结果:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('状态: ${_testResult!['success'] ? '成功' : '失败'}'),
                    if (_testResult!['socketId'] != null)
                      Text('Socket ID: ${_testResult!['socketId']}'),
                    if (_testResult!['error'] != null)
                      Text('错误: ${_testResult!['error']}',
                          style: const TextStyle(color: Colors.red)),
                    Text('响应时间: ${_testResult!['timeTaken']}ms'),

                    // 查看详情按钮
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showConnectionDetails(_testResult!),
                        child: const Text('查看详情'),
                      ),
                    ),
                  ],
                ),
              ),

            // 内容区域 - 聊天室列表（无论连接状态如何）
            Expanded(
              child: connectionState.when(
                data: (isConnected) {
                  // 总是尝试加载聊天室列表，不再根据连接状态显示不同的内容
                  return _buildChatRoomListContent();
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('连接错误',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('$error'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _initializeConnection,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // 添加创建聊天室的浮动按钮
        floatingActionButton: FloatingActionButton(
          onPressed: _createNewChatRoom,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add_comment),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // 构建聊天室列表内容
  Widget _buildChatRoomListContent() {
    // 监听chatRoomsProvider获取聊天室列表
    final chatRoomsAsync = ref.watch(chatRoomsProvider);

    return chatRoomsAsync.when(
      data: (chatRooms) {
        return _buildChatRoomsList(chatRooms);
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载聊天室列表...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('加载聊天室失败',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => ref.refresh(chatRoomsProvider),
                  child: const Text('重新加载'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _createNewChatRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('创建聊天室'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建聊天室列表
  Widget _buildChatRoomsList(List<ChatRoom> chatRooms) {
    if (chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('暂无聊天室', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewChatRoom,
              icon: const Icon(Icons.add),
              label: const Text('创建聊天室'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // 获取当前选中的聊天室ID
    final currentRoomId = ref.watch(currentChatRoomIdProvider);

    // 按创建时间排序，新创建的排在前面
    final sortedRooms = [...chatRooms];
    sortedRooms.sort(
        (a, b) => (b.createdAt?.compareTo(a.createdAt ?? DateTime.now()) ?? 0));

    return ListView.builder(
      itemCount: sortedRooms.length,
      itemBuilder: (context, index) {
        final room = sortedRooms[index];
        // 检查是否是当前选中的聊天室
        final isSelected = room.id == currentRoomId;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isSelected ? Colors.blue : Colors.blue.shade100,
            child: Text(
              room.name.isNotEmpty
                  ? room.name.substring(0, 1).toUpperCase()
                  : '?',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.blue.shade800,
              ),
            ),
          ),
          title: Text(
            room.name,
            style: isSelected
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
          subtitle: Text('${room.members.length} 位用户'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
          onTap: () {
            // 设置当前选中的聊天室ID
            ref.read(currentChatRoomIdProvider.notifier).state = room.id;

            // 加入聊天室
            ref.read(chatNotifierProvider.notifier).joinRoom(room.id);

            // 导航到聊天页面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChatPage(chatRoomId: room.id, chatRoomName: room.name),
              ),
            );
          },
        );
      },
    );
  }

  void _returnToNative() async {
    try {
      // 调用原生方法，通知原生端即将关闭Flutter视图
      await ChatListPage.platform.invokeMethod('willCloseFlutterView');
      // 关闭Flutter视图
      SystemNavigator.pop();
    } catch (e) {
      print('关闭页面时出错: $e');
      // 即使调用原生方法失败，也尝试关闭Flutter视图
      SystemNavigator.pop();
    }
  }
}
