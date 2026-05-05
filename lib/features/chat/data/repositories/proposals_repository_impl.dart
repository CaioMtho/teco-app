import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chats_repository.dart';
import '../datasources/proposals_remote_datasource.dart';

class ProposalsRepositoryImpl implements ProposalsRepository {
  final ProposalsRemoteDataSource _remote;

  ProposalsRepositoryImpl(this._remote);

  @override
  Future<List<ProposalEntity>> getProposalsByRequest(String requestId) {
    return _remote.getProposalsByRequestId(requestId);
  }

  @override
  Future<ProposalEntity> createProposal({
    required String requestId,
    required double amount,
    String? message,
  }) {
    return _remote.createProposal(
      requestId: requestId,
      amount: amount,
      message: message,
    );
  }

  @override
  Future<ProposalEntity> acceptProposal(String proposalId) {
    return _remote.acceptProposal(proposalId);
  }

  @override
  Future<void> declineProposal(String proposalId) {
    return _remote.declineProposal(proposalId);
  }

  @override
  Stream<ProposalEntity> listenToChatProposals(String requestId) {
    return _remote.listenToChatProposals(requestId);
  }
}
