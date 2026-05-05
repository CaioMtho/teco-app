import '../entities/chat_entity.dart';
import '../repositories/chats_repository.dart';

class CreateProposalUseCase {
  final ProposalsRepository _repository;

  CreateProposalUseCase(this._repository);

  Future<ProposalEntity> call({
    required String requestId,
    required double amount,
    String? message,
  }) {
    return _repository.createProposal(
      requestId: requestId,
      amount: amount,
      message: message,
    );
  }
}
