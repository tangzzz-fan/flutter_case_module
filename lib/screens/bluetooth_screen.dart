import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/bluetooth_service.dart';
import 'dart:async';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({Key? key}) : super(key: key);

  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  static const platform = MethodChannel('com.example.swiftflutter/channel');
  final BluetoothService _bluetoothService = BluetoothService();
  BluetoothState _state = BluetoothState.unknown;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  String _lastMessage = '';
  final List<String> _logMessages = [];

  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _bluetoothService.stopScan();
    if (_connectedDevice != null) {
      _bluetoothService.disconnect();
    }
    super.dispose();
  }

  Future<void> _initBluetooth() async {
    try {
      final state = await _bluetoothService.getBluetoothState();
      setState(() {
        _state = state;
      });

      _messageSubscription =
          _bluetoothService.messages.listen(_handleBluetoothMessage);
    } catch (e) {
      _addLogMessage('初始化蓝牙失败: $e');
    }
  }

  void _handleBluetoothMessage(BluetoothMessage message) {
    setState(() {
      _lastMessage = '${message.type}: ${message.data}';
      _addLogMessage('收到消息: ${message.type}');

      switch (message.type) {
        case BluetoothMessageType.STATE_CHANGED:
          _updateBluetoothState();
          break;
        case BluetoothMessageType.SCAN_RESULT:
          _refreshDeviceList();
          break;
        case BluetoothMessageType.CONNECTED:
          _updateConnectedDevice();
          break;
        case BluetoothMessageType.DISCONNECTED:
          setState(() {
            _connectedDevice = null;
          });
          break;
        default:
          break;
      }
    });
  }

  Future<void> _updateBluetoothState() async {
    final state = await _bluetoothService.getBluetoothState();
    setState(() {
      _state = state;
    });
  }

  Future<void> _refreshDeviceList() async {
    final devices = await _bluetoothService.getDevices();
    setState(() {
      _devices = devices;
    });
  }

  Future<void> _updateConnectedDevice() async {
    final devices = await _bluetoothService.getDevices();
    // 连接的设备应该是设备列表中的一个
    // 实际应用中可能需要通过ID匹配
    if (devices.isNotEmpty) {
      setState(() {
        _connectedDevice = devices.first;
      });
    }
  }

  Future<void> _startScan() async {
    if (_state != BluetoothState.ready) {
      _addLogMessage('蓝牙未准备好');
      return;
    }

    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      await _bluetoothService.startScan();
      _addLogMessage('开始扫描');
    } catch (e) {
      _addLogMessage('扫描失败: $e');
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _stopScan() async {
    try {
      await _bluetoothService.stopScan();
      setState(() {
        _isScanning = false;
      });
      _addLogMessage('停止扫描');
    } catch (e) {
      _addLogMessage('停止扫描失败: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      _addLogMessage('正在连接到设备: ${device.name ?? device.id}');
      final success = await _bluetoothService.connect(device.id);
      if (success) {
        _addLogMessage('连接成功');
        setState(() {
          _connectedDevice = device;
        });
      } else {
        _addLogMessage('连接失败');
      }
    } catch (e) {
      _addLogMessage('连接出错: $e');
    }
  }

  Future<void> _disconnect() async {
    try {
      final success = await _bluetoothService.disconnect();
      if (success) {
        _addLogMessage('断开连接成功');
        setState(() {
          _connectedDevice = null;
        });
      } else {
        _addLogMessage('断开连接失败');
      }
    } catch (e) {
      _addLogMessage('断开连接出错: $e');
    }
  }

  void _addLogMessage(String message) {
    setState(() {
      _logMessages.insert(
          0, '${DateTime.now().toString().substring(11, 19)} $message');
      if (_logMessages.length > 100) {
        _logMessages.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('蓝牙'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.clear),
          onPressed: () {
            _returnToNative();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.search),
            onPressed: _isScanning ? _stopScan : _startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStateCard(),
          _buildDeviceList(),
          _buildLogPanel(),
        ],
      ),
    );
  }

  Widget _buildStateCard() {
    String stateText = '未知';
    Color stateColor = Colors.grey;

    switch (_state) {
      case BluetoothState.ready:
        stateText = '已就绪';
        stateColor = Colors.green;
        break;
      case BluetoothState.disabled:
        stateText = '已禁用';
        stateColor = Colors.red;
        break;
      case BluetoothState.unauthorized:
        stateText = '未授权';
        stateColor = Colors.orange;
        break;
      case BluetoothState.unsupported:
        stateText = '不支持';
        stateColor = Colors.red;
        break;
      case BluetoothState.resetting:
        stateText = '重置中';
        stateColor = Colors.amber;
        break;
      case BluetoothState.unknown:
      default:
        stateText = '未知';
        stateColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.bluetooth, color: stateColor),
                const SizedBox(width: 8),
                Text('蓝牙状态: $stateText',
                    style: TextStyle(
                        color: stateColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (_connectedDevice != null) ...[
              Row(
                children: [
                  const Icon(Icons.link, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                      '已连接: ${_connectedDevice!.name ?? _connectedDevice!.id}'),
                  const Spacer(),
                  TextButton(
                    onPressed: _disconnect,
                    child: const Text('断开'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
            if (_lastMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('最新消息: $_lastMessage', style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(8),
        child: _isScanning && _devices.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  final isConnected = _connectedDevice?.id == device.id;

                  return ListTile(
                    leading: Icon(
                      Icons.bluetooth,
                      color: isConnected ? Colors.blue : Colors.grey,
                    ),
                    title: Text(device.name ?? '未命名设备'),
                    subtitle: Text('ID: ${device.id.substring(0, 8)}...'),
                    trailing: Text('RSSI: ${device.rssi ?? 'N/A'}'),
                    onTap: isConnected ? null : () => _connectToDevice(device),
                    tileColor:
                        isConnected ? Colors.blue.withOpacity(0.1) : null,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildLogPanel() {
    return Container(
      height: 150,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        reverse: true,
        itemCount: _logMessages.length,
        itemBuilder: (context, index) {
          return Text(
            _logMessages[index],
            style: const TextStyle(color: Colors.green, fontSize: 12),
          );
        },
      ),
    );
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
