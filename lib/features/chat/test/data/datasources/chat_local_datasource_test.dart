import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_module/features/chat/core/exceptions.dart';
import 'package:flutter_module/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:flutter_module/features/chat/data/models/message_model.dart';
import 'package:flutter_module/features/chat/data/models/user_model.dart';
import 'package:flutter_module/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_module/features/chat/domain/entities/message.dart';
import 'package:flutter_module/features/chat/domain/entities/user.dart';
import 'dart:async';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late ChatLocalDataSourceImpl dataSource;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    dataSource = ChatLocalDataSourceImpl(mockPrefs);
  });

  group('聊天室操作', () {
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
      ChatRoom(
        id: 'room2',
        name: '测试聊天室2',
        members: [
          User(id: 'user1', name: '用户1'),
          User(id: 'user3', name: '用户3'),
        ],
        description: '测试描述2',
        createdAt: DateTime.now(),
        isPrivate: true,
      ),
    ];

    test('应该正确保存和获取聊天室列表', () async {
      // 准备
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.getString('chat_rooms')).thenReturn(
          json.encode(testChatRooms.map((e) => e.toJson()).toList()));

      // 执行保存
      await dataSource.saveChatRooms(testChatRooms);

      // 验证保存
      verify(() => mockPrefs.setString(any(), any())).called(1);

      // 执行获取
      final result = await dataSource.getChatRooms();

      // 验证获取
      expect(result.length, 2);
      expect(result.first.id, 'room1');
      expect(result.first.name, '测试聊天室1');
      expect(result.last.id, 'room2');
      expect(result.last.isPrivate, true);
    });

    test('获取聊天室列表应正确处理空结果', () async {
      // 准备
      when(() => mockPrefs.getString('chat_rooms')).thenReturn(null);

      // 执行
      final result = await dataSource.getChatRooms();

      // 验证
      expect(result, isEmpty);
    });

    test('获取聊天室列表应处理格式错误', () async {
      // 准备
      when(() => mockPrefs.getString('chat_rooms')).thenReturn('无效JSON');

      // 执行 & 验证
      expect(() => dataSource.getChatRooms(), throwsA(isA<CacheException>()));
    });
  });

  group('消息操作', () {
    final testMessages = [
      Message(
        id: 'msg1',
        content: '测试消息1',
        senderId: 'user1',
        receiverId: 'user2',
        timestamp: DateTime.now(),
      ),
      Message(
        id: 'msg2',
        content: '测试消息2',
        senderId: 'user2',
        receiverId: 'user1',
        timestamp: DateTime.now(),
      ),
    ];

    test('应该正确保存和获取消息列表', () async {
      // 准备
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.getString('messages_room1')).thenReturn(
          json.encode(testMessages.map((e) => e.toJson()).toList()));

      // 执行保存
      await dataSource.saveMessages('room1', testMessages);

      // 验证保存
      verify(() => mockPrefs.setString(any(), any())).called(1);

      // 执行获取
      final result = await dataSource.getMessages('room1');

      // 验证获取
      expect(result.length, 2);
      expect(result.first.id, 'msg1');
      expect(result.first.content, '测试消息1');
      expect(result.last.id, 'msg2');
      expect(result.last.senderId, 'user2');
    });

    test('应该正确保存单条消息', () async {
      // 准备
      final testMessage = Message(
        id: 'msg3',
        content: '测试消息3',
        senderId: 'user1',
        receiverId: 'user2',
        timestamp: DateTime.now(),
      );

      // 模拟先获取现有消息
      when(() => mockPrefs.getString('messages_room1')).thenReturn(
          json.encode(testMessages.map((e) => e.toJson()).toList()));

      // 模拟保存更新后的消息
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);

      // 执行
      await dataSource.saveMessage('room1', testMessage);

      // 验证
      verify(() => mockPrefs.getString('messages_room1')).called(1);
      verify(() => mockPrefs.setString(any(), any())).called(1);
    });
  });
}
