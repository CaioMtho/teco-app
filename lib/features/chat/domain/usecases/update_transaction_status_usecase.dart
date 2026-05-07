import '../entities/transaction_entity.dart';
import '../repositories/transactions_repository.dart';

class UpdateTransactionStatusUseCase {
  UpdateTransactionStatusUseCase(this._repository);

  final TransactionsRepository _repository;

  Future<TransactionEntity> call({
    required String transactionId,
    required String status,
  }) {
    return _repository.updateTransactionStatus(
      transactionId: transactionId,
      status: status,
    );
  }
}