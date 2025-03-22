## Chat 模块架构设计文档

### 1. 概述

   Chat 模块采用 Clean Architecture（整洁架构）设计，通过明确的层次分离和依赖规则，提供了高度可维护、可测试和可扩展的聊天功能实现。本文档详细介绍了该架构的设计理念、实现细节以及扩展指南。

### 2. 架构设计

#### 2.1 整体架构

   该模块严格遵循 Clean Architecture 的原则，分为以下几层：
```
   features/chat/
├── core/                 # 核心组件（异常、失败处理等）
├── domain/               # 领域层（业务规则和实体）
│   ├── entities/         # 领域实体
│   ├── repositories/     # 仓库接口
│   └── usecases/         # 用例（业务逻辑）
├── data/                 # 数据层（仓库实现和数据源）
│   ├── datasources/      # 数据源
│   ├── models/           # 数据模型
│   └── repositories/     # 仓库实现
└── presentation/         # 表现层（UI 和状态管理）
    ├── providers/        # 状态管理
    └── widgets/          # UI 组件
```

#### 2.2 依赖规则

依赖关系严格遵循从外到内的方向：

- presentation 依赖 domain
- data 依赖 domain
- domain 不依赖外层任何模块

这确保了核心业务逻辑的独立性和稳定性。

#### 3. 详细设计

#### 3.1 Domain 层

Domain 层包含业务实体和核心业务逻辑，与具体实现细节无关。

#### 3.1.1 实体

采用 freezed 库实现不可变的领域实体：
- Message: 消息实体，包含ID、发送者、接收者、内容等属性
- User: 用户实体，包含ID、姓名、在线状态等属性
- ChatRoom: 聊天室实体，包含ID、名称、参与者等属性

#### 3.1.2 仓库接口

ChatRepository 接口定义了与数据源交互的方法，如：
```dart
abstract class ChatRepository {
  Future<Either<Failure, bool>> connect();
  Future<Either<Failure, List<ChatRoom>>> getChatRooms();
  Future<Either<Failure, List<Message>>> getMessages(String chatRoomId);
  // ... 其他方法
}
```

#### 3.1.3 用例

用例封装了特定的业务逻辑，每个用例负责一个具体功能：
- GetChatRooms: 获取聊天室列表
- SendMessage: 发送消息

#### 3.2 Data 层

Data 层负责实现 Domain 层定义的仓库接口，并处理数据源交互。

#### 3.2.1 数据源
- ChatSocketDatasource: 处理与服务器的实时通信
- ChatLocalDatasource: 处理本地数据存储和检索

#### 3.2.2 数据模型
- MessageModel: 消息数据模型
- UserModel: 用户数据模型
- ChatRoomModel: 聊天室数据模型

所有模型都提供与领域实体的转换方法：
- toMessage(), toUser(), toChatRoom()
- fromMessage(), fromUser(), fromChatRoom()

#### 3.2.3 仓库实现
ChatRepositoryImpl 协调多个数据源，实现 ChatRepository 接口：
```dart
class ChatRepositoryImpl implements ChatRepository {
  final ChatSocketDatasource remoteDatasource;
  final ChatLocalDatasource localDatasource;
  
  // ... 实现方法
}
```

#### 3.3 Presentation 层

Presentation 层负责 UI 和状态管理。

#### 3.3.1 状态管理

使用 Riverpod 进行状态管理：
- chatRoomsProvider: 管理聊天室列表状态
- messagesProvider: 管理消息状态
- sendMessageProvider: 提供发送消息功能

#### 3.3.2 UI 组件

-  ChatInput: 消息输入组件
-  MessageItem: 消息显示组件
-  ChatRoomItem: 聊天室列表项组件

#### 4. 关键技术选择

-  Freezed: 用于创建不可变数据类，简化模型定义和JSON序列化
-  Dartz: 提供Either类型支持函数式错误处理
-  Riverpod: 用于依赖注入和状态管理
-  Socket.io Client: 用于实时通信
-  SQLite/Shared Preferences: 用于本地数据存储

