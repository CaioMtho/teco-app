import '../entities/chat_entity.dart';
import '../repositories/chats_repository.dart';

class GetProposalsByRequestUseCase {
  final ProposalsRepository _repository;

  GetProposalsByRequestUseCase(this._repository);

  Future<List<ProposalEntity>> call(String requestId) {
    return _repository.getProposalsByRequest(requestId);
  }
}
