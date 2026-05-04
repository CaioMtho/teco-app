import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chats_repository_impl.dart';
import '../../domain/repositories/chats_repository.dart';
import '../../domain/usecases/get_user_chats_usecase.dart';
import '../../domain/entities/chat_entity.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource();
});

final chatsRepositoryProvider = Provider<ChatsRepository>((ref) {
  return ChatsRepositoryImpl(ref.read(chatRemoteDataSourceProvider));
});

final getUserChatsUseCaseProvider = Provider<GetUserChatsUseCase>((ref) {
  return GetUserChatsUseCase(ref.read(chatsRepositoryProvider));
});

class ChatListNotifier extends StateNotifier<AsyncValue<List<ChatEntity>>> {
  ChatListNotifier(this._getUserChats) : super(const AsyncValue.loading());

  final GetUserChatsUseCase _getUserChats;

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final chats = await _getUserChats.call();
      state = AsyncValue.data(chats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final chatListNotifierProvider = StateNotifierProvider<ChatListNotifier, AsyncValue<List<ChatEntity>>>((ref) {
  final notifier = ChatListNotifier(ref.read(getUserChatsUseCaseProvider));
  // don't auto load here; consumer will call load when opening panel
  return notifier;
});
