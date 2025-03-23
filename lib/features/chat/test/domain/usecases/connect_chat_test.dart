import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_module/features/chat/core/failure.dart';
import 'package:flutter_module/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_module/features/chat/domain/usecases/connect_chat.dart';
import 'dart:async';

// 模拟聊天仓库
class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late ConnectChat usecase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    usecase = ConnectChat(mockRepository);
  });

  test('应该从仓库转发连接请求', () async {
    // 准备
    when(() => mockRepository.connect())
        .thenAnswer((_) async => const Right(true));

    // 执行
    final result = await usecase.execute();

    // 验证
    expect(result, const Right(true));
    verify(() => mockRepository.connect()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('应该正确处理连接失败', () async {
    // 准备
    when(() => mockRepository.connect())
        .thenAnswer((_) async => Left(ConnectionFailure('连接失败')));

    // 执行
    final result = await usecase.execute();

    // 验证
    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, isA<ConnectionFailure>()),
      (_) => fail('应该返回失败结果'),
    );
    verify(() => mockRepository.connect()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
