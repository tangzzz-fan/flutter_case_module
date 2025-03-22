import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository_impl.dart';
import '../datasources/chat_socket_datasource.dart';
import '../datasources/chat_local_datasource.dart';
import '../../domain/repositories/chat_repository.dart';

// 配置 provider
final serverUrlProvider = Provider<String>((ref) {
  // 使用本地服务器地址
  return "http://localhost:6000";
});

// 数据源 provider
final chatSocketDatasourceProvider = Provider<ChatSocketDatasource>((ref) {
  // 提供本地服务器地址
  final serverUrl = ref.watch(serverUrlProvider);
  return ChatSocketDatasourceImpl(serverUrl: serverUrl);
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
