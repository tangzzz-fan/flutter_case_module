import 'package:dartz/dartz.dart';
import '../repositories/chat_repository.dart';
import '../entities/message.dart';
import '../../core/failure.dart';

class SendMessage {
  final ChatRepository repository;

  SendMessage(this.repository);

  Future<Either<Failure, Message>> execute(
    String chatRoomId,
    String content,
    MessageType type,
    String senderId,
  ) {
    return repository.sendMessage(
      chatRoomId,
      content,
      type,
      senderId,
    );
  }
}
