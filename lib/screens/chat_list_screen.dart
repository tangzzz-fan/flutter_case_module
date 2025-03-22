import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/chat/presentation/providers/chat_ui_providers.dart';
import '../features/chat/presentation/widgets/chat_room_item.dart';
import '../features/chat/domain/entities/chat_room.dart';
import 'chat_detail_screen.dart';

/// 聊天会话列表页面
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  static const platform = MethodChannel('com.example.swiftflutter/channel');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(chatConnectionStateProvider);
    final isConnected = connectionState.maybeWhen(
      data: (connected) => connected,
      orElse: () => false,
    );

    final chatRoomsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
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
            onPressed: () {
              // 实现新建聊天功能
            },
          ),
        ],
      ),
      body: chatRoomsAsync.when(
        data: (chatRooms) {
          if (chatRooms.isEmpty) {
            return const Center(
              child: Text('没有聊天记录，开始新的对话吧'),
            );
          }

          return ListView.separated(
            itemCount: chatRooms.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return ChatRoomItem(
                chatRoom: chatRoom,
                onTap: () => _navigateToChatDetail(context, ref, chatRoom),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('加载失败: $error'),
        ),
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
    try {
      await platform.invokeMethod('willCloseFlutterView');
      SystemNavigator.pop();
    } catch (e) {
      print('关闭页面时出错: $e');
      SystemNavigator.pop();
    }
  }
}
