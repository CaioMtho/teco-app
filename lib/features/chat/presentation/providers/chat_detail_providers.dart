import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/chat_messages_remote_datasource.dart';
import '../../data/datasources/proposals_remote_datasource.dart';
import '../../data/datasources/transactions_remote_datasource.dart';
import '../../data/repositories/chat_messages_repository_impl.dart';
import '../../data/repositories/proposals_repository_impl.dart';
import '../../data/repositories/transactions_repository_impl.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/chats_repository.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../../domain/usecases/accept_proposal_usecase.dart';
import '../../domain/usecases/create_proposal_usecase.dart';
import '../../domain/usecases/create_transaction_usecase.dart';
import '../../domain/usecases/decline_proposal_usecase.dart';
import '../../domain/usecases/get_chat_messages_usecase.dart';
import '../../domain/usecases/get_proposals_by_request_usecase.dart';
import '../../domain/usecases/get_transaction_by_proposal_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/update_transaction_status_usecase.dart';
import '../../../requests/domain/usecases/update_request_status_usecase.dart';
import '../../../requests/presentation/providers/requests_providers.dart' hide updateRequestStatusUseCaseProvider;

// Datasource Providers
final chatMessagesRemoteDataSourceProvider = Provider<ChatMessagesRemoteDataSource>((ref) {
  return ChatMessagesRemoteDataSource();
});

final proposalsRemoteDataSourceProvider = Provider<ProposalsRemoteDataSource>((ref) {
  return ProposalsRemoteDataSource();
});

final transactionsRemoteDataSourceProvider = Provider<TransactionsRemoteDataSource>((ref) {
  return TransactionsRemoteDataSource();
});

// Repository Providers
final chatMessagesRepositoryProvider = Provider<ChatMessagesRepository>((ref) {
  return ChatMessagesRepositoryImpl(ref.read(chatMessagesRemoteDataSourceProvider));
});

final proposalsRepositoryProvider = Provider<ProposalsRepository>((ref) {
  return ProposalsRepositoryImpl(ref.read(proposalsRemoteDataSourceProvider));
});

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepositoryImpl(ref.read(transactionsRemoteDataSourceProvider));
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

final createTransactionUseCaseProvider = Provider<CreateTransactionUseCase>((ref) {
  return CreateTransactionUseCase(ref.read(transactionsRepositoryProvider));
});

final getTransactionByProposalUseCaseProvider = Provider<GetTransactionByProposalUseCase>((ref) {
  return GetTransactionByProposalUseCase(ref.read(transactionsRepositoryProvider));
});

final updateTransactionStatusUseCaseProvider = Provider<UpdateTransactionStatusUseCase>((ref) {
  return UpdateTransactionStatusUseCase(ref.read(transactionsRepositoryProvider));
});

final updateRequestStatusUseCaseProvider = Provider<UpdateRequestStatusUseCase>((ref) {
  return UpdateRequestStatusUseCase(ref.read(requestsRepositoryProvider));
});

class ChatDetailState {
  final AsyncValue<List<MessageEntity>> messages;
  final AsyncValue<List<ProposalEntity>> proposals;
  final AsyncValue<TransactionEntity?> paymentTransaction;

