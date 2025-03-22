# Flutter 模块

这是一个Flutter模块项目，设计用于集成到现有iOS或Android应用中，提供多种通信机制和功能演示。

## 项目描述

该模块展示了Flutter与原生应用的无缝集成能力，实现了多种通信机制和实用功能，包括日志系统、蓝牙管理、传感器数据处理等。通过使用不同的通信通道（Method/Event/BasicMessage Channel），演示了Flutter与原生代码之间的各种交互方式。

## 项目结构
```
flutter_module/
├── lib/
│ ├── main.dart # 应用入口
│ ├── router/
│ │ └── app_router.dart # 路由管理（go_router）
│ ├── screens/
│ │ ├── home_screen.dart # 首页（MethodChannel示例）
│ │ ├── detail_screen.dart # 详情页面
│ │ ├── log_screen.dart # 日志展示（BasicMessageChannel示例）
│ │ ├── sensor_screen.dart # 传感器数据（EventChannel示例）
│ │ ├── bluetooth_screen.dart # 蓝牙管理
│ │ ├── settings_screen.dart # 设置页面
│ │ ├── profile_screen.dart # 个人资料
│ │ └── not_found_screen.dart # 404页面
│ ├── services/
│ │ ├── log_service.dart # 日志服务
│ │ ├── sensor_service.dart # 传感器服务
│ │ └── bluetooth_service.dart # 蓝牙服务
│ └── widgets/
│ └── bottom_nav_bar.dart # 底部导航栏
```

## 核心功能

### 跨平台通信机制

模块实现了三种Flutter与原生代码的通信机制：

1. **MethodChannel** - 用于方法调用和返回单一结果
   - 示例: 首页（HomeScreen）中的消息传递和页面退出

2. **EventChannel** - 用于连续数据流
   - 示例: 传感器数据（SensorScreen）中的加速度计数据流

3. **BasicMessageChannel** - 用于简单的消息传递
   - 示例: 日志系统（LogScreen）中的日志记录和显示

### 功能模块

1. **日志系统**
   - 记录不同级别的日志（INFO、WARNING、ERROR、DEBUG）
   - 在Flutter和原生端之间同步日志
   - 提供用户友好的日志查看界面

2. **蓝牙功能**
   - 扫描周围蓝牙设备
   - 连接/断开蓝牙设备
   - 显示设备信息和信号强度

3. **传感器数据**
   - 实时获取设备加速度计数据
   - 图形化展示传感器数据变化

4. **路由导航**
   - 使用go_router管理应用内导航
   - 实现基于命名路由的导航系统
   - 支持动态参数和嵌套路由

## 技术栈

- **路由管理**: go_router
- **状态管理**: provider
- **UI组件**: flutter_svg, cached_network_image
- **开发环境**: Flutter SDK 3.3+

## 开始使用

### 环境配置

确保已安装Flutter开发环境。有关Flutter开发的入门帮助，请查看在线[文档](https://flutter.dev/)。

### 集成到现有应用

有关将Flutter模块集成到现有应用程序的说明，请参阅[add-to-app文档](https://flutter.dev/docs/development/add-to-app)。

### 使用示例

#### 方法通道示例（MethodChannel）

```dart
// 发送消息到原生端
await platform.invokeMethod('sendMessageToNative', '来自Flutter的消息');

// 接收来自原生端的消息
platform.setMethodCallHandler((call) async {
  if (call.method == 'sendMessageToFlutter') {
    // 处理消息
    return '消息已接收';
  }
});
```

#### 日志示例（BasicMessageChannel）

```dart
// 记录日志
LogService().log('这是一条测试日志', LogLevel.info);

// 显示日志界面
Navigator.push(context, MaterialPageRoute(builder: (context) => LogScreen()));
```

#### 传感器数据示例（EventChannel）

```dart
// 获取传感器数据流
SensorService().accelerometerStream.listen((data) {
  print('X: ${data.x}, Y: ${data.y}, Z: ${data.z}');
});
```

## 注意事项

- 项目需要Flutter 3.3或更高版本
- 集成到原生应用时，需遵循Flutter官方的add-to-app流程
- 部分功能可能需要特定平台权限（如蓝牙、传感器）
