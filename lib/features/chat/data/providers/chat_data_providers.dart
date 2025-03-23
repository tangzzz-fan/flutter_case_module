import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

import '../../presentation/providers/chat_ui_providers.dart';
import '../repositories/chat_repository_impl.dart';
import '../datasources/chat_socket_datasource.dart';
import '../datasources/chat_local_datasource.dart';
import '../datasources/chat_remote_datasource.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/socket_connection_manager.dart';
import 'auth_providers.dart';
import '../datasources/chat_remote_http_datasource.dart';
import '../datasources/mock_chat_remote_datasource.dart';

// 服务器地址配置
final serverUrlProvider = Provider<String>((ref) {
  const environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  switch (environment) {
    case 'prod':
      return "https://api.yourcompany.com";
    case 'staging':
      return "https://staging-api.yourcompany.com";
    case 'dev':
    default:
      // 对于iOS模拟器
      if (Platform.isIOS) {
        return "http://localhost:6000";
      }
      // 对于Android模拟器
      else if (Platform.isAndroid) {
        return "http://10.0.2.2:6000"; // Android模拟器特殊IP
      }
      // 对于Web或其他平台
      else {
        return "http://localhost:6000";
      }
  }
});

// 共享首选项提供者
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('应在应用程序启动时使用 override 提供 SharedPreferences 实例');
});

// Socket.IO 连接管理器提供者
final socketConnectionManagerProvider =
    Provider<SocketConnectionManager>((ref) {
  // 获取服务器 URL
  final serverUrl = ref.watch(serverUrlProvider);

  // 获取认证信息，用于Socket连接
  final authInfoFuture = ref.watch(authInfoProvider.future);

  print('创建 Socket 连接管理器，服务器 URL: $serverUrl');

  // 创建 Socket 连接管理器
  return SocketConnectionManager(
    serverUrl: serverUrl, // 使用从配置中获取的 URL
    authInfoFuture: authInfoFuture,
  );
});

// Socket.IO 连接状态提供者
final socketConnectionStatusProvider = StreamProvider<bool>((ref) {
  final manager = ref.watch(socketConnectionManagerProvider);
  return manager.connectionStatus;
});

// Socket.IO 实例提供者
final socketProvider = Provider<IO.Socket>((ref) {
  final manager = ref.watch(socketConnectionManagerProvider);
  if (!manager.isConnected) {
    throw StateError('Socket 尚未连接，应先调用 connect() 方法');
  }
  return manager.socket;
});

// 本地数据源提供者
final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ChatLocalDataSourceImpl(prefs);
});

// 远程数据源提供者
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final serverUrl = ref.watch(serverUrlProvider);
  final httpClient = ref.watch(httpClientProvider);

  // 获取认证信息的函数
  final getAuthHeaders = () async {
    final authInfo = await ref.read(authInfoProvider.future);
    return {
      'Authorization': 'Bearer ${authInfo['token'] ?? ''}',
    };
  };

  if (ref.read(useMockDataProvider)) {
    // 使用模拟数据
    return MockChatRemoteDataSource();
  } else {
    // 使用HTTP实现
    return ChatRemoteHttpDataSourceImpl(
      baseUrl: serverUrl,
      httpClient: httpClient,
      getHeaders: () => {
        'Authorization':
            'Bearer ${ref.read(authInfoProvider).value?['token'] ?? ''}',
        'Content-Type': 'application/json',
      },
    );
  }
});

// Socket 数据源提供者
final chatSocketDataSourceProvider = Provider<ChatSocketDataSource>((ref) {
  final socket = ref.watch(socketProvider);
  final manager = ref.watch(socketConnectionManagerProvider);
  return ChatSocketDataSourceImpl(socket, manager);
});

// 聊天仓库提供者
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final localDataSource = ref.watch(chatLocalDataSourceProvider);
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  final socketDataSource = ref.watch(chatSocketDataSourceProvider);

  // 实例化仓库实现
  return ChatRepositoryImpl(
    localDatasource: localDataSource,
    remoteDatasource: remoteDataSource,
    socketDatasource: socketDataSource,
  );
});

// 添加HTTP客户端提供者
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// 添加一个用于控制是否使用模拟数据的开关
final useMockDataProvider = StateProvider<bool>((ref) => true);

// 修改提供者工厂，注册Socket连接初始化方法
final socketInitializerProvider = Provider<Future<void>>((ref) async {
  // 仅在需要时触发Socket连接
  final socketManager = ref.watch(socketConnectionManagerProvider);
  final shouldConnect = ref.watch(shouldConnectProvider);

  if (shouldConnect) {
    await socketManager.connect();
  }

  // 注册清理方法
  ref.onDispose(() {
    socketManager.disconnect();
  });
});

// 工具方法：提供未来某个时间点的用户会话凭证
Future<Map<String, String>> getSocketAuthInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString('username') ?? 'guest_user';
  final token = prefs.getString('auth_token') ?? '';

  return {
    'username': username,
    'token': token,
  };
}

// 修改 mockRemoteDataSource 提供器，确保它不依赖于 Socket
final mockRemoteDataSourceProvider = Provider<MockChatRemoteDataSource>((ref) {
  return MockChatRemoteDataSource();
});
