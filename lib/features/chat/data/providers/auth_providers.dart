import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

import '../../domain/entities/chat_state.dart';
import '../../domain/entities/user.dart';
// import '../../domain/repositories/auth_repository.dart'; // 注释这行，因为我们将直接在本文件中定义接口

// 定义 AuthRepository 接口
abstract class AuthRepository {
  Stream<bool> connectionStateStream();
  Future<User?> getCurrentUser();
  // 其他可能需要的方法...
}

// 创建一个 Mock 实现
class MockAuthRepository implements AuthRepository {
  // 模拟连接状态流
  @override
  Stream<bool> connectionStateStream() {
    // 返回一个始终为已连接状态的流
    return Stream.value(true).asBroadcastStream();
  }

  // 模拟获取当前用户
  @override
  Future<User?> getCurrentUser() async {
    // 模拟延迟，模拟网络请求
    await Future.delayed(const Duration(milliseconds: 300));
    // 返回一个测试用户，包含所有新字段
    return User(
      id: 'mock_user_id',
      name: 'Mock User',
      avatar: 'https://via.placeholder.com/150',
      isOnline: true,
      lastSeen: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }
}

// 用户认证信息提供者
final authInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // 通常从安全存储或登录状态获取用户凭证
  final prefs = await SharedPreferences.getInstance();

  // 如果没有现有用户名，创建一个临时用户名
  String username = prefs.getString('username') ?? '';
  if (username.isEmpty) {
    username = 'Guest_${Random().nextInt(10000)}';
    await prefs.setString('username', username);
    print('👤 创建临时用户名: $username');
  }

  final token = prefs.getString('auth_token') ?? '';

  final authInfo = {
    'username': username,
    'token': token,
  };

  print('🔑 获取认证信息: $authInfo');
  return authInfo;
});

// 设置认证信息
Future<void> setAuthInfo(String username, String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('username', username);
  await prefs.setString('auth_token', token);
  print(
      '✅ 已更新认证信息: username=$username, token=${token.isNotEmpty ? '******' : 'empty'}');
}

// 临时用户名 provider
final tempUsernameProvider = StateProvider<String>((ref) {
  return 'Guest_${Random().nextInt(10000)}';
});

// 更新 authRepositoryProvider 使用 MockAuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // 返回 MockAuthRepository 作为测试用途
  return MockAuthRepository();
});

// 重命名为更具描述性的名称
final authConnectionStateProvider = StreamProvider<bool>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.connectionStateStream();
});

// 当前用户 Provider
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authInfo = await ref.watch(authInfoProvider.future);

  // 创建一个简单的用户对象，基于认证信息
  return User(
    id: 'local_user',
    name: authInfo['username'],
    isOnline: true,
    avatar: null,
    lastSeen: DateTime.now(),
  );
});
