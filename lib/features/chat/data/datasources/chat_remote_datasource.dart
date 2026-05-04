import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/chat_entity.dart';

class ChatRemoteDataSource {
  Future<List<ChatEntity>> getUserChats() async {
    final client = SupabaseService.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return <ChatEntity>[];
    }

    final rpcResponse = await client.rpc('get_user_chats', params: {'p_user_id': userId});

    final rows = _asListOfMaps(rpcResponse);

    final chats = rows.map((row) {
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
      );
    }).toList(growable: false);

    return chats;
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
