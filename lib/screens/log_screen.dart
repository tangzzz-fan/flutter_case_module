import 'dart:async';
import 'package:flutter/material.dart';
import '../services/log_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final LogService _logService = LogService();
  final List<LogEntry> _logs = [];
  final TextEditingController _messageController = TextEditingController();
  LogLevel _selectedLevel = LogLevel.info;
  StreamSubscription<LogEntry>? _subscription;

  @override
  void initState() {
    super.initState();
    _setupLogSubscription();
  }

  void _setupLogSubscription() {
    _subscription = _logService.logStream.listen((entry) {
      setState(() {
        _logs.insert(0, entry);
      });
    });
  }

  Future<void> _sendLog() async {
    if (_messageController.text.isNotEmpty) {
      final response =
          await _logService.log(_messageController.text, _selectedLevel);
      print('原生响应: $response');
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.debug:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志系统 (BasicMessageChannel 演示)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '发送日志',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: '输入日志消息',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<LogLevel>(
                      value: _selectedLevel,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLevel = value;
                          });
                        }
                      },
                      items: LogLevel.values.map((level) {
                        return DropdownMenuItem<LogLevel>(
                          value: level,
                          child: Text(
                            level.value,
                            style: TextStyle(
                              color: _getLevelColor(level),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _sendLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('发送'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    '时间',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '级别',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    '消息',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 80),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final time = log.timestamp;
                final timeString =
                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

                return Container(
                  color: index % 2 == 0 ? Colors.grey.withOpacity(0.1) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(timeString),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            log.level.value,
                            style: TextStyle(
                              color: _getLevelColor(log.level),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(log.message),
                        ),
                        SizedBox(
                          width: 80,
                          child: Chip(
                            label: Text(
                              log.fromNative ? '原生' : 'Flutter',
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: log.fromNative
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
