import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// 聊天会话列表页面
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  static const platform = MethodChannel('com.example.swiftflutter/channel');

  // 模拟的聊天会话数据
  final List<ChatSession> _chatSessions = [
    ChatSession(
      id: '1',
      name: '张三',
      avatar: 'https://randomuser.me/api/portraits/men/1.jpg',
      lastMessage: '明天我们在公司见面讨论项目进展',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
    ),
    ChatSession(
      id: '2',
      name: '李四',
      avatar: 'https://randomuser.me/api/portraits/women/2.jpg',
      lastMessage: '好的，我已经收到文件了，谢谢！',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 0,
    ),
    ChatSession(
      id: '3',
      name: '项目组',
      avatar: 'https://randomuser.me/api/portraits/men/3.jpg',
      lastMessage: '王五: 我已经完成了UI设计稿，请大家查收',
      time: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 5,
    ),
    ChatSession(
      id: '4',
      name: '技术支持',
      avatar: 'https://randomuser.me/api/portraits/women/4.jpg',
      lastMessage: '您的问题已经解决了吗？需要进一步帮助吗？',
      time: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
    ),
    ChatSession(
      id: '5',
      name: '市场部',
      avatar: 'https://randomuser.me/api/portraits/men/5.jpg',
      lastMessage: '下周一我们将举行新产品发布会，请各位准备相关材料',
      time: DateTime.now().subtract(const Duration(days: 2)),
      unreadCount: 0,
    ),
    ChatSession(
      id: '6',
      name: '赵六',
      avatar: 'https://randomuser.me/api/portraits/women/6.jpg',
      lastMessage: '[图片]',
      time: DateTime.now().subtract(const Duration(days: 3)),
      unreadCount: 0,
    ),
    ChatSession(
      id: '7',
      name: '人力资源',
      avatar: 'https://randomuser.me/api/portraits/men/7.jpg',
      lastMessage: '请查收本月工资条',
      time: DateTime.now().subtract(const Duration(days: 5)),
      unreadCount: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: ListView.separated(
        itemCount: _chatSessions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final session = _chatSessions[index];
          return _buildChatSessionItem(session);
        },
      ),
    );
  }

  Widget _buildChatSessionItem(ChatSession session) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(session.avatar),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              session.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(session.time),
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
              session.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: session.unreadCount > 0
                    ? Colors.black87
                    : Colors.grey.shade600,
              ),
            ),
          ),
          if (session.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                session.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // 处理点击聊天会话的事件
        print('点击了聊天会话：${session.name}');
      },
    );
  }

  /// 格式化时间显示
  String _formatTime(DateTime time) {
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

/// 聊天会话数据模型
class ChatSession {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final DateTime time;
  final int unreadCount;

  ChatSession({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
  });
}
