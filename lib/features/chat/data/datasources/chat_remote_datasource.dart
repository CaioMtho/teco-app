import 'package:flutter/foundation.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/chat_entity.dart';

class ChatRemoteDataSource {
  Future<List<ChatEntity>> getUserChats() async {
    debugPrint('[ChatRemoteDataSource] Iniciando carregamento de chats do usuário');
    final client = SupabaseService.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[ChatRemoteDataSource] Usuário não autenticado');
      return <ChatEntity>[];
    }
    debugPrint('[ChatRemoteDataSource] userId obtido: $userId');

    try {
      debugPrint('[ChatRemoteDataSource] Chamando RPC get_user_chats com userId: $userId');
      final rpcResponse = await client.rpc('get_user_chats', params: {'p_user_id': userId});
      debugPrint('[ChatRemoteDataSource] RPC retornou com sucesso, processando dados...');

    final rows = _asListOfMaps(rpcResponse);
    debugPrint('[ChatRemoteDataSource] Processado ${rows.length} linhas de resposta RPC');

    final chats = rows.map((row) {
      debugPrint('[ChatRemoteDataSource] Mapeando chat ID: ${row['chat_id']}, com participante: ${row['participant_name']}');
      final lastMessageId = row['last_message_id'];

      final MessagePreview? lastMessage = lastMessageId != null
          ? MessagePreview(
              id: row['last_message_id']?.toString() ?? '',
              content: row['last_message_content']?.toString(),
              senderId: row['last_message_sender_id']?.toString(),
              createdAt: _dateFromDynamic(row['last_message_created_at']),
              updatedAt: _dateFromDynamic(row['last_message_created_at']),
              deletedAt: null,
            )
          : null;

      return ChatEntity(
        id: row['chat_id']?.toString() ?? '',
        requestId: row['request_id']?.toString() ?? '',
        requestTitle: row['request_title']?.toString() ?? 'Conversa',
        requesterId: row['requester_id']?.toString() ?? '',
        providerId: row['provider_id']?.toString() ?? '',
        participantId: row['participant_id']?.toString() ?? '',
        participantName: row['participant_name']?.toString() ?? 'Pessoa',
        participantAvatarUrl: row['participant_avatar_url']?.toString(),
        createdAt: _dateFromDynamic(row['created_at']),
        updatedAt: _dateFromDynamic(row['last_message_created_at']) ?? _dateFromDynamic(row['created_at']),
        deletedAt: _dateFromDynamic(row['deleted_at']),
        lastMessage: lastMessage,
      ).._debugLog();
    }).toList(growable: false);
    
    debugPrint('[ChatRemoteDataSource] ${chats.length} chats mapeados com sucesso');
    return chats;
    } catch (e, st) {
      debugPrint('[ChatRemoteDataSource] Erro ao carregar chats: $e\nStackTrace: $st');
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

  DateTime? _dateFromDynamic(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

extension on ChatEntity {
  void _debugLog() {
    debugPrint(
      '[Chat mapeado: ID=$id, participante=$participantName, request=$requestTitle, últimaMsg=${lastMessage?.content}',
    );
  }
}
