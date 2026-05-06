import 'package:flutter/foundation.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionsRemoteDataSource {
  Future<TransactionEntity> createTransaction({
    required String proposalId,
    required double amount,
  }) async {
    debugPrint('[TransactionsRemoteDataSource] Criando transação para proposal: $proposalId');
    try {
      final response = await SupabaseService.client
          .from('transactions')
          .insert({
            'proposal_id': proposalId,
            'amount': amount,
            'status': 'pending',
          })
          .select()
          .single();

      return _mapRowToTransactionEntity(Map<String, dynamic>.from(response as Map));
    } catch (e, st) {
      debugPrint('[TransactionsRemoteDataSource] Erro ao criar transação: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<TransactionEntity?> getTransactionByProposalId(String proposalId) async {
    debugPrint('[TransactionsRemoteDataSource] Buscando transação por proposal: $proposalId');
    try {
      final response = await SupabaseService.client
          .from('transactions')
          .select()
          .eq('proposal_id', proposalId)
          .order('created_at', ascending: false)
          .limit(1);

      final rows = _asListOfMaps(response);
      if (rows.isEmpty) {
        return null;
      }

      return _mapRowToTransactionEntity(rows.first);
    } catch (e, st) {
      debugPrint('[TransactionsRemoteDataSource] Erro ao buscar transação: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<TransactionEntity> updateTransactionStatus({
    required String transactionId,
    required String status,
  }) async {
    debugPrint('[TransactionsRemoteDataSource] Atualizando transação: id=$transactionId, status=$status');
    try {
      final response = await SupabaseService.client
          .from('transactions')
          .update({'status': status})
          .eq('id', transactionId)
          .select()
          .single();

      return _mapRowToTransactionEntity(Map<String, dynamic>.from(response as Map));
    } catch (e, st) {
      debugPrint('[TransactionsRemoteDataSource] Erro ao atualizar transação: $e\nStackTrace: $st');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
    if (value == null) return <Map<String, dynamic>>[];
    if (value is List) {
      return value.map((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).where((m) => m.isNotEmpty).toList(growable: false);
    }
    return <Map<String, dynamic>>[];
  }

  TransactionEntity _mapRowToTransactionEntity(Map<String, dynamic> row) {
    return TransactionEntity(
      id: row['id']?.toString() ?? '',
      proposalId: row['proposal_id']?.toString() ?? '',
      amount: _doubleFromDynamic(row['amount']) ?? 0.0,
      status: row['status']?.toString() ?? 'pending',
      createdAt: _dateFromDynamic(row['created_at']),
      updatedAt: _dateFromDynamic(row['updated_at']),
    );
  }

  DateTime? _dateFromDynamic(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  double? _doubleFromDynamic(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}