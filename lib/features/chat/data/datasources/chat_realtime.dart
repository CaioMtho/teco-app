import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRealtime {
  final SupabaseClient supabase;
  final String topic;

  RealtimeChannel? _channel;

  ChatRealtime({required this.supabase, required this.topic});

  /// Start listening to channel. Provide callbacks for INSERT/UPDATE/DELETE.
  Future<void> start({
    required void Function(Map<String, dynamic> record) onInsert,
    void Function(Map<String, dynamic> record)? onUpdate,
    void Function(Map<String, dynamic> oldRecord)? onDelete,
  }) async {
    // Authorize realtime client (use current session token)
    final session = supabase.auth.currentSession;
    if (session == null) {
      throw StateError('No authenticated session for realtime');
    }

    await supabase.realtime.setAuth(session.accessToken);

    _channel = supabase.channel(topic, opts: const RealtimeChannelConfig(private: true));

    _channel!
      .onBroadcast(
        event: 'INSERT',
        callback: (payload) {
          final record = payload['payload']?['record'] ?? payload['record'];
          if (record is Map<String, dynamic>) onInsert(record);
        },
      )
      .onBroadcast(
        event: 'UPDATE',
        callback: (payload) {
          final record = payload['payload']?['record'] ?? payload['record'];
          if (record is Map<String, dynamic>) onUpdate?.call(record);
        },
      )
      .onBroadcast(
        event: 'DELETE',
        callback: (payload) {
          final oldRecord = payload['payload']?['old_record'] ?? payload['old_record'];
          if (oldRecord is Map<String, dynamic>) onDelete?.call(oldRecord);
        },
      );

    _channel!.subscribe();
  }

  Future<void> stop() async {
    if (_channel != null) {
      await _channel!.unsubscribe();
      _channel = null;
    }
  }
}
