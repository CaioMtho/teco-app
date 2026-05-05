import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/chat_entity.dart';
import 'chat_realtime.dart';

class ProposalsRemoteDataSource {
  Future<List<ProposalEntity>> getProposalsByRequestId(String requestId) async {
    debugPrint('[ProposalsRemoteDataSource] Carregando propostas para request: $requestId');
    try {
      final client = SupabaseService.client;
      final response = await client
          .from('proposals')
          .select()
          .eq('request_id', requestId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      final rows = _asListOfMaps(response);
      debugPrint('[ProposalsRemoteDataSource] Carregadas ${rows.length} propostas');

      return rows.map(_mapRowToProposalEntity).toList(growable: false);
    } catch (e, st) {
      debugPrint('[ProposalsRemoteDataSource] Erro ao carregar propostas: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<ProposalEntity> createProposal({
    required String requestId,
    required double amount,
    String? message,
  }) async {
    debugPrint('[ProposalsRemoteDataSource] Criando proposta para request: $requestId, amount: $amount');
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw StateError('No authenticated user found');
      }

      final response = await client
          .from('proposals')
          .insert({
            'request_id': requestId,
            'provider_id': userId,
            'amount': amount,
            'message': message,
            'status': 'pending',
          })
          .select()
          .single();

      debugPrint('[ProposalsRemoteDataSource] Proposta criada com sucesso');
      return _mapRowToProposalEntity(response);
    } catch (e, st) {
      debugPrint('[ProposalsRemoteDataSource] Erro ao criar proposta: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<ProposalEntity> acceptProposal(String proposalId) async {
    debugPrint('[ProposalsRemoteDataSource] Aceitando proposta: $proposalId');
    try {
      final client = SupabaseService.client;
      final response = await client
          .from('proposals')
          .update({'status': 'accepted'})
          .eq('id', proposalId)
          .select()
          .single();

      debugPrint('[ProposalsRemoteDataSource] Proposta aceita com sucesso');
      return _mapRowToProposalEntity(response);
    } catch (e, st) {
      debugPrint('[ProposalsRemoteDataSource] Erro ao aceitar proposta: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<void> declineProposal(String proposalId) async {
    debugPrint('[ProposalsRemoteDataSource] Recusando proposta: $proposalId');
    try {
      final client = SupabaseService.client;
      await client
          .from('proposals')
          .update({'status': 'declined'})
          .eq('id', proposalId);

      debugPrint('[ProposalsRemoteDataSource] Proposta recusada com sucesso');
    } catch (e, st) {
      debugPrint('[ProposalsRemoteDataSource] Erro ao recusar proposta: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Stream<ProposalEntity> listenToChatProposals(String requestId) {
    debugPrint('[ProposalsRemoteDataSource] Iniciando listener para propostas do request: $requestId');
    final client = SupabaseService.client;
    final controller = StreamController<ProposalEntity>();

    final realtime = ChatRealtime(supabase: client, topic: 'proposals:$requestId');

    Future<void> initializeListener() async {
      try {
        await realtime.start(
          onInsert: (record) {
            try {
              final proposal = _mapRowToProposalEntity(record);
              controller.add(proposal);
            } catch (e) {
              debugPrint('[ProposalsRemoteDataSource] Erro ao processar INSERT: $e');
            }
          },
          onUpdate: (record) {
            try {
              final proposal = _mapRowToProposalEntity(record);
              controller.add(proposal);
            } catch (e) {
              debugPrint('[ProposalsRemoteDataSource] Erro ao processar UPDATE: $e');
            }
          },
          onDelete: (oldRecord) {
            try {
              final proposalData = {
                ...oldRecord,
                'deleted_at': DateTime.now().toIso8601String(),
              };
              final proposal = _mapRowToProposalEntity(proposalData);
              controller.add(proposal);
            } catch (e) {
              debugPrint('[ProposalsRemoteDataSource] Erro ao processar DELETE: $e');
            }
          },
        );
      } catch (e) {
        debugPrint('[ProposalsRemoteDataSource] Erro ao inicializar listener: $e');
        controller.addError(e);
      }
    }

    initializeListener();

    controller.onCancel = () {
      realtime.stop();
    };

    return controller.stream;
  }

  ProposalEntity _mapRowToProposalEntity(Map<String, dynamic> row) {
    return ProposalEntity(
      id: row['id']?.toString() ?? '',
      requestId: row['request_id']?.toString() ?? '',
      providerId: row['provider_id']?.toString() ?? '',
      amount: _doubleFromDynamic(row['amount']) ?? 0.0,
      message: row['message']?.toString(),
      status: row['status']?.toString() ?? 'pending',
      createdAt: _dateFromDynamic(row['created_at']),
      updatedAt: _dateFromDynamic(row['updated_at']),
      deletedAt: _dateFromDynamic(row['deleted_at']),
    );
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
