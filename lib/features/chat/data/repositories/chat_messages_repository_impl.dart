import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chats_repository.dart';
import '../datasources/chat_messages_remote_datasource.dart';

class ChatMessagesRepositoryImpl implements ChatMessagesRepository {
  final ChatMessagesRemoteDataSource _remote;

  ChatMessagesRepositoryImpl(this._remote);

  @override
  Future<List<MessageEntity>> getChatMessages(String chatId) {
    return _remote.getChatMessages(chatId);
  }

  @override
  Future<MessageEntity> sendMessage(String chatId, String content) {
    return _remote.sendMessage(chatId, content);
  }

  @override
  Stream<MessageEntity> listenToChatMessages(String chatId) {
    return _remote.listenToChatMessages(chatId);
  }
}