#### 5. 扩展和替换指南

#### 5.1 添加新的数据源

   在 data/datasources 目录下创建新的数据源接口和实现类：
```dart
abstract class NewDataSource {
  // 定义接口方法
}

class NewDataSourceImpl implements NewDataSource {
  // 实现方法
}
```

2.在 ChatRepositoryImpl 中注入并使用新数据源：
```dart 
class ChatRepositoryImpl implements ChatRepository {
  final ChatSocketDatasource remoteDatasource;
  final ChatLocalDatasource localDatasource;
  final NewDataSource newDatasource;
  
  ChatRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
    required this.newDatasource,
  });
  
  // 使用新数据源实现方法
}
```

#### 5.2 替换现有实现

   替换数据源实现
   例如，将 WebSocket 实现替换为 Firebase:
1.创建新的实现类：
```dart
class FirebaseChatDatasource implements ChatSocketDatasource {
  // 使用 Firebase 实现相同接口
}
```
2.更新依赖注入：
```dart
// 在 chat_provider.dart 中
final chatSocketDatasourceProvider = Provider<ChatSocketDatasource>((ref) {
  return FirebaseChatDatasource();  // 替换为新实现
});
```

#### 5.2 替换状态管理

   要从 Riverpod 切换到另一个状态管理解决方案（如 Bloc）：
   1. 创建相应的 Bloc 实现：
```dart
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatRooms getChatRooms;
  final SendMessage sendMessage;
  
  ChatBloc({required this.getChatRooms, required this.sendMessage}) : super(ChatInitial());
  
  // 实现事件处理
}
```
2. 更新 UI 组件以使用新的状态管理：
```dart
class ChatListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => serviceLocator<ChatBloc>()..add(LoadChatRooms()),
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          // 根据状态构建 UI
        },
      ),
    );
  }
}
```

#### 5.3 添加新功能

例如，添加"已读回执"功能：

1. 在 Domain 层更新实体：
```dart
// 在 Message 实体中添加 readReceipt 字段
@freezed
class Message with _$Message {
  const factory Message({
    // 现有字段
    required DateTime? readAt,  // 新增字段
  }) = _Message;
  
  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}
```

2. 更新仓库接口：
```dart
class ChatRepositoryImpl implements ChatRepository {
  // 现有实现
  @override
  Future<Either<Failure, bool>> markAsRead(String messageId, DateTime readAt) async {
    try {
      // 实现标记已读逻辑
      return const Right(true);
    } on ServerException {
      return Left(const Failure.server());
    }
  }
}
```

3. 实现新方法：
```dart
class ChatRepositoryImpl implements ChatRepository {
  // 现有实现
  @override
  Future<Either<Failure, bool>> markAsRead(String messageId, DateTime readAt) async {
    try {
      // 实现标记已读逻辑
      return const Right(true);
    } on ServerException {
      return Left(const Failure.server());
    }
  }
}
```

4. 添加新用例：
```dart
class MarkMessageAsRead {
  final ChatRepository repository;
  
  MarkMessageAsRead(this.repository);
  
  Future<Either<Failure, bool>> execute(String messageId) async {
    return repository.markAsRead(messageId, DateTime.now());
  }
}
```
5. 更新 Providers：
```dart
final markAsReadProvider = Provider<MarkMessageAsRead>((ref) {
  return MarkMessageAsRead(ref.watch(chatRepositoryProvider));
});
```

### 6. 总结
Chat 模块采用的 Clean Architecture 设计提供了高度的模块化和可扩展性。通过严格的层次分离和依赖规则，使得系统各部分可以独立演化，便于测试和维护。无论是添加新功能、替换实现还是扩展现有功能，都可以在不影响其他部分的情况下完成。
这种架构特别适合需要长期维护和不断演进的应用程序，能够适应不断变化的业务需求和技术选择。