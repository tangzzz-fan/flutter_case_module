import 'package:dartz/dartz.dart';
import '../repositories/chat_repository.dart';
import '../entities/chat_room.dart';
import '../../core/failure.dart';

class GetChatRooms {
  final ChatRepository repository;

  GetChatRooms(this.repository);

  Future<Either<Failure, List<ChatRoom>>> execute() {
    return repository.getChatRooms();
  }
}
