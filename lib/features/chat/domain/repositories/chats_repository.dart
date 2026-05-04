import '../entities/chat_entity.dart';

abstract class ChatsRepository {
  Future<List<ChatEntity>> getUserChats();
}
