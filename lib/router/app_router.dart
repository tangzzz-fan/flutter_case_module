import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/bluetooth_screen.dart';
import '../screens/sensor_screen.dart';
import '../screens/log_screen.dart';

/// 应用路由管理类
class AppRouter {
  // 单例模式
  static final AppRouter _instance = AppRouter._internal();
  factory AppRouter() => _instance;
  AppRouter._internal();

  // 路由名称常量
  static const String home = '/';
  static const String detail = '/detail';
  static const String settings = '/settings';
  static const String profile = '/profile';

  // 路由配置
  late final GoRouter router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'detail/:id',
            name: 'detail',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? 'unknown';
              return DetailScreen(id: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/sensor',
        builder: (context, state) => const SensorScreen(),
      ),
      GoRoute(
        path: '/logs',
        builder: (context, state) => const LogScreen(),
      ),
      GoRoute(
        path: '/bluetooth',
        builder: (context, state) => const BluetoothScreen(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );

  // 导航方法
  static void navigateToDetail(BuildContext context, String id) {
    context.goNamed('detail', pathParameters: {'id': id});
  }

  static void navigateToSettings(BuildContext context) {
    context.goNamed('settings');
  }

  static void navigateToProfile(BuildContext context) {
    context.goNamed('profile');
  }

  static void navigateToHome(BuildContext context) {
    context.goNamed('home');
  }

  static void navigateToBluetooth(BuildContext context) {
    GoRouter.of(context).push('/bluetooth');
  }

  static void pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }

  static void navigateToSensorDemo(BuildContext context) {
    context.push('/sensor');
  }

  static void navigateToLogDemo(BuildContext context) {
    context.push('/logs');
  }
}
