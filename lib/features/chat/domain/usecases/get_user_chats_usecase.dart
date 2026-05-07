import '../entities/chat_entity.dart';
import '../repositories/chats_repository.dart';

class GetUserChatsUseCase {
  final ChatsRepository _repository;

  GetUserChatsUseCase(this._repository);

  Future<List<ChatEntity>> call() {
    return _repository.getUserChats();
  }
}
