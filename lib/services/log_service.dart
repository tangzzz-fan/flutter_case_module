import 'dart:async';
import 'package:flutter/services.dart';

enum LogLevel { info, warning, error, debug }

extension LogLevelExtension on LogLevel {
  String get value {
    switch (this) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.debug:
        return 'DEBUG';
    }
  }

  static LogLevel fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INFO':
        return LogLevel.info;
      case 'WARNING':
        return LogLevel.warning;
      case 'ERROR':
        return LogLevel.error;
      case 'DEBUG':
        return LogLevel.debug;
      default:
        return LogLevel.info;
    }
  }
}

class LogEntry {
  final String message;
  final LogLevel level;
  final DateTime timestamp;
  final bool fromNative;

  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
    required this.fromNative,
  });
}

class LogService {
  static const BasicMessageChannel<String> _channel =
      BasicMessageChannel<String>(
    'com.example.swiftflutter/logging',
    StringCodec(),
  );

  // 使用广播流控制器来允许多个监听者
  final _logStreamController = StreamController<LogEntry>.broadcast();

  // 单例模式
  static final LogService _instance = LogService._internal();

  factory LogService() => _instance;

  LogService._internal() {
    _setupMessageHandler();
  }

  // 设置消息处理器来接收来自原生端的日志
  void _setupMessageHandler() {
    _channel.setMessageHandler((String? message) async {
      if (message != null) {
        final parts = message.split(':');
        if (parts.length >= 2) {
          final level = LogLevelExtension.fromString(parts[0]);
          final logMessage = parts.sublist(1).join(':');

          final entry = LogEntry(
            message: logMessage,
            level: level,
            timestamp: DateTime.now(),
            fromNative: true,
          );

          _logStreamController.add(entry);
        }
      }
      return 'Log received in Flutter';
    });
  }

  // 发送日志到原生端
  Future<String?> log(String message, LogLevel level) async {
    final formattedMessage = '${level.value}:$message';

    // 添加到本地日志流
    final entry = LogEntry(
      message: message,
      level: level,
      timestamp: DateTime.now(),
      fromNative: false,
    );
    _logStreamController.add(entry);

    // 发送到原生端
    return _channel.send(formattedMessage);
  }

  // 获取日志流
  Stream<LogEntry> get logStream => _logStreamController.stream;

  // 关闭服务
  void dispose() {
    _logStreamController.close();
  }
}
