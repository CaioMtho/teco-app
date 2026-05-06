import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../datasources/transactions_remote_datasource.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl(this._remoteDataSource);

  final TransactionsRemoteDataSource _remoteDataSource;

  @override
  Future<TransactionEntity> createTransaction({
    required String proposalId,
    required double amount,
  }) {
    return _remoteDataSource.createTransaction(
      proposalId: proposalId,
      amount: amount,
    );
  }

  @override
  Future<TransactionEntity?> getTransactionByProposalId(String proposalId) {
    return _remoteDataSource.getTransactionByProposalId(proposalId);
  }

  @override
  Future<TransactionEntity> updateTransactionStatus({
    required String transactionId,
    required String status,
  }) {
    return _remoteDataSource.updateTransactionStatus(
      transactionId: transactionId,
      status: status,
    );
  }
}