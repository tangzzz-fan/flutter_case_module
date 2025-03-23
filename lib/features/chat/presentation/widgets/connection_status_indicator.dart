import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/chat_data_providers.dart';
import '../../data/datasources/socket_connection_manager.dart';

/// 连接状态指示器组件
///
/// 显示当前Socket连接状态，并允许通过点击触发重连
class ConnectionStatusIndicator extends ConsumerStatefulWidget {
  const ConnectionStatusIndicator({Key? key}) : super(key: key);

  @override
  ConsumerState<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState
    extends ConsumerState<ConnectionStatusIndicator> {
  bool _isTesting = false;
  Map<String, dynamic>? _testResult;

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(socketConnectionStatusProvider);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: connectionState.when(
          data: (isConnected) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      isConnected ? Icons.check_circle : Icons.error_outline,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? '连接状态: 已连接' : '连接状态: 未连接',
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (!isConnected)
                      TextButton(
                        onPressed: () {
                          final manager =
                              ref.read(socketConnectionManagerProvider);
                          manager.connect();
                        },
                        child: const Text('重新连接'),
                      ),
                    IconButton(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: const Icon(Icons.health_and_safety),
                      tooltip: '测试连接',
                    ),
                  ],
                ),

                // 显示测试结果
                if (_testResult != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('连接测试结果:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('成功: ${_testResult!['success']}'),
                        if (_testResult!.containsKey('error'))
                          Text('错误: ${_testResult!['error']}',
                              style: TextStyle(color: Colors.red)),
                        if (_testResult!.containsKey('socketId'))
                          Text('Socket ID: ${_testResult!['socketId']}'),
                        Text('耗时: ${_testResult!['timeTaken']}ms'),

                        // 显示诊断信息
                        const SizedBox(height: 8),
                        const Text('连接诊断:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        _buildDiagnosticInfo(),
                      ],
                    ),
                  ),

                if (_isTesting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('连接错误: $error'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 测试连接方法
  Future<void> _testConnection() async {
    final manager = ref.read(socketConnectionManagerProvider);

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      // 获取诊断信息
      final diagnosticInfo = manager.getDiagnosticInfo();
      print('💻 诊断信息: $diagnosticInfo');

      // 测试连接
      final result = await manager.testConnection();
      print('🔍 连接测试结果: $result');

      setState(() {
        _testResult = result;
        _isTesting = false;
      });
    } catch (e) {
      print('❌ 测试连接时出错: $e');
      setState(() {
        _testResult = {
          'success': false,
          'error': '测试过程异常: $e',
          'timeTaken': 0,
        };
        _isTesting = false;
      });
    }
  }

  // 构建诊断信息显示
  Widget _buildDiagnosticInfo() {
    final manager = ref.read(socketConnectionManagerProvider);
    final info = manager.getDiagnosticInfo();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Socket初始化: ${info['socketInitialized']}'),
        Text('Socket ID: ${info['socketId'] ?? '无'}'),
        Text('连接状态: ${info['isConnected']}'),
        Text('初始化中: ${info['isInitializing']}'),
        Text('重连尝试: ${info['reconnectAttempts']}'),
        Text('服务器URL: ${info['serverUrl']}'),
        Text('传输类型: ${info['transportType'] ?? '未知'}'),
        Text('引擎状态: ${info['engineState'] ?? '未知'}'),
      ],
    );
  }
}
