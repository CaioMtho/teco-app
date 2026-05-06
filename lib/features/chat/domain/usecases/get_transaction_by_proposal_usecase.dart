import '../entities/transaction_entity.dart';
import '../repositories/transactions_repository.dart';

class GetTransactionByProposalUseCase {
  GetTransactionByProposalUseCase(this._repository);

  final TransactionsRepository _repository;

  Future<TransactionEntity?> call(String proposalId) {
    return _repository.getTransactionByProposalId(proposalId);
  }
}