import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository_impl.dart';
import '../datasources/chat_socket_datasource.dart';
import '../datasources/chat_local_datasource.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/socket_connection_manager.dart';
import 'auth_providers.dart';

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

// Socket连接管理器Provider，依赖于认证信息
final socketConnectionManagerProvider =
    Provider<SocketConnectionManager>((ref) {
  final serverUrl = ref.watch(serverUrlProvider);

  // 使用临时用户名进行快速测试（实际应用中应使用真实认证）
  final tempUsername = ref.watch(tempUsernameProvider);
  final authInfo = {'username': tempUsername};

  final manager = SocketConnectionManager(
    serverUrl: serverUrl,
    authInfo: authInfo,
  );

  // 当Provider被销毁时释放资源
  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

// 数据源 provider
final chatSocketDatasourceProvider = Provider<ChatSocketDatasource>((ref) {
  final serverUrl = ref.watch(serverUrlProvider);
  final datasource = ChatSocketDatasourceImpl(serverUrl: serverUrl);

  // 当Provider被销毁时释放资源
  ref.onDispose(() {
    (datasource as ChatSocketDatasourceImpl).dispose();
  });

  return datasource;
});

final chatLocalDatasourceProvider = Provider<ChatLocalDatasource>((ref) {
  // 实现本地数据源
  return ChatLocalDatasourceImpl();
});

// 仓库 provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    remoteDatasource: ref.watch(chatSocketDatasourceProvider),
    localDatasource: ref.watch(chatLocalDatasourceProvider),
  );
});

// 连接状态 provider
final socketConnectionStatusProvider = StreamProvider<bool>((ref) {
  final manager = ref.watch(socketConnectionManagerProvider);
  return manager.connectionStatus;
});
