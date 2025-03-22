import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/usecases/get_chat_rooms.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/datasources/chat_socket_datasource.dart';
import '../../data/datasources/chat_local_datasource.dart';

// 依赖注入
final chatSocketDatasourceProvider = Provider<ChatSocketDatasource>((ref) {
  return ChatSocketDatasourceImpl(serverUrl: 'ws://your-server-url.com');
});

final chatLocalDatasourceProvider = Provider<ChatLocalDatasource>((ref) {
  return ChatLocalDatasourceImpl();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    remoteDatasource: ref.watch(chatSocketDatasourceProvider),
    localDatasource: ref.watch(chatLocalDatasourceProvider),
  );
});

final getChatRoomsProvider = Provider<GetChatRooms>((ref) {
  return GetChatRooms(ref.watch(chatRepositoryProvider));
});

final sendMessageProvider = Provider<SendMessage>((ref) {
  return SendMessage(ref.watch(chatRepositoryProvider));
});

// 状态管理
final chatConnectionProvider =
    StateNotifierProvider<ChatConnectionNotifier, bool>((ref) {
  return ChatConnectionNotifier(ref.watch(chatRepositoryProvider));
});

class ChatConnectionNotifier extends StateNotifier<bool> {
  final ChatRepository _repository;

  ChatConnectionNotifier(this._repository) : super(false) {
    connect();
  }

  Future<void> connect() async {
    final result = await _repository.connect();
    result.fold((failure) => state = false, (connected) => state = connected);
  }

  Future<void> disconnect() async {
    final result = await _repository.disconnect();
    result.fold((failure) => {}, (disconnected) => state = !disconnected);
  }
}

// 聊天室列表状态
final chatRoomsProvider =
    StateNotifierProvider<ChatRoomsNotifier, AsyncValue<List<ChatRoom>>>((ref) {
  return ChatRoomsNotifier(ref.watch(getChatRoomsProvider));
});

class ChatRoomsNotifier extends StateNotifier<AsyncValue<List<ChatRoom>>> {
  final GetChatRooms _getChatRooms;

  ChatRoomsNotifier(this._getChatRooms) : super(const AsyncValue.loading()) {
    loadChatRooms();
  }

  Future<void> loadChatRooms() async {
    state = const AsyncValue.loading();
    final result = await _getChatRooms.execute();
    state = result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (chatRooms) => AsyncValue.data(chatRooms));
  }
}

// 消息状态
final currentChatRoomIdProvider = StateProvider<String?>((ref) => null);

final messagesProvider =
    StreamProvider.family<List<Message>, String>((ref, chatRoomId) {
  final repository = ref.watch(chatRepositoryProvider);

  // 首先获取历史消息，然后监听新消息
  // 使用rxdart的扩展方法来累积消息
  return repository.messageStream
      .where((message) =>
          message.senderId == chatRoomId || message.receiverId == chatRoomId)
      .scan<List<Message>>((acc, message, _) => [...acc, message], <Message>[]);
});

// 添加获取历史消息的Provider
final historicalMessagesProvider =
    FutureProvider.family<List<Message>, String>((ref, chatRoomId) async {
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getMessages(chatRoomId);
  return result.fold((failure) => <Message>[], (messages) => messages);
});
