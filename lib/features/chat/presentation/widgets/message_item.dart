import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';

class MessageItem extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const MessageItem({
    Key? key,
    required this.message,
    this.isCurrentUser = true, // 假设已知当前用户
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            CircleAvatar(
              radius: 16,
              child: Text(message.senderId.substring(0, 1).toUpperCase()),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isCurrentUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade700,
              child: const Text('我', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
