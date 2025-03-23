import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_module/features/chat/core/exceptions.dart';
import 'package:flutter_module/features/chat/core/failure.dart';
import 'package:flutter_module/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:flutter_module/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:flutter_module/features/chat/data/datasources/chat_socket_datasource.dart';
import 'package:flutter_module/features/chat/data/models/message_model.dart';
import 'package:flutter_module/features/chat/data/models/user_model.dart';
import 'package:flutter_module/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:flutter_module/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_module/features/chat/domain/entities/message.dart';
import 'package:flutter_module/features/chat/domain/entities/user.dart';
import 'dart:async';

// 模拟数据源
class MockChatRemoteDataSource extends Mock implements ChatRemoteDataSource {}

class MockChatLocalDataSource extends Mock implements ChatLocalDataSource {}

class MockChatSocketDataSource extends Mock implements ChatSocketDataSource {}

// 创建 Message 的 Fake 类用于注册
class FakeMessage extends Fake implements Message {}

void main() {
  // 注册 MessageType 和 Message 的 fallback 值
  setUpAll(() {
    registerFallbackValue(MessageType.text);
    registerFallbackValue(FakeMessage());
  });

  late ChatRepositoryImpl repository;
  late MockChatRemoteDataSource mockRemoteDataSource;
  late MockChatLocalDataSource mockLocalDataSource;
  late MockChatSocketDataSource mockSocketDataSource;

  setUp(() {
    mockRemoteDataSource = MockChatRemoteDataSource();
    mockLocalDataSource = MockChatLocalDataSource();
    mockSocketDataSource = MockChatSocketDataSource();
    repository = ChatRepositoryImpl(
      remoteDatasource: mockRemoteDataSource,
      localDatasource: mockLocalDataSource,
      socketDatasource: mockSocketDataSource,
    );
  });

  group('connect', () {
    test('应该成功连接到聊天服务器', () async {
      // 准备
      when(() => mockSocketDataSource.connect()).thenAnswer((_) async => true);

      // 执行
      final result = await repository.connect();

      // 验证
      expect(result, const Right(true));
      verify(() => mockSocketDataSource.connect()).called(1);
      verifyNoMoreInteractions(mockSocketDataSource);
    });

    test('应该处理连接异常', () async {
      // 准备
      when(() => mockSocketDataSource.connect())
          .thenThrow(ConnectionException('连接失败'));

      // 执行
      final result = await repository.connect();

      // 验证
      expect(result, Left(const Failure.connection()));
      verify(() => mockSocketDataSource.connect()).called(1);
      verifyNoMoreInteractions(mockSocketDataSource);
    });
  });

  group('getChatRooms', () {
    final testChatRooms = [
      ChatRoom(
        id: 'room1',
        name: '测试聊天室1',
        members: [
          User(id: 'user1', name: '用户1'),
          User(id: 'user2', name: '用户2'),
        ],
        description: '测试描述1',
        createdAt: DateTime.now(),
        isPrivate: false,
      ),
    ];

    test('应该首先尝试从本地获取聊天室', () async {
      // 准备
      when(() => mockLocalDataSource.getChatRooms())
          .thenAnswer((_) async => testChatRooms);
      when(() => mockRemoteDataSource.getChatRooms())
          .thenAnswer((_) async => Right(testChatRooms));
      when(() => mockLocalDataSource.saveChatRooms(any()))
          .thenAnswer((_) async {});

      // 执行
      final result = await repository.getChatRooms();

      // 验证
      expect(result, Right(testChatRooms));
      verify(() => mockLocalDataSource.getChatRooms()).called(1);
      verify(() => mockRemoteDataSource.getChatRooms()).called(1);
      verify(() => mockLocalDataSource.saveChatRooms(testChatRooms)).called(1);
    });

    test('当远程获取失败时应该返回本地数据', () async {
      // 准备
      when(() => mockLocalDataSource.getChatRooms())
          .thenAnswer((_) async => testChatRooms);
      when(() => mockRemoteDataSource.getChatRooms())
          .thenAnswer((_) async => Left(ServerFailure('服务器错误')));

      // 执行
      final result = await repository.getChatRooms();

      // 验证
      expect(result, Right(testChatRooms));
      verify(() => mockLocalDataSource.getChatRooms()).called(1);
      verify(() => mockRemoteDataSource.getChatRooms()).called(1);
    });

    test('当本地获取失败时应该尝试远程获取', () async {
      // 准备
      when(() => mockLocalDataSource.getChatRooms())
          .thenThrow(CacheException('缓存错误'));
      when(() => mockRemoteDataSource.getChatRooms())
          .thenAnswer((_) async => Right(testChatRooms));
      when(() => mockLocalDataSource.saveChatRooms(any()))
          .thenAnswer((_) async {});

      // 执行
      final result = await repository.getChatRooms();

      // 验证
      expect(result, Right(testChatRooms));
      verify(() => mockLocalDataSource.getChatRooms()).called(1);
      verify(() => mockRemoteDataSource.getChatRooms()).called(1);
      verify(() => mockLocalDataSource.saveChatRooms(testChatRooms)).called(1);
    });
  });

  group('sendMessage', () {
    final testMessage = Message(
      id: 'msg1',
      content: '测试消息',
      senderId: 'user1',
      receiverId: 'user2',
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    test('应该正确发送消息', () async {
      // 使用具体值代替 any() 来避免匹配器问题
      when(() => mockRemoteDataSource.sendMessage(
            'room1',
            '测试消息',
            MessageType.text,
            'user1',
          )).thenAnswer((_) async => Right(MessageModel(
            id: 'msg1',
            content: '测试消息',
            fromUserId: 'user1',
            timestamp: DateTime.now(),
          )));

      when(() => mockLocalDataSource.saveMessage(any(), any()))
          .thenAnswer((_) async {});

      // 执行
      final result = await repository.sendMessage(
        'room1',
        '测试消息',
        MessageType.text,
        'user1',
      );

      // 验证
      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.sendMessage(
            'room1',
            '测试消息',
            MessageType.text,
            'user1',
          )).called(1);
      verify(() => mockLocalDataSource.saveMessage(any(), any())).called(1);
    });

    test('当远程发送失败时应使用Socket发送并创建临时消息', () async {
      // 替换为具体异常而不是 any()
      when(() => mockRemoteDataSource.sendMessage(
            'room1',
            '测试消息',
            MessageType.text,
            'user1',
          )).thenThrow(ServerException('发送失败'));

      when(() => mockSocketDataSource.sendMessage(
            'room1',
            '测试消息',
            MessageType.text,
          )).thenReturn(null);

      when(() => mockLocalDataSource.saveMessage(any(), any()))
          .thenAnswer((_) async {});

      // 执行
      final result = await repository.sendMessage(
        'room1',
        '测试消息',
        MessageType.text,
        'user1',
      );

      // 验证
      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.sendMessage(
            'room1',
            '测试消息',
            MessageType.text,
            'user1',
          )).called(1);
      verify(() => mockSocketDataSource.sendMessage(
            'room1',
            '测试消息',
            MessageType.text,
          )).called(1);
      verify(() => mockLocalDataSource.saveMessage(any(), any())).called(1);
    });
  });
}
