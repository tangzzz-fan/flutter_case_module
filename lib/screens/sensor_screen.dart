import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sensor_service.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({Key? key}) : super(key: key);

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final SensorService _sensorService = SensorService();
  StreamSubscription<SensorData>? _subscription;
  SensorData? _latestData;
  List<String> _dataLog = [];

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _subscription =
        _sensorService.accelerometerStream.listen((SensorData data) {
      setState(() {
        _latestData = data;
        _addToLog(data);
      });
    }, onError: (dynamic error) {
      setState(() {
        _dataLog.insert(0, '错误: ${error.toString()}');
      });
    });
  }

  void _addToLog(SensorData data) {
    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute}:${now.second}';
    _dataLog.insert(0, '$timeStr - ${data.toString()}');

    // 只保留最近20条记录
    if (_dataLog.length > 20) {
      _dataLog.removeLast();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('传感器数据 (EventChannel 演示)'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前加速度计读数',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_latestData != null) ...[
                      Text('X轴: ${_latestData!.x.toStringAsFixed(4)}'),
                      Text('Y轴: ${_latestData!.y.toStringAsFixed(4)}'),
                      Text('Z轴: ${_latestData!.z.toStringAsFixed(4)}'),
                    ] else
                      const Text('等待数据...'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '数据日志',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _dataLog.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      _dataLog[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: index == 0 ? Colors.blue : Colors.black87,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
