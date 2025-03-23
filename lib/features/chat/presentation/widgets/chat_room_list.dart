import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_room.dart';
import '../providers/chat_ui_providers.dart';
import 'error_display.dart';

/// 聊天室列表组件
///
/// 显示可用的聊天室列表，并允许用户选择一个进入
class ChatRoomList extends ConsumerWidget {
  const ChatRoomList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);

    return chatRoomsAsync.when(
      data: (chatRooms) {
        if (chatRooms.isEmpty) {
          return const Center(
            child: Text('暂无可用的聊天室'),
          );
        }

        return ListView.builder(
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            final chatRoom = chatRooms[index];
            return _buildChatRoomItem(context, chatRoom, ref);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => ErrorDisplay(
        message: '无法加载聊天室: $error',
        onRetry: () {
          // 刷新聊天室列表
          ref.invalidate(chatRoomsProvider);
        },
      ),
    );
  }

  Widget _buildChatRoomItem(
      BuildContext context, ChatRoom chatRoom, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Icon(
          chatRoom.isGroup == true ? Icons.group : Icons.person,
          color: Colors.blue,
        ),
      ),
      title: Text(chatRoom.name),
      subtitle: chatRoom.description != null
          ? Text(
              chatRoom.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: chatRoom.unreadCount != null && chatRoom.unreadCount! > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                chatRoom.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            )
          : null,
      onTap: () {
        // 设置当前选中的聊天室
        ref.read(currentChatRoomIdProvider.notifier).state = chatRoom.id;

        // 导航到聊天页面
        Navigator.pushNamed(
          context,
          '/chat/room/${chatRoom.id}',
          arguments: {
            'chatRoomName': chatRoom.name,
          },
        );
      },
    );
  }
}
