import 'package:flutter/material.dart';
import '../../domain/entities/chat_room.dart';

class ChatRoomItem extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;

  const ChatRoomItem({
    Key? key,
    required this.chatRoom,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 25,
        backgroundImage:
            chatRoom.members.isNotEmpty && chatRoom.members[0].avatar != null
                ? NetworkImage(chatRoom.members[0].avatar!)
                : null,
        child: chatRoom.members.isEmpty || chatRoom.members[0].avatar == null
            ? Text(chatRoom.name.substring(0, 1).toUpperCase())
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chatRoom.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(chatRoom.lastMessage?.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              chatRoom.lastMessage?.content ?? '无消息',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chatRoom.unreadCount != null && chatRoom.unreadCount! > 0
                    ? Colors.black87
                    : Colors.grey.shade600,
              ),
            ),
          ),
          if (chatRoom.unreadCount != null && chatRoom.unreadCount! > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                chatRoom.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${time.month}-${time.day}';
    }
  }
}
