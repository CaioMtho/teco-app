import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chats_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatsRepositoryImpl implements ChatsRepository {
  final ChatRemoteDataSource _remote;

  ChatsRepositoryImpl(this._remote);

  @override
  Future<List<ChatEntity>> getUserChats() {
    return _remote.getUserChats();
  }

  @override
  Future<ChatEntity> createChatWithMessage({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String providerId,
    required String participantId,
    required String participantName,
    String? participantAvatarUrl,
    required String messageContent,
  }) {
    return _remote.createChatWithMessage(
      requestId: requestId,
      requestTitle: requestTitle,
      requesterId: requesterId,
      providerId: providerId,
      participantId: participantId,
      participantName: participantName,
      participantAvatarUrl: participantAvatarUrl,
      messageContent: messageContent,
    );
  }
}
