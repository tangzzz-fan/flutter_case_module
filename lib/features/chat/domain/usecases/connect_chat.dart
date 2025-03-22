import 'package:dartz/dartz.dart';
import '../repositories/chat_repository.dart';
import '../../core/failure.dart';

class ConnectChat {
  final ChatRepository repository;

  ConnectChat(this.repository);

  Future<Either<Failure, bool>> execute() {
    return repository.connect();
  }
}
