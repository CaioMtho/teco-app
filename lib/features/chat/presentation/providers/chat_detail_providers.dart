import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/chat_messages_remote_datasource.dart';
import '../../data/datasources/proposals_remote_datasource.dart';
import '../../data/repositories/chat_messages_repository_impl.dart';
import '../../data/repositories/proposals_repository_impl.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chats_repository.dart';
import '../../domain/usecases/accept_proposal_usecase.dart';
import '../../domain/usecases/create_proposal_usecase.dart';
import '../../domain/usecases/decline_proposal_usecase.dart';
import '../../domain/usecases/get_chat_messages_usecase.dart';
import '../../domain/usecases/get_proposals_by_request_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';

// Datasource Providers
final chatMessagesRemoteDataSourceProvider = Provider<ChatMessagesRemoteDataSource>((ref) {
  return ChatMessagesRemoteDataSource();
});

final proposalsRemoteDataSourceProvider = Provider<ProposalsRemoteDataSource>((ref) {
  return ProposalsRemoteDataSource();
});

// Repository Providers
final chatMessagesRepositoryProvider = Provider<ChatMessagesRepository>((ref) {
  return ChatMessagesRepositoryImpl(ref.read(chatMessagesRemoteDataSourceProvider));
});

final proposalsRepositoryProvider = Provider<ProposalsRepository>((ref) {
  return ProposalsRepositoryImpl(ref.read(proposalsRemoteDataSourceProvider));
});

