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
}
