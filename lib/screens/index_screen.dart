import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../router/app_router.dart';

/// 案例索引页面 - 展示所有可用的功能演示
class IndexScreen extends StatelessWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('功能演示'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.clear),
          onPressed: () {
            final methodChannel =
                const MethodChannel('com.example.swiftflutter/channel');
            _returnToNative(methodChannel);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('基础功能'),
          _buildDemoItem(
            icon: Icons.article,
            title: '详情页面',
            description: '基本页面导航与参数传递演示',
            onTap: () => AppRouter.navigateToDetail(context, '1'),
          ),
          _buildDemoItem(
            icon: Icons.sensors,
            title: '传感器演示',
            description: '访问设备传感器数据',
            onTap: () => AppRouter.navigateToSensorDemo(context),
          ),
          _buildDemoItem(
            icon: Icons.format_align_left,
            title: '日志演示',
            description: '查看应用日志记录',
            onTap: () => AppRouter.navigateToLogDemo(context),
          ),
          _buildSectionHeader('硬件交互'),
          _buildDemoItem(
            icon: Icons.bluetooth,
            title: '蓝牙连接',
            description: '扫描并连接蓝牙设备',
            onTap: () => AppRouter.navigateToBluetooth(context),
          ),
          _buildDemoItem(
            icon: Icons.camera_alt,
            title: '相机访问',
            description: '拍照和图片选择功能',
            onTap: () => _showFeatureComingSoon(context),
          ),
          _buildDemoItem(
            icon: Icons.location_on,
            title: '位置服务',
            description: '获取当前位置和地图功能',
            onTap: () => _showFeatureComingSoon(context),
          ),
          _buildSectionHeader('原生交互'),
          _buildDemoItem(
            icon: Icons.message,
            title: 'Native通信',
            description: '与原生代码进行数据交换',
            onTap: () => _showNativeCommunicationDemo(context),
          ),
          _buildDemoItem(
            icon: Icons.notifications,
            title: '推送通知',
            description: '接收和处理推送通知',
            onTap: () => _showFeatureComingSoon(context),
          ),
          _buildSectionHeader('UI组件'),
          _buildDemoItem(
            icon: Icons.view_list,
            title: '下拉刷新',
            description: '列表刷新和加载更多',
            onTap: () => _showFeatureComingSoon(context),
          ),
          _buildDemoItem(
            icon: Icons.graphic_eq,
            title: '动画效果',
            description: '各种UI动画演示',
            onTap: () => _showFeatureComingSoon(context),
          ),
          _buildDemoItem(
            icon: Icons.dark_mode,
            title: '主题切换',
            description: '明暗主题和动态颜色',
            onTap: () => _showFeatureComingSoon(context),
          ),
        ],
      ),
    );
  }

  /// 构建分区标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  /// 构建演示项目卡片
  Widget _buildDemoItem({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  /// 显示即将推出的功能提示
  void _showFeatureComingSoon(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('功能开发中'),
        content: const Text('该功能正在开发中，敬请期待！'),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// 显示原生通信演示对话框
  void _showNativeCommunicationDemo(BuildContext context) {
    final methodChannel =
        const MethodChannel('com.example.swiftflutter/channel');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('原生通信演示'),
        content: const Text('点击下方按钮向原生代码发送消息'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await methodChannel.invokeMethod(
                  'sendMessageToNative',
                  '来自 Flutter 的消息: ${DateTime.now()}',
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('原生响应: $result')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('发送失败: $e')),
                  );
                }
              }
            },
            child: const Text('发送消息'),
          ),
        ],
      ),
    );
  }

  /// 返回原生页面的方法
  void _returnToNative(MethodChannel platform) async {
    try {
      await platform.invokeMethod('willCloseFlutterView');
      SystemNavigator.pop();
    } catch (e) {
      print('关闭页面时出错: $e');
      SystemNavigator.pop();
    }
  }
}
