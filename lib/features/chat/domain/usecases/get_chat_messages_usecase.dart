import '../entities/chat_entity.dart';
import '../repositories/chats_repository.dart';

class GetChatMessagesUseCase {
  final ChatMessagesRepository _repository;

  GetChatMessagesUseCase(this._repository);

  Future<List<MessageEntity>> call(String chatId) {
    return _repository.getChatMessages(chatId);
  }
}
