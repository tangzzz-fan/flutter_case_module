import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_module/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:flutter_module/features/chat/domain/entities/message.dart';
import 'dart:async';

void main() {
  late MockChatRemoteDataSource dataSource;

  setUp(() {
    dataSource = MockChatRemoteDataSource();
  });

  test('应该返回模拟用户列表', () async {
    // 执行
    final result = await dataSource.getUsers();

    // 验证结果内容而不是检查 isRight()
    result.fold(
      (failure) => fail('应该返回成功结果，但得到: $failure'),
      (users) {
        expect(users.length, 10);
        expect(users.first.id, startsWith('user_'));
        expect(users.first.username, startsWith('User '));
      },
    );
  });

  test('应该返回模拟聊天室列表', () async {
    // 执行
    final result = await dataSource.getChatRooms();

    // 验证结果内容而不是检查 isRight()
    result.fold(
      (failure) => fail('应该返回成功结果，但得到: $failure'),
      (rooms) {
        expect(rooms.length, 5);
        expect(rooms.first.id, startsWith('room_'));
        expect(rooms.first.name, startsWith('Room '));
        expect(rooms.first.members.length, greaterThan(0));
      },
    );
  });

  test('应该返回特定聊天室的模拟消息', () async {
    // 执行
    final result = await dataSource.getMessages('room_1');

    // 验证
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('应该返回成功结果'),
      (messages) {
        expect(messages.length, greaterThan(0));
        expect(messages.first.id, contains('msg_'));
      },
    );
  });

  test('应该能够发送消息', () async {
    // 执行
    final result = await dataSource.sendMessage(
      'room_1',
      '测试消息',
      MessageType.text,
      'user_1',
    );

    // 验证
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('应该返回成功结果'),
      (message) {
        expect(message.content, '测试消息');
        expect(message.fromUserId, 'user_1');
      },
    );
  });

  test('应该能够创建新聊天室', () async {
    // 执行
    final result = await dataSource.createChatRoom(
      '新测试聊天室',
      '这是一个测试聊天室',
      false,
    );

    // 验证
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('应该返回成功结果'),
      (room) {
        expect(room.name, '新测试聊天室');
        expect(room.description, '这是一个测试聊天室');
        expect(room.isPrivate, false);
      },
    );
  });
}