// Use Case Providers
final getChatMessagesUseCaseProvider = Provider<GetChatMessagesUseCase>((ref) {
  return GetChatMessagesUseCase(ref.read(chatMessagesRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.read(chatMessagesRepositoryProvider));
});

final createProposalUseCaseProvider = Provider<CreateProposalUseCase>((ref) {
  return CreateProposalUseCase(ref.read(proposalsRepositoryProvider));
});

final acceptProposalUseCaseProvider = Provider<AcceptProposalUseCase>((ref) {
  return AcceptProposalUseCase(ref.read(proposalsRepositoryProvider));
});

final declineProposalUseCaseProvider = Provider<DeclineProposalUseCase>((ref) {
  return DeclineProposalUseCase(ref.read(proposalsRepositoryProvider));
});

final getProposalsByRequestUseCaseProvider = Provider<GetProposalsByRequestUseCase>((ref) {
  return GetProposalsByRequestUseCase(ref.read(proposalsRepositoryProvider));
});

class ChatDetailState {
  final AsyncValue<List<MessageEntity>> messages;
  final AsyncValue<List<ProposalEntity>> proposals;

  const ChatDetailState({
    required this.messages,
    required this.proposals,
  });

  ProposalEntity? get acceptedProposal {
    return proposals.whenData((list) {
      try {
        return list.firstWhere((p) => p.isAccepted);
      } catch (e) {
        return null;
      }
    }).value;
  }

  ChatDetailState copyWith({
    AsyncValue<List<MessageEntity>>? messages,
    AsyncValue<List<ProposalEntity>>? proposals,
  }) {
    return ChatDetailState(
      messages: messages ?? this.messages,
      proposals: proposals ?? this.proposals,
    );
  }
}

class ChatDetailNotifier extends StateNotifier<ChatDetailState> {
  ChatDetailNotifier(
    this._getChatMessages,
    this._sendMessage,
    this._createProposal,
    this._acceptProposal,
    this._declineProposal,
    this._getProposalsByRequest,
    this._messagesRepository,
    this._proposalsRepository,
  ) : super(
    const ChatDetailState(
      messages: AsyncValue.loading(),
      proposals: AsyncValue.loading(),
    ),
  );

  final GetChatMessagesUseCase _getChatMessages;
  final SendMessageUseCase _sendMessage;
  final CreateProposalUseCase _createProposal;
  final AcceptProposalUseCase _acceptProposal;
  final DeclineProposalUseCase _declineProposal;
  final GetProposalsByRequestUseCase _getProposalsByRequest;
  final ChatMessagesRepository _messagesRepository;
  final ProposalsRepository _proposalsRepository;

  Future<void> load(String chatId, String requestId) async {
    debugPrint('[ChatDetailNotifier] Carregando chat $chatId e request $requestId');
    try {
      state = state.copyWith(
        messages: const AsyncValue.loading(),
        proposals: const AsyncValue.loading(),
      );

      final messages = await _getChatMessages.call(chatId);
      final proposals = await _getProposalsByRequest.call(requestId);

      state = state.copyWith(
        messages: AsyncValue.data(messages),
        proposals: AsyncValue.data(proposals),
      );

      debugPrint('[ChatDetailNotifier] Carregamento concluído: ${messages.length} mensagens, ${proposals.length} propostas');
    } catch (e, st) {
      debugPrint('[ChatDetailNotifier] Erro ao carregar: $e\nStackTrace: $st');
      state = state.copyWith(
        messages: AsyncValue.error(e, st),
        proposals: AsyncValue.error(e, st),
      );
    }
  }

  Future<void> subscribeToUpdates(String chatId, String requestId) async {
    debugPrint('[ChatDetailNotifier] Abrindo realtime listeners para chat $chatId e request $requestId');
    try {
      _messagesRepository.listenToChatMessages(chatId).listen(
        (message) {
          debugPrint('[ChatDetailNotifier] Mensagem realtime recebida: ${message.id}');
          state.messages.whenData((messages) {
            final updated = _updateOrAddMessage(messages, message);
            state = state.copyWith(messages: AsyncValue.data(updated));
          });
        },
        onError: (e, st) {
          debugPrint('[ChatDetailNotifier] Erro no listener de mensagens: $e');
        },
      );

      _proposalsRepository.listenToChatProposals(requestId).listen(
        (proposal) {
          debugPrint('[ChatDetailNotifier] Proposta realtime recebida: ${proposal.id}');
          state.proposals.whenData((proposals) {
            final updated = _updateOrAddProposal(proposals, proposal);
            state = state.copyWith(proposals: AsyncValue.data(updated));
          });
        },
        onError: (e, st) {
          debugPrint('[ChatDetailNotifier] Erro no listener de propostas: $e');
        },
      );
    } catch (e, st) {
      debugPrint('[ChatDetailNotifier] Erro ao abrir listeners: $e\nStackTrace: $st');
    }
  }

  Future<void> sendMessage(String chatId, String content) async {
    debugPrint('[ChatDetailNotifier] Enviando mensagem para chat $chatId');
    try {
      final message = await _sendMessage.call(chatId, content);
      state.messages.whenData((messages) {
        state = state.copyWith(messages: AsyncValue.data([...messages, message]));
      });
      debugPrint('[ChatDetailNotifier] Mensagem enviada com sucesso');
    } catch (e, st) {
      debugPrint('[ChatDetailNotifier] Erro ao enviar mensagem: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<void> createProposal(String requestId, double amount, String? message) async {
    debugPrint('[ChatDetailNotifier] Criando proposta para request $requestId, amount: $amount');
    try {
      final proposal = await _createProposal.call(
        requestId: requestId,
        amount: amount,
        message: message,
      );
      state.proposals.whenData((proposals) {
        state = state.copyWith(proposals: AsyncValue.data([...proposals, proposal]));
      });
      debugPrint('[ChatDetailNotifier] Proposta criada com sucesso');
    } catch (e, st) {
      debugPrint('[ChatDetailNotifier] Erro ao criar proposta: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<void> acceptProposal(String proposalId) async {
    debugPrint('[ChatDetailNotifier] Aceitando proposta $proposalId');
    try {
      final updated = await _acceptProposal.call(proposalId);
      state.proposals.whenData((proposals) {
        final newList = proposals.map((p) => p.id == proposalId ? updated : p).toList();
        state = state.copyWith(proposals: AsyncValue.data(newList));
      });
      debugPrint('[ChatDetailNotifier] Proposta aceita com sucesso');
    } catch (e, st) {
      debugPrint('[ChatDetailNotifier] Erro ao aceitar proposta: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<void> declineProposal(String proposalId) async {
    debugPrint('[ChatDetailNotifier] Recusando proposta $proposalId');
    try {
      await _declineProposal.call(proposalId);
      state.proposals.whenData((proposals) {
        final newList = proposals.where((p) => p.id != proposalId).toList();
        state = state.copyWith(proposals: AsyncValue.data(newList));
      });
      debugPrint('[ChatDetailNotifier] Proposta recusada com sucesso');
    } catch (e, st) {
      debugPrint('[ChatDetailNotifier] Erro ao recusar proposta: $e\nStackTrace: $st');
      rethrow;
    }
  }

  List<MessageEntity> _updateOrAddMessage(List<MessageEntity> messages, MessageEntity newMessage) {
    final index = messages.indexWhere((m) => m.id == newMessage.id);
    if (index >= 0) {
      final updated = messages.toList();
      updated[index] = newMessage;
      return updated;
    }
    return [...messages, newMessage];
  }

  List<ProposalEntity> _updateOrAddProposal(List<ProposalEntity> proposals, ProposalEntity newProposal) {
    final index = proposals.indexWhere((p) => p.id == newProposal.id);
    if (index >= 0) {
      final updated = proposals.toList();
      updated[index] = newProposal;
      return updated;
    }
    return [...proposals, newProposal];
  }
}

final chatDetailNotifierProvider = StateNotifierProvider<ChatDetailNotifier, ChatDetailState>((ref) {
  return ChatDetailNotifier(
    ref.read(getChatMessagesUseCaseProvider),
    ref.read(sendMessageUseCaseProvider),
    ref.read(createProposalUseCaseProvider),
    ref.read(acceptProposalUseCaseProvider),
    ref.read(declineProposalUseCaseProvider),
    ref.read(getProposalsByRequestUseCaseProvider),
    ref.read(chatMessagesRepositoryProvider),
    ref.read(proposalsRepositoryProvider),
  );
});
