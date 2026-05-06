import '../entities/transaction_entity.dart';
import '../repositories/transactions_repository.dart';

class CreateTransactionUseCase {
  CreateTransactionUseCase(this._repository);

  final TransactionsRepository _repository;

  Future<TransactionEntity> call({
    required String proposalId,
    required double amount,
  }) {
    return _repository.createTransaction(
      proposalId: proposalId,
      amount: amount,
    );
  }
}