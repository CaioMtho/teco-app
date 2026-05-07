import '../entities/chat_entity.dart';
import '../repositories/chats_repository.dart';

class AcceptProposalUseCase {
  final ProposalsRepository _repository;

  AcceptProposalUseCase(this._repository);

  Future<ProposalEntity> call(String proposalId) {
    return _repository.acceptProposal(proposalId);
  }
}
