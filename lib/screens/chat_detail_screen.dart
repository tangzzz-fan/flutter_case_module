import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/chat/presentation/pages/chat_page.dart';

class ChatDetailScreen extends ConsumerWidget {
  final String chatId;
  final String chatName;

  const ChatDetailScreen(
      {Key? key, required this.chatId, required this.chatName})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 委托给新的ChatPage实现
    return ChatPage(
      chatRoomId: chatId,
      chatRoomName: chatName,
    );
  }
}
