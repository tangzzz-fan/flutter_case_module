import 'package:dartz/dartz.dart';
import '../repositories/chat_repository.dart';
import '../entities/message.dart';
import '../../core/failure.dart';

class GetMessages {
  final ChatRepository repository;

  GetMessages(this.repository);

  Future<Either<Failure, List<Message>>> execute(String chatRoomId) {
    return repository.getMessages(chatRoomId);
  }
}
