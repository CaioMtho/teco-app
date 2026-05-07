import '../entities/chat_entity.dart';
import '../repositories/chats_repository.dart';

class SendMessageUseCase {
  final ChatMessagesRepository _repository;

  SendMessageUseCase(this._repository);

  Future<MessageEntity> call(String chatId, String content) {
    return _repository.sendMessage(chatId, content);
  }
}
