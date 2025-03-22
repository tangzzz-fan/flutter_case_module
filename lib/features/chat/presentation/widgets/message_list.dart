import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_ui_providers.dart';
import 'message_item.dart';

class MessageList extends ConsumerWidget {
  final String chatRoomId;
  final ScrollController scrollController;

  const MessageList({
    Key? key,
    required this.chatRoomId,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(chatRoomId));

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Text('还没有消息，发送一条新消息开始聊天吧！'),
          );
        }

        return ListView.builder(
          controller: scrollController,
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
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载消息失败: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(chatMessagesProvider(chatRoomId));
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
