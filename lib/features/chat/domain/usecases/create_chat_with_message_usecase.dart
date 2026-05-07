import '../entities/chat_entity.dart';
import '../repositories/chats_repository.dart';

class CreateChatWithMessageUseCase {
  final ChatsRepository _repository;

  CreateChatWithMessageUseCase(this._repository);

  Future<ChatEntity> call({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String providerId,
    required String participantId,
    required String participantName,
    String? participantAvatarUrl,
    required String messageContent,
  }) {
    return _repository.createChatWithMessage(
      requestId: requestId,
      requestTitle: requestTitle,
      requesterId: requesterId,
      providerId: providerId,
      participantId: participantId,
      participantName: participantName,
      participantAvatarUrl: participantAvatarUrl,
      messageContent: messageContent,
    );
  }
}
