import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_module/features/chat/core/failure.dart';
import 'package:flutter_module/features/chat/domain/entities/chat_room.dart';
import 'package:flutter_module/features/chat/domain/entities/user.dart';
import 'package:flutter_module/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_module/features/chat/domain/usecases/get_chat_rooms.dart';
import 'dart:async';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late GetChatRooms usecase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    usecase = GetChatRooms(mockRepository);
  });

  final testUsers = [
    User(id: 'user1', name: '用户1'),
    User(id: 'user2', name: '用户2'),
  ];

  final testChatRooms = [
    ChatRoom(
      id: 'room1',
      name: '测试聊天室1',
      members: testUsers,
      description: '测试描述1',
      createdAt: DateTime.now(),
      isPrivate: false,
    ),
    ChatRoom(
      id: 'room2',
      name: '测试聊天室2',
      members: testUsers,
      description: '测试描述2',
      createdAt: DateTime.now(),
      isPrivate: true,
    ),
  ];

  test('应该正确获取聊天室列表', () async {
    // 准备
    when(() => mockRepository.getChatRooms())
        .thenAnswer((_) async => Right(testChatRooms));

    // 执行
    final result = await usecase.execute();

    // 验证
    expect(result, Right(testChatRooms));
    verify(() => mockRepository.getChatRooms()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('应该正确处理获取聊天室列表失败', () async {
    // 准备
    when(() => mockRepository.getChatRooms())
        .thenAnswer((_) async => Left(ServerFailure('服务器错误')));

    // 执行
    final result = await usecase.execute();

    // 验证
    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, isA<ServerFailure>()),
      (_) => fail('应该返回失败结果'),
    );
    verify(() => mockRepository.getChatRooms()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
