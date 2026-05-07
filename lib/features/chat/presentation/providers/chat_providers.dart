import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chats_repository_impl.dart';
import '../../domain/repositories/chats_repository.dart';
import '../../domain/usecases/get_user_chats_usecase.dart';
import '../../domain/usecases/create_chat_with_message_usecase.dart';
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

final createChatWithMessageUseCaseProvider = Provider<CreateChatWithMessageUseCase>((ref) {
  return CreateChatWithMessageUseCase(ref.read(chatsRepositoryProvider));
});

class ChatListNotifier extends StateNotifier<AsyncValue<List<ChatEntity>>> {
  ChatListNotifier(this._getUserChats) : super(const AsyncValue.loading());

  final GetUserChatsUseCase _getUserChats;

  Future<void> load() async {
    debugPrint('[ChatListNotifier] Iniciando carregamento de chats');
    try {
      state = const AsyncValue.loading();
      debugPrint('[ChatListNotifier] Chamando use case getUserChats');
      final chats = await _getUserChats.call();
      debugPrint('[ChatListNotifier] Carregamento sucesso: ${chats.length} chats obtidos');
      state = AsyncValue.data(chats);
    } catch (e, st) {
      debugPrint('[ChatListNotifier] Erro ao carregar chats: $e\nStackTrace: $st');
      state = AsyncValue.error(e, st);
    }
  }
}

final chatListNotifierProvider = StateNotifierProvider<ChatListNotifier, AsyncValue<List<ChatEntity>>>((ref) {
  final notifier = ChatListNotifier(ref.read(getUserChatsUseCaseProvider));
  // don't auto load here; consumer will call load when opening panel
  return notifier;
});
