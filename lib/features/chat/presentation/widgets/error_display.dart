import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/connection_diagnostics.dart';

// 服务器URL的Provider
final serverUrlProvider = Provider<String>((ref) => 'ws://localhost:6000');

class ErrorDisplay extends ConsumerWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isConnectionError;

  const ErrorDisplay({
    Key? key,
    required this.message,
    this.onRetry,
    this.isConnectionError = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnectionError ? Icons.signal_wifi_off : Icons.error_outline,
              size: 48,
              color: isConnectionError ? Colors.orange : Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              isConnectionError ? '连接问题' : '出错了',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color:
                      isConnectionError ? Colors.orange[700] : Colors.red[700]),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(isConnectionError ? '重新连接' : '重试'),
              ),
            ],
            if (isConnectionError) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.bug_report),
                label: const Text('连接诊断'),
                onPressed: () async {
                  // 显示诊断中对话框
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      title: Text('诊断中...'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('正在检查网络连接问题，请稍候...')
                        ],
                      ),
                    ),
                  );

                  // 运行诊断 - 从Riverpod读取serverUrl
                  final serverUrl = ref.read(serverUrlProvider);
                  final diagnostics =
                      await ConnectionDiagnostics.runDiagnostics(serverUrl);
                  final report =
                      ConnectionDiagnostics.generateReport(diagnostics);

                  // 关闭诊断中对话框
                  Navigator.of(context).pop();

                  // 显示诊断结果
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('连接诊断结果'),
                      content: SingleChildScrollView(
                        child: SelectableText(report), // 使用SelectableText允许用户复制
                      ),
                      actions: [
                        TextButton(
                          child: const Text('关闭'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        TextButton(
                          child: const Text('复制'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: report));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('诊断报告已复制到剪贴板')),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              TextButton(
                onPressed: () {
                  // 显示网络诊断帮助
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('连接问题解决方案'),
                      content: const SingleChildScrollView(
                        child: ListBody(
                          children: [
                            Text('1. 确认你的网络连接正常'),
                            Text('2. 服务器地址可能错误，请检查配置'),
                            Text('3. 服务器可能未开启或无法访问'),
                            Text('4. 如果使用WiFi，尝试切换到移动数据'),
                            Text('5. 尝试重启应用'),
                            Text('6. 检查是否有防火墙或网络限制'),
                            Text('7. 查看诊断报告以获取更多信息'),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: const Text('关闭'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('连接帮助'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
