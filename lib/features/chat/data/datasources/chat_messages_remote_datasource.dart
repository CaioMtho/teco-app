import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/chat_entity.dart';
import 'chat_realtime.dart';

class ChatMessagesRemoteDataSource {
  Future<List<MessageEntity>> getChatMessages(String chatId) async {
    debugPrint('[ChatMessagesRemoteDataSource] Iniciando carregamento de mensagens para chat: $chatId');
    try {
      final client = SupabaseService.client;
      final response = await client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: true);

      final rows = _asListOfMaps(response);
      debugPrint('[ChatMessagesRemoteDataSource] Carregadas ${rows.length} mensagens');

      return rows.map(_mapRowToMessageEntity).toList(growable: false);
    } catch (e, st) {
      debugPrint('[ChatMessagesRemoteDataSource] Erro ao carregar mensagens: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<MessageEntity> sendMessage(String chatId, String content) async {
    debugPrint('[ChatMessagesRemoteDataSource] Enviando mensagem para chat: $chatId');
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw StateError('No authenticated user found');
      }

      final response = await client
          .from('messages')
          .insert({
            'chat_id': chatId,
            'sender_id': userId,
            'content': content,
          })
          .select()
          .single();

      debugPrint('[ChatMessagesRemoteDataSource] Mensagem enviada com sucesso');
      return _mapRowToMessageEntity(response);
    } catch (e, st) {
      debugPrint('[ChatMessagesRemoteDataSource] Erro ao enviar mensagem: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Stream<MessageEntity> listenToChatMessages(String chatId) {
    debugPrint('[ChatMessagesRemoteDataSource] Iniciando listener para chat: $chatId');
    final client = SupabaseService.client;
    final controller = StreamController<MessageEntity>();

    final realtime = ChatRealtime(supabase: client, topic: 'chat:$chatId');

    Future<void> initializeListener() async {
      try {
        await realtime.start(
          onInsert: (record) {
            try {
              final message = _mapRowToMessageEntity(record);
              controller.add(message);
            } catch (e) {
              debugPrint('[ChatMessagesRemoteDataSource] Erro ao processar INSERT: $e');
            }
          },
          onUpdate: (record) {
            try {
              final message = _mapRowToMessageEntity(record);
              controller.add(message);
            } catch (e) {
              debugPrint('[ChatMessagesRemoteDataSource] Erro ao processar UPDATE: $e');
            }
          },
          onDelete: (oldRecord) {
            try {
              final messageData = {
                ...oldRecord,
                'deleted_at': DateTime.now().toIso8601String(),
              };
              final message = _mapRowToMessageEntity(messageData);
              controller.add(message);
            } catch (e) {
              debugPrint('[ChatMessagesRemoteDataSource] Erro ao processar DELETE: $e');
            }
          },
        );
      } catch (e) {
        debugPrint('[ChatMessagesRemoteDataSource] Erro ao inicializar listener: $e');
        controller.addError(e);
      }
    }

    initializeListener();

    controller.onCancel = () {
      realtime.stop();
    };

    return controller.stream;
  }

  MessageEntity _mapRowToMessageEntity(Map<String, dynamic> row) {
    return MessageEntity(
      id: row['id']?.toString() ?? '',
      chatId: row['chat_id']?.toString() ?? '',
      senderId: row['sender_id']?.toString() ?? '',
      content: row['content']?.toString(),
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
}
