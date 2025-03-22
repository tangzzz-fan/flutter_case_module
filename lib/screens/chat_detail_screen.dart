import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/chat/domain/entities/chat_room.dart';
import '../features/chat/domain/entities/message.dart';
import '../features/chat/presentation/providers/chat_provider.dart';
import '../features/chat/presentation/widgets/message_item.dart';
import '../features/chat/presentation/widgets/chat_input.dart';

class ChatDetailScreen extends ConsumerWidget {
  final ChatRoom chatRoom;

  const ChatDetailScreen({
    Key? key,
    required this.chatRoom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取历史消息
    final historicalMessagesAsync =
        ref.watch(historicalMessagesProvider(chatRoom.id));

    // 获取实时消息流
    final messagesAsync = ref.watch(messagesProvider(chatRoom.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(chatRoom.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (chatRoom.isGroup)
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () {
                // 显示群组成员列表
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // 显示更多选项菜单
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: historicalMessagesAsync.when(
              data: (historicalMessages) {
                return messagesAsync.when(
                  data: (realtimeMessages) {
                    // 合并历史消息和实时消息
                    final allMessages = [
                      ...historicalMessages,
                      ...realtimeMessages
                    ];

                    if (allMessages.isEmpty) {
                      return const Center(
                        child: Text('没有消息记录，开始聊天吧'),
                      );
                    }

                    // 按时间排序
                    allMessages
                        .sort((a, b) => a.timestamp.compareTo(b.timestamp));

                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: allMessages.length,
                      itemBuilder: (context, index) {
                        final message = allMessages[index];
                        // 判断是否是当前用户发送的消息
                        final isCurrentUser = message.senderId == 'me';
                        return MessageItem(
                          message: message,
                          isCurrentUser: isCurrentUser,
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: historicalMessages.length,
                      itemBuilder: (context, index) {
                        final message = historicalMessages[index];
                        final isCurrentUser = message.senderId == 'me';
                        return MessageItem(
                          message: message,
                          isCurrentUser: isCurrentUser,
                        );
                      },
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Text('加载实时消息失败: $error'),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('加载历史消息失败: $error'),
              ),
            ),
          ),

          // 输入框
          ChatInput(
            onSendMessage: (content) {
              _sendMessage(ref, content);
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage(WidgetRef ref, String content) {
    if (content.isEmpty) return;

    final sendMessage = ref.read(sendMessageProvider);
    sendMessage.execute(chatRoom.id, content, MessageType.text);
  }
}
