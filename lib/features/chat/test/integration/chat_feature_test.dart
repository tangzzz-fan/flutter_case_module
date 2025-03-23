import 'package:dartz/dartz.dart';
import 'package:flutter_module/features/chat/data/models/message_model.dart';
import 'package:flutter_module/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_module/features/chat/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_module/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:flutter_module/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:flutter_module/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:flutter_module/features/chat/domain/usecases/get_chat_rooms.dart';
import 'package:flutter_module/features/chat/domain/usecases/send_message.dart';
import 'package:flutter_module/features/chat/domain/entities/message.dart';
import 'package:flutter_module/features/chat/data/datasources/chat_socket_datasource.dart';
import 'dart:async';

// 模拟依赖
class MockChatSocketDataSource extends Mock implements ChatSocketDataSource {}

class FakeMessage extends Fake implements Message {}

// 创建控制得更严格的远程数据源模拟
class StrictMockRemoteDataSource extends Mock
    implements MockChatRemoteDataSource {}

void main() {
  // 注册 MessageType 和 Message 的 fallback 值
  setUpAll(() {
    registerFallbackValue(MessageType.text);
    registerFallbackValue(FakeMessage());
  });

  late MockChatSocketDataSource socketDataSource;
  late StrictMockRemoteDataSource remoteDataSource;
  late ChatLocalDataSourceImpl localDataSource;
  late SharedPreferences sharedPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
    localDataSource = ChatLocalDataSourceImpl(sharedPrefs);
    remoteDataSource = StrictMockRemoteDataSource();
    socketDataSource = MockChatSocketDataSource();

    // 预设模拟行为，使用明确的返回值
    when(() => socketDataSource.connect()).thenAnswer((_) async => true);
    when(() => socketDataSource.disconnect()).thenAnswer((_) async => true);
  });

  // 确保资源清理
  tearDown(() async {
    // 清理缓存
    await sharedPrefs.clear();
  });

  testWidgets('完整聊天特性集成测试', (WidgetTester tester) async {
    // 使用超时限制避免无限等待
    await runZoned(() async {
      // 创建仓库
      final repository = ChatRepositoryImpl(
        remoteDatasource: remoteDataSource,
        localDatasource: localDataSource,
        socketDatasource: socketDataSource,
      );

      // 创建用例
      final getChatRoomsUseCase = GetChatRooms(repository);
      final sendMessageUseCase = SendMessage(repository);

      // 明确预设模拟返回值
      final testRooms = [
        ChatRoom(
          id: 'room_0',
          name: 'Room 0',
          members: [User(id: 'user_1', name: 'User 1')],
          isPrivate: false,
          description: 'Room 0 description',
          createdAt: DateTime.now(),
        ),
        ChatRoom(
          id: 'room_1',
          name: 'Room 1',
          members: [User(id: 'user_1', name: 'User 1')],
          isPrivate: false,
          description: 'Room 1 description',
          createdAt: DateTime.now(),
        ),
      ];

      when(() => remoteDataSource.getChatRooms())
          .thenAnswer((_) async => Right(testRooms));

      // 测试获取聊天室
      final chatRoomsResult = await getChatRoomsUseCase.execute();

      chatRoomsResult.fold(
        (failure) => fail('获取聊天室应该成功: $failure'),
        (rooms) {
          expect(rooms.length, 2);
          expect(rooms.first.name, 'Room 0');
        },
      );

      // 设置消息发送的模拟行为
      final testMessage = Message(
        id: 'test_msg_1',
        content: '集成测试消息',
        senderId: 'user_1',
        receiverId: 'room_1',
        timestamp: DateTime.now(),
        type: MessageType.text,
      );

      when(() => socketDataSource.sendMessage(
            'room_1',
            '集成测试消息',
            MessageType.text,
          )).thenReturn(null);

      when(() => remoteDataSource.sendMessage(
            'room_1',
            '集成测试消息',
            MessageType.text,
            'user_1',
          )).thenAnswer((_) async => Right(MessageModel(
            id: 'test_msg_1',
            content: '集成测试消息',
            fromUserId: 'user_1',
            timestamp: DateTime.now(),
          )));

      // 测试发送消息
      final sendResult = await sendMessageUseCase.execute(
        'room_1',
        '集成测试消息',
        MessageType.text,
        'user_1',
      );

      sendResult.fold(
        (failure) => fail('发送消息应该成功: $failure'),
        (message) {
          expect(message.content, '集成测试消息');
        },
      );

      // 保存测试聊天室到本地
      await localDataSource.saveChatRooms(testRooms);

      // 验证本地缓存是否工作
      final cachedRooms = await localDataSource.getChatRooms();
      expect(cachedRooms.length, 2);
    }, onError: (error, stack) {
      fail('测试遇到错误: $error\n$stack');
    });
  }, timeout: const Timeout(Duration(seconds: 5))); // 添加超时限制
}
