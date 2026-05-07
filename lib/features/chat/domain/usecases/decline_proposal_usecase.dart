import '../repositories/chats_repository.dart';

class DeclineProposalUseCase {
  final ProposalsRepository _repository;

  DeclineProposalUseCase(this._repository);

  Future<void> call(String proposalId) {
    return _repository.declineProposal(proposalId);
  }
}
