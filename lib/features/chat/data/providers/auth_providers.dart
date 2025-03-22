import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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
    await Future.delayed(Duration(milliseconds: 300));
    // 返回一个测试用户
    return const User(
        id: 'mock_user_id',
        name: 'Mock User',
        avatar: 'https://via.placeholder.com/150');
  }
}

// 用户认证信息提供者
final authInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // 通常从安全存储或登录状态获取用户凭证
  final prefs = await SharedPreferences.getInstance();

  // 获取存储的用户名和令牌
  final username = prefs.getString('username') ?? 'guest_user';
  final token = prefs.getString('auth_token') ?? '';

  return {
    'username': username,
    'token': token,
  };
});

// 设置认证信息
Future<void> setAuthInfo(String username, String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('username', username);
  await prefs.setString('auth_token', token);
}

// 临时用户名 provider - 这是唯一的定义
final tempUsernameProvider = StateProvider<String>(
    (ref) => 'Guest_${DateTime.now().millisecondsSinceEpoch}');

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

// 添加 currentUserProvider 定义
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getCurrentUser();
});
