import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_state.dart';
import '../../domain/usecases/connect_chat.dart';
import '../../domain/usecases/get_chat_rooms.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_room.dart';
import '../../data/providers/chat_data_providers.dart';
import '../../data/providers/auth_providers.dart';
import 'chat_provider.dart';

// 使用例子提供者
final connectChatProvider = Provider<ConnectChat>((ref) {
  return ConnectChat(ref.watch(chatRepositoryProvider));
});

final getChatRoomsProvider = Provider<GetChatRooms>((ref) {
  return GetChatRooms(ref.watch(chatRepositoryProvider));
});

final getMessagesProvider = Provider<GetMessages>((ref) {
  return GetMessages(ref.watch(chatRepositoryProvider));
});

final sendMessageProvider = Provider<SendMessage>((ref) {
  return SendMessage(ref.watch(chatRepositoryProvider));
});

// 聊天状态提供者 - 使用外部定义的 socketConnectionStatusProvider（StreamProvider<bool>）
final chatConnectionStateProvider = Provider<AsyncValue<bool>>((ref) {
  // 直接返回 socketConnectionStatusProvider 的值
  return ref.watch(socketConnectionStatusProvider);
});

// 聊天室列表提供者
final chatRoomsProvider = FutureProvider<List<ChatRoom>>((ref) async {
  // 先获取连接状态
  final connectionState = ref.watch(socketConnectionStatusProvider);
  final isConnected = connectionState.maybeWhen(
    data: (connected) => connected,
    orElse: () => false,
  );

  if (!isConnected) {
    // 尝试连接
    await ref.read(chatNotifierProvider.notifier).connect();
  }

  final getChatRooms = ref.watch(getChatRoomsProvider);
  final result = await getChatRooms.execute();
  return result.fold(
    (failure) => [],
    (chatRooms) => chatRooms,
  );
});

// 特定聊天室的消息提供者
final chatMessagesProvider =
    FutureProvider.family<List<Message>, String>((ref, chatRoomId) async {
  // 检查连接状态
  final connectionState = ref.watch(socketConnectionStatusProvider);
  final isConnected = connectionState.maybeWhen(
    data: (connected) => connected,
    orElse: () => false,
  );

  if (!isConnected) {
    // 如果未连接，尝试连接
    await ref.read(chatNotifierProvider.notifier).connect();
  }

  final getMessages = ref.watch(getMessagesProvider);
  final result = await getMessages.execute(chatRoomId);
  return result.fold(
    (failure) => [],
    (messages) => messages,
  );
});

// 实时消息流提供者
final messageStreamProvider = StreamProvider<Message>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.messageStream;
});

// 改为使用StateNotifierProvider
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  // 使用从数据层导入的 socketConnectionManagerProvider
  final socketManager = ref.watch(socketConnectionManagerProvider);
  return ChatNotifier(socketManager);
});

// 当前聊天室ID提供者
final currentChatRoomIdProvider = StateProvider<String?>((ref) => null);