  const ChatDetailState({
    required this.messages,
    required this.proposals,
    required this.paymentTransaction,
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
    AsyncValue<TransactionEntity?>? paymentTransaction,
  }) {
    return ChatDetailState(
      messages: messages ?? this.messages,
      proposals: proposals ?? this.proposals,
      paymentTransaction: paymentTransaction ?? this.paymentTransaction,
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
    this._createTransaction,
    this._getTransactionByProposal,
    this._updateTransactionStatus,
    this._updateRequestStatus,
    this._messagesRepository,
    this._proposalsRepository,
  ) : super(
    const ChatDetailState(
      messages: AsyncValue.loading(),
      proposals: AsyncValue.loading(),
      paymentTransaction: AsyncValue.data(null),
    ),
  );

  final GetChatMessagesUseCase _getChatMessages;
  final SendMessageUseCase _sendMessage;
  final CreateProposalUseCase _createProposal;
  final AcceptProposalUseCase _acceptProposal;
  final DeclineProposalUseCase _declineProposal;
  final GetProposalsByRequestUseCase _getProposalsByRequest;
  final CreateTransactionUseCase _createTransaction;
  final GetTransactionByProposalUseCase _getTransactionByProposal;
  final UpdateTransactionStatusUseCase _updateTransactionStatus;
  final UpdateRequestStatusUseCase _updateRequestStatus;
  final ChatMessagesRepository _messagesRepository;
  final ProposalsRepository _proposalsRepository;

  // Subscription management
  StreamSubscription<MessageEntity>? _messagesSubscription;
  StreamSubscription<ProposalEntity>? _proposalsSubscription;
  bool _isSubscribed = false;
  final List<MessageEntity> _pendingMessageUpdates = [];
  final List<ProposalEntity> _pendingProposalUpdates = [];
  final Set<String> _pendingRemovedProposalIds = <String>{};

  Future<void> load(String chatId, String requestId) async {
    debugPrint('[ChatDetailNotifier] Carregando chat $chatId e request $requestId');
    try {
      state = state.copyWith(
        messages: const AsyncValue.loading(),
        proposals: const AsyncValue.loading(),
        paymentTransaction: const AsyncValue.data(null),
      );

      final messages = await _getChatMessages.call(chatId);
      final proposals = await _getProposalsByRequest.call(requestId);
      final acceptedProposal = proposals.where((proposal) => proposal.isAccepted).isNotEmpty
          ? proposals.firstWhere((proposal) => proposal.isAccepted)
          : null;
      final paymentTransaction = acceptedProposal == null
          ? null
          : await _getTransactionByProposal.call(acceptedProposal.id);

      state = state.copyWith(
        messages: AsyncValue.data(_mergeAndSortMessages(messages, _pendingMessageUpdates)),
        proposals: AsyncValue.data(
          _mergeAndSortProposals(
            proposals.where((proposal) => !_pendingRemovedProposalIds.contains(proposal.id)).toList(),
            _pendingProposalUpdates,
          ),
        ),
        paymentTransaction: AsyncValue.data(paymentTransaction),
      );
      _pendingMessageUpdates.clear();
      _pendingProposalUpdates.clear();
      _pendingRemovedProposalIds.clear();

      debugPrint('[ChatDetailNotifier] Carregamento concluído: ${messages.length} mensagens, ${proposals.length} propostas');
    } catch (e, st) {
      debugPrint('[ChatDetailNotifier] Erro ao carregar: $e\nStackTrace: $st');
      state = state.copyWith(
        messages: AsyncValue.error(e, st),
        proposals: AsyncValue.error(e, st),
        paymentTransaction: AsyncValue.error(e, st),
      );
    }
  }

  Future<void> subscribeToUpdates(String chatId, String requestId) async {
    debugPrint('[ChatDetailNotifier] Abrindo realtime listeners para chat $chatId e request $requestId');
    
    // Avoid duplicate subscriptions
    if (_isSubscribed) {
      debugPrint('[ChatDetailNotifier] Já inscrito. Ignorando segunda chamada.');
      return;
    }
    _isSubscribed = true;

    try {
      _messagesSubscription = _messagesRepository.listenToChatMessages(chatId).listen(
        (message) {
          debugPrint('[ChatDetailNotifier] Mensagem realtime recebida: ${message.id}');
          _applyMessageUpdate(message);
        },
        onError: (e, st) {
          debugPrint('[ChatDetailNotifier] Erro no listener de mensagens: $e');
        },
      );

      _proposalsSubscription = _proposalsRepository.listenToChatProposals(requestId).listen(
        (proposal) {
          debugPrint('[ChatDetailNotifier] Proposta realtime recebida: ${proposal.id}');
          _applyProposalUpdate(proposal);
        },
        onError: (e, st) {
          debugPrint('[ChatDetailNotifier] Erro no listener de propostas: $e');
        },
      );
    } catch (e, st) {
      debugPrint('[ChatDetailNotifier] Erro ao abrir listeners: $e\nStackTrace: $st');
      _isSubscribed = false;
    }
  }

  @override
  void dispose() {
    debugPrint('[ChatDetailNotifier] Cancelando subscrições realtime');
    _messagesSubscription?.cancel();
    _proposalsSubscription?.cancel();
    _isSubscribed = false;
    super.dispose();
  }

  Future<void> sendMessage(String chatId, String content) async {
    debugPrint('[ChatDetailNotifier] Enviando mensagem para chat $chatId');
    try {
      final message = await _sendMessage.call(chatId, content);
      _applyMessageUpdate(message);
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
      _applyProposalUpdate(proposal);
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
      _applyProposalUpdate(updated);
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
      _removeProposal(proposalId);
      debugPrint('[ChatDetailNotifier] Proposta recusada com sucesso');
    } catch (e, st) {
      debugPrint('[ChatDetailNotifier] Erro ao recusar proposta: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<TransactionEntity> startPaymentForProposal(ProposalEntity proposal) async {
    final currentTransaction = state.paymentTransaction.valueOrNull;
    if (currentTransaction != null && currentTransaction.proposalId == proposal.id) {
      return currentTransaction;
    }

    final transaction = await _createTransaction.call(
      proposalId: proposal.id,
      amount: proposal.amount,
    );
    state = state.copyWith(paymentTransaction: AsyncValue.data(transaction));
    return transaction;
  }

  Future<TransactionEntity> confirmPayment({
    required String requestId,
    required TransactionEntity transaction,
  }) async {
    final updatedTransaction = await _updateTransactionStatus.call(
      transactionId: transaction.id,
      status: 'escrow',
    );
    await _updateRequestStatus.call(
      requestId: requestId,
      status: 'in_progress',
    );
    state = state.copyWith(paymentTransaction: AsyncValue.data(updatedTransaction));
    return updatedTransaction;
  }

  Future<TransactionEntity> completeRequest({
    required String requestId,
    required TransactionEntity transaction,
  }) async {
    final updatedTransaction = await _updateTransactionStatus.call(
      transactionId: transaction.id,
      status: 'released',
    );
    await _updateRequestStatus.call(
      requestId: requestId,
      status: 'completed',
    );
    state = state.copyWith(paymentTransaction: AsyncValue.data(updatedTransaction));
    return updatedTransaction;
  }

  Future<void> cancelUnpaidProposal({
    required String requestId,
    required String proposalId,
  }) async {
    await declineProposal(proposalId);
    await _updateRequestStatus.call(
      requestId: requestId,
      status: 'open',
    );
    state = state.copyWith(paymentTransaction: const AsyncValue.data(null));
  }

  void _applyMessageUpdate(MessageEntity message) {
    final currentMessages = state.messages.valueOrNull;
    if (currentMessages == null) {
      _pendingMessageUpdates.removeWhere((item) => item.id == message.id);
      _pendingMessageUpdates.add(message);
      return;
    }

    final updated = _mergeAndSortMessages(currentMessages, [message]);
    state = state.copyWith(messages: AsyncValue.data(updated));
  }

  void _applyProposalUpdate(ProposalEntity proposal) {
    _pendingRemovedProposalIds.remove(proposal.id);
    final currentProposals = state.proposals.valueOrNull;
    if (currentProposals == null) {
      _pendingProposalUpdates.removeWhere((item) => item.id == proposal.id);
      _pendingProposalUpdates.add(proposal);
      return;
    }

    final updated = _mergeAndSortProposals(currentProposals, [proposal]);
    state = state.copyWith(proposals: AsyncValue.data(updated));
  }

  void _removeProposal(String proposalId) {
    _pendingRemovedProposalIds.add(proposalId);
    final currentProposals = state.proposals.valueOrNull;
    if (currentProposals == null) {
      _pendingProposalUpdates.removeWhere((item) => item.id == proposalId);
      return;
    }

    final updated = currentProposals.where((proposal) => proposal.id != proposalId).toList();
    state = state.copyWith(proposals: AsyncValue.data(updated));
  }

  List<MessageEntity> _mergeAndSortMessages(
    List<MessageEntity> base,
    List<MessageEntity> updates,
  ) {
    final merged = <String, MessageEntity>{
      for (final message in base) message.id: message,
      for (final message in updates) message.id: message,
    };

    final sorted = merged.values.toList()
      ..sort((a, b) => _compareDateTimeAscending(a.createdAt, b.createdAt));
    return sorted;
  }

  List<ProposalEntity> _mergeAndSortProposals(
    List<ProposalEntity> base,
    List<ProposalEntity> updates,
  ) {
    final merged = <String, ProposalEntity>{
      for (final proposal in base) proposal.id: proposal,
      for (final proposal in updates) proposal.id: proposal,
    };

    final sorted = merged.values.toList()
      ..sort((a, b) => _compareDateTimeAscending(a.createdAt, b.createdAt));
    return sorted;
  }

  int _compareDateTimeAscending(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
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
    ref.read(createTransactionUseCaseProvider),
    ref.read(getTransactionByProposalUseCaseProvider),
    ref.read(updateTransactionStatusUseCaseProvider),
    ref.read(updateRequestStatusUseCaseProvider),
    ref.read(chatMessagesRepositoryProvider),
    ref.read(proposalsRepositoryProvider),
  );
});
