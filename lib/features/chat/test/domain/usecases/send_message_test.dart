import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_module/features/chat/core/failure.dart';
import 'package:flutter_module/features/chat/domain/entities/message.dart';
import 'package:flutter_module/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_module/features/chat/domain/usecases/send_message.dart';
import 'dart:async';

class MockChatRepository extends Mock implements ChatRepository {}

class FakeMessage extends Fake implements Message {}

void main() {
  // 注册 MessageType 和 Message 的 fallback 值
  setUpAll(() {
    registerFallbackValue(MessageType.text);
    registerFallbackValue(FakeMessage());
  });

  late SendMessage usecase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    usecase = SendMessage(mockRepository);
  });

  final testMessage = Message(
    id: 'msg1',
    content: '测试消息',
    senderId: 'user1',
    receiverId: 'user2',
    timestamp: DateTime.now(),
    type: MessageType.text,
  );

  test('应该正确发送消息', () async {
    // 使用具体参数而不是 any()
    when(() => mockRepository.sendMessage(
          'room1',
          '测试消息',
          MessageType.text,
          'user1',
        )).thenAnswer((_) async => Right(testMessage));

    // 执行
    final result = await usecase.execute(
      'room1',
      '测试消息',
      MessageType.text,
      'user1',
    );

    // 验证
    expect(result, Right(testMessage));
    verify(() => mockRepository.sendMessage(
          'room1',
          '测试消息',
          MessageType.text,
          'user1',
        )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('应该正确处理发送消息失败', () async {
    // 使用具体参数而不是 any()
    when(() => mockRepository.sendMessage(
          'room1',
          '测试消息',
          MessageType.text,
          'user1',
        )).thenAnswer((_) async => Left(ServerFailure('发送失败')));

    // 执行
    final result = await usecase.execute(
      'room1',
      '测试消息',
      MessageType.text,
      'user1',
    );

    // 验证
    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, isA<ServerFailure>()),
      (_) => fail('应该返回失败结果'),
    );
    verify(() => mockRepository.sendMessage(
          'room1',
          '测试消息',
          MessageType.text,
          'user1',
        )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
