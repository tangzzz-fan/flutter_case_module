import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../router/app_router.dart';
import 'package:flutter/cupertino.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'bluetooth_screen.dart';
import 'index_screen.dart';
import 'chat_list_screen.dart';

/// 主页面容器，包含底部标签栏和各个标签页
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.example.swiftflutter/channel');
  String _message = '等待来自 iOS 的消息';
  int _currentIndex = 0;

  // 定义标签页
  final List<Widget> _tabs = [
    const IndexScreen(),
    const ChatListScreen(),
    const BluetoothScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'sendMessageToFlutter':
          setState(() {
            _message = call.arguments;
          });
          return '消息已成功接收';
        case 'willCloseFromNative':
          print('收到原生端关闭通知');
          return '已收到关闭通知';
        default:
          throw PlatformException(
            code: 'NOT_IMPLEMENTED',
            message: '方法 ${call.method} 未实现',
          );
      }
    });
  }

  void _sendMessageToNative() async {
    try {
      final result = await platform.invokeMethod(
        'sendMessageToNative',
        '来自 Flutter 的消息: ${DateTime.now()}',
      );
      print('iOS 响应: $result');
    } on PlatformException catch (e) {
      print('发送消息失败: ${e.message}');
    }
  }

  /// 返回到原生页面
  void _returnToNative() async {
    try {
      await platform.invokeMethod('willCloseFlutterView');
      SystemNavigator.pop();
    } catch (e) {
      print('关闭页面时出错: $e');
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用 IndexedStack 保持各个标签页的状态
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      // 使用 CupertinoTabBar 实现 iOS 风格的底部导航栏
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: _currentIndex,
        activeColor: CupertinoColors.activeBlue,
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble),
            label: '消息',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bluetooth),
            label: '蓝牙',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: '个人中心',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
