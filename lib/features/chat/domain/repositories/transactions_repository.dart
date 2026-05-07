import '../entities/transaction_entity.dart';

abstract class TransactionsRepository {
  Future<TransactionEntity> createTransaction({
    required String proposalId,
    required double amount,
  });

  Future<TransactionEntity?> getTransactionByProposalId(String proposalId);

  Future<TransactionEntity> updateTransactionStatus({
    required String transactionId,
    required String status,
  });
}