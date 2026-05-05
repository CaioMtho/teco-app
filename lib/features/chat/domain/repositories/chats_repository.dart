import '../entities/chat_entity.dart';

abstract class ChatsRepository {
  Future<List<ChatEntity>> getUserChats();
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
