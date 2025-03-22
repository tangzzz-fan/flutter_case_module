import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';

enum BluetoothState {
  unknown,
  resetting,
  unsupported,
  unauthorized,
  disabled,
  ready,
}

enum BluetoothMessageType {
  STATE_CHANGED,
  SCAN_STARTED,
  SCAN_STOPPED,
  SCAN_RESULT,
  CONNECTING,
  CONNECTED,
  DISCONNECTING,
  DISCONNECTED,
  DATA_RECEIVED,
  DATA_SENT,
  NOTIFICATION,
  ERROR,
}

class BluetoothMessage {
  final BluetoothMessageType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  BluetoothMessage({
    required this.type,
    this.data,
    required this.timestamp,
  });

  factory BluetoothMessage.fromJson(Map<String, dynamic> json) {
    return BluetoothMessage(
      type: BluetoothMessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => BluetoothMessageType.ERROR,
      ),
      data: json['data'] != null ? jsonDecode(json['data']) : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}

class BluetoothDevice {
  final String id;
  final String? name;
  final int? rssi;
  final bool hasName;

  BluetoothDevice({
    required this.id,
    this.name,
    this.rssi,
    required this.hasName,
  });

  factory BluetoothDevice.fromJson(Map<String, dynamic> json) {
    return BluetoothDevice(
      id: json['id'],
      name: json['name'],
      rssi: json['rssi'],
      hasName: json['hasName'] ?? false,
    );
  }
}

class BluetoothService {
  static const MethodChannel _channel =
      MethodChannel('com.example.swiftflutter/bluetooth');

  // 消息流控制器
  final _messageStreamController =
      StreamController<BluetoothMessage>.broadcast();

  // 构造函数中设置方法通道处理程序
  BluetoothService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  // 处理从Native端接收的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onBluetoothMessage') {
      final jsonString = call.arguments as String;
      final json = jsonDecode(jsonString);
      final message = BluetoothMessage.fromJson(json);
      _messageStreamController.add(message);
    }
    return null;
  }

  // 监听蓝牙消息
  Stream<BluetoothMessage> get messages => _messageStreamController.stream;

  // 在不再需要时关闭控制器
  void dispose() {
    _messageStreamController.close();
  }

  // 获取蓝牙状态
  Future<BluetoothState> getBluetoothState() async {
    final state = await _channel.invokeMethod<String>('getBluetoothState');
    return BluetoothState.values.firstWhere(
      (e) => e.toString().split('.').last == state,
      orElse: () => BluetoothState.unknown,
    );
  }

  // 开始扫描
  Future<bool> startScan({List<String>? serviceUuids}) async {
    return await _channel.invokeMethod<bool>('startScan', serviceUuids) ??
        false;
  }

  // 停止扫描
  Future<bool> stopScan() async {
    return await _channel.invokeMethod<bool>('stopScan') ?? false;
  }

  // 获取扫描到的设备
  Future<List<BluetoothDevice>> getDevices() async {
    final devices = await _channel.invokeMethod<List<dynamic>>('getDevices');
    return devices
            ?.map((e) => BluetoothDevice.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
  }

  // 连接设备
  Future<bool> connect(String deviceId) async {
    return await _channel.invokeMethod<bool>('connect', deviceId) ?? false;
  }

  // 断开连接
  Future<bool> disconnect() async {
    return await _channel.invokeMethod<bool>('disconnect') ?? false;
  }

  // 读取特征值
  Future<String> readCharacteristic(
      String serviceUuid, String characteristicUuid) async {
    return await _channel.invokeMethod<String>('readCharacteristic', {
          'serviceUuid': serviceUuid,
          'characteristicUuid': characteristicUuid,
        }) ??
        '';
  }

  // 写入特征值
  Future<bool> writeCharacteristic(
    String serviceUuid,
    String characteristicUuid,
    String data, {
    bool withResponse = true,
  }) async {
    return await _channel.invokeMethod<bool>('writeCharacteristic', {
          'serviceUuid': serviceUuid,
          'characteristicUuid': characteristicUuid,
          'data': data,
          'withResponse': withResponse,
        }) ??
        false;
  }

  // 设置通知
  Future<bool> setNotification(
    String serviceUuid,
    String characteristicUuid,
    bool enable,
  ) async {
    return await _channel.invokeMethod<bool>('setNotification', {
          'serviceUuid': serviceUuid,
          'characteristicUuid': characteristicUuid,
          'enable': enable,
        }) ??
        false;
  }
}
