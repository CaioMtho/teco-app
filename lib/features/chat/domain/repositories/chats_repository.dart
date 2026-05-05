import '../entities/chat_entity.dart';

abstract class ChatsRepository {
  Future<List<ChatEntity>> getUserChats();
  Future<ChatEntity> createChatWithMessage({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String providerId,
    required String participantId,
    required String participantName,
    String? participantAvatarUrl,
    required String messageContent,
  });
}

abstract class ChatMessagesRepository {
  Future<List<MessageEntity>> getChatMessages(String chatId);
  Future<MessageEntity> sendMessage(String chatId, String content);
  Stream<MessageEntity> listenToChatMessages(String chatId);
}

abstract class ProposalsRepository {
  Future<List<ProposalEntity>> getProposalsByRequest(String requestId);
  Future<ProposalEntity> createProposal({
    required String requestId,
    required double amount,
    String? message,
  });
  Future<ProposalEntity> acceptProposal(String proposalId);
  Future<void> declineProposal(String proposalId);
  Stream<ProposalEntity> listenToChatProposals(String requestId);
}
