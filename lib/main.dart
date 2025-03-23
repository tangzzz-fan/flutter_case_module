import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/chat/data/providers/chat_data_providers.dart';

Future<void> main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // 使用ProviderScope覆盖提供者并运行应用
  runApp(
    ProviderScope(
      overrides: [
        // 覆盖sharedPreferencesProvider，提供实际的实例
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter 模块',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      routerConfig: AppRouter().router,
    );
  }
}
