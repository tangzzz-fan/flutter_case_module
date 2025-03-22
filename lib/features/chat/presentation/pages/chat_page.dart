import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/chat_data_providers.dart';
import '../../utils/network_connectivity.dart';
import '../providers/chat_ui_providers.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_item.dart';
import '../../domain/entities/message.dart';
import '../widgets/error_display.dart';
import '../../domain/entities/chat_state.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String chatRoomId;
  final String chatRoomName;

  const ChatPage({
    Key? key,
    required this.chatRoomId,
    required this.chatRoomName,
  }) : super(key: key);

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _isFirstBuild = true;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 统一使用 chatNotifierProvider 进行连接
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 只使用一种方式初始化连接
      ref.read(chatNotifierProvider.notifier).connect();

      // 设置网络状态监听
      _checkAndHandleNetworkChange(null, ref.read(networkStatusProvider));
    });
  }

  // 网络状态变化处理逻辑
  void _checkAndHandleNetworkChange(
      AsyncValue<bool>? previous, AsyncValue<bool> current) {
    current.whenData((hasNetwork) {
      if (hasNetwork && previous != null) {
        final previousHasNetwork =
            previous.maybeWhen(data: (value) => value, orElse: () => false);

        // 只有在网络从无到有变化时，才尝试重连
        if (!previousHasNetwork) {
          print('网络恢复，尝试重新连接...');
          // 统一使用 chatNotifierProvider 进行重连
          ref.read(chatNotifierProvider.notifier).connect();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 当应用从后台恢复时，检查网络状态并尝试重连
    if (state == AppLifecycleState.resumed) {
      _checkAndHandleNetworkChange(null, ref.read(networkStatusProvider));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // 滚动到底部的方法
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstBuild) {
      _isFirstBuild = false;
    }

    // 网络状态监听
    ref.listen<AsyncValue<bool>>(
        networkStatusProvider, _checkAndHandleNetworkChange);

    // 获取消息列表
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatRoomId));

    // 监听实时消息流
    ref.listen<AsyncValue<Message>>(messageStreamProvider, (_, messageAsync) {
      messageAsync.whenData((message) {
        // 如果收到的消息属于当前聊天室，刷新消息列表
        if (message.senderId == widget.chatRoomId ||
            message.receiverId == widget.chatRoomId) {
          ref.invalidate(chatMessagesProvider(widget.chatRoomId));

          // 滚动到底部显示新消息
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      });
    });

    // 使用 riverpod 监听 ChatNotifier 的连接状态
    final chatState = ref.watch(chatNotifierProvider);
    final isConnected =
        chatState.connectionStatus == ConnectionStatus.connected;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.chatRoomName),
            if (!isConnected)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.cloud_off, size: 16, color: Colors.red),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // 设置用户名对话框
              final textController = TextEditingController(
                text: ref.read(tempUsernameProvider),
              );

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('设置用户名'),
                  content: TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      hintText: '输入聊天用户名',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        final newUsername = textController.text.trim();
                        if (newUsername.isNotEmpty) {
                          // 更新用户名
                          ref.read(tempUsernameProvider.notifier).state =
                              newUsername;

                          // 更新Socket连接管理器的认证信息
                          final manager =
                              ref.read(socketConnectionManagerProvider);
                          manager.updateAuthInfo({'username': newUsername});

                          // 通过Riverpod的方式尝试重连
                          ref.read(chatNotifierProvider.notifier).connect();
                        }
                        Navigator.of(context).pop();
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // 聊天设置菜单
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 连接状态提示
          if (!isConnected)
            Container(
              color: Colors.red.shade100,
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '连接已断开，部分功能可能不可用。',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    child: const Text('重新连接'),
                    onPressed: () {
                      ref.read(chatNotifierProvider.notifier).connect();
                    },
                  ),
                ],
              ),
            ),

          // 消息列表
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                // 数据加载完成后滚动到底部
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('还没有消息，发送一条新消息开始聊天吧！'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == 'me'; // 假设'me'是当前用户ID

                    return MessageItem(
                      message: message,
                      isCurrentUser: isMe,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorDisplay(
                message: error.toString(),
                isConnectionError: error.toString().contains('Connection'),
                onRetry: () {
                  // 先尝试重新连接
                  ref.read(chatNotifierProvider.notifier).connect();
                  // 然后刷新消息
                  ref.invalidate(chatMessagesProvider(widget.chatRoomId));
                },
              ),
            ),
          ),

          // 消息输入框
          ChatInput(chatRoomId: widget.chatRoomId),
        ],
      ),
    );
  }
}
