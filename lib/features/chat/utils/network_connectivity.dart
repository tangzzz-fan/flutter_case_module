import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkConnectivity {
  final _connectivity = Connectivity();
  final _controller = StreamController<ConnectivityResult>.broadcast();

  StreamSubscription<ConnectivityResult>? _subscription;

  NetworkConnectivity() {
    _init();
  }

  Stream<ConnectivityResult> get connectivityStream => _controller.stream;

  void _init() async {
    // 获取初始连接状态
    ConnectivityResult result = await _connectivity.checkConnectivity();
    _controller.add(result);

    // 监听连接变化
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _controller.add(result);
    });
  }

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

final networkConnectivityProvider = Provider<NetworkConnectivity>((ref) {
  final connectivity = NetworkConnectivity();
  ref.onDispose(() => connectivity.dispose());
  return connectivity;
});

final networkStatusProvider = StreamProvider<bool>((ref) {
  final connectivity = ref.watch(networkConnectivityProvider);
  return connectivity.connectivityStream
      .map((status) => status != ConnectivityResult.none);
});
