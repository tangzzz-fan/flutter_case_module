import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/connection_diagnostics.dart';
import '../../data/providers/chat_data_providers.dart';

class NetworkDiagnosticWidget extends ConsumerStatefulWidget {
  final VoidCallback onRetry;
  final String error;

  const NetworkDiagnosticWidget({
    Key? key,
    required this.onRetry,
    required this.error,
  }) : super(key: key);

  @override
  ConsumerState<NetworkDiagnosticWidget> createState() =>
      _NetworkDiagnosticWidgetState();
}

class _NetworkDiagnosticWidgetState
    extends ConsumerState<NetworkDiagnosticWidget> {
  String _diagnosticResult = '正在进行网络诊断...';
  bool _isDiagnosing = true;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isDiagnosing = true;
      _diagnosticResult = '正在进行网络诊断...';
    });

    try {
      final serverUrl = ref.read(serverUrlProvider);
      final results = await ConnectionDiagnostics.runDiagnostics(serverUrl);
      final report = ConnectionDiagnostics.generateReport(results);

      setState(() {
        _diagnosticResult = report;
        _isDiagnosing = false;
      });
    } catch (e) {
      setState(() {
        _diagnosticResult = '诊断过程中出错: $e';
        _isDiagnosing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.network_check,
            size: 48.0,
            color: Colors.orange,
          ),
          const SizedBox(height: 16.0),
          Text(
            '连接失败',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8.0),
          Text(
            '无法连接到聊天服务器: ${widget.error}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '诊断信息:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                _isDiagnosing
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Text(_diagnosticResult),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _runDiagnostics,
                icon: const Icon(Icons.refresh),
                label: const Text('重新诊断'),
              ),
              const SizedBox(width: 16.0),
              ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.repeat),
                label: const Text('重试连接'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
