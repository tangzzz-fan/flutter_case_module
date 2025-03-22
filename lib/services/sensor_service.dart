import 'dart:async';
import 'package:flutter/services.dart';

class SensorData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  SensorData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      x: map['x'],
      y: map['y'],
      z: map['z'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'].toInt()),
    );
  }

  @override
  String toString() => 'x: $x, y: $y, z: $z';
}

class SensorService {
  static const EventChannel _eventChannel =
      EventChannel('com.example.swiftflutter/sensor_events');

  Stream<SensorData>? _accelerometerStream;

  // 使用单例模式
  static final SensorService _instance = SensorService._internal();

  factory SensorService() => _instance;

  SensorService._internal();

  // 获取加速度计数据流
  Stream<SensorData> get accelerometerStream {
    _accelerometerStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => SensorData.fromMap(event));
    return _accelerometerStream!;
  }
}
