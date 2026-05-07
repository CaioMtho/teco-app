import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/chat_detail_providers.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  const ChatDetailPage({
    super.key,
    required this.chatId,
    required this.requestId,
    required this.requesterId,
    required this.participantName,
    required this.participantAvatarUrl,
    required this.requestTitle,
  });

  final String chatId;
  final String requestId;
  final String requesterId;
  final String participantName;
  final String? participantAvatarUrl;
  final String requestTitle;

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  late final TextEditingController _messageController;
  late final TextEditingController _proposalAmountController;
  late final TextEditingController _proposalMessageController;
  late final ScrollController _listViewController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _proposalAmountController = TextEditingController();
    _proposalMessageController = TextEditingController();
    _listViewController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatDetailNotifierProvider.notifier).load(widget.chatId, widget.requestId);
      ref.read(chatDetailNotifierProvider.notifier).subscribeToUpdates(widget.chatId, widget.requestId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _proposalAmountController.dispose();
    _proposalMessageController.dispose();
    _listViewController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    final scaffold = ScaffoldMessenger.of(context);
    try {
      await ref.read(chatDetailNotifierProvider.notifier).sendMessage(widget.chatId, content);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      scaffold.showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $e')),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_listViewController.hasClients) {
        _listViewController.animateTo(
          _listViewController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCreateProposalDialog() async {
    _proposalAmountController.clear();
    _proposalMessageController.clear();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222431),
        title: const Text('Criar Proposta', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _proposalAmountController,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor da proposta (R\$)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1E1E23),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _proposalMessageController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Mensagem (opcional)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1E1E23),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(_proposalAmountController.text);
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Valor inválido')),
                );
                return;
              }
              Navigator.pop(context, {
                'amount': amount,
                'message': _proposalMessageController.text.trim().isEmpty
                    ? null
                    : _proposalMessageController.text.trim(),
              });
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (result == null) return;

    // ignore: use_build_context_synchronously
    final scaffold = ScaffoldMessenger.of(context);
    try {
      await ref.read(chatDetailNotifierProvider.notifier).createProposal(
        widget.requestId,
        result['amount'],
        result['message'],
      );
      if (!mounted) return;
      scaffold.showSnackBar(
        const SnackBar(content: Text('Proposta criada com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;
      scaffold.showSnackBar(
        SnackBar(content: Text('Erro ao criar proposta: $e')),
      );
    }
  }

  Future<void> _showRatingDialog() async {
    int rating = 0;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF222431),
            title: const Text('Avalie este pedido', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Avaliação opcional de 5 estrelas', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    return IconButton(
                      onPressed: () => setState(() => rating = idx),
                      icon: Icon(
                        Icons.star,
                        color: idx <= rating ? Colors.amber : Colors.white24,
                      ),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Pular'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Enviar'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _showProposalPaymentSheet(
    ProposalEntity proposal, {
    required bool isRequester,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101114),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _ProposalPaymentSheet(
          proposal: proposal,
          requestId: widget.requestId,
          isRequester: isRequester,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(chatDetailNotifierProvider);
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    final isProvider = authState.whenData((state) {
      return state.profile?.type == 'provider';
    }).value ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xDD222431),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.requestTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.participantName,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky proposal header
            detailState.proposals.when(
              data: (proposals) {
                final acceptedProposal = detailState.acceptedProposal;
                final pendingProposals = proposals.where((p) => p.isPending).toList();
                final visibleProposal = acceptedProposal ?? (pendingProposals.isNotEmpty ? pendingProposals.first : null);

                if (visibleProposal != null) {
                  final isRequester = authState.whenData((state) {
                    return state.user?.id == widget.requesterId;
                  }).value ?? false;

                  return _StickyProposalHeader(
                    proposal: visibleProposal,
                    isRequester: isRequester,
                    paymentTransaction: detailState.paymentTransaction.valueOrNull,
                    onAccept: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref.read(chatDetailNotifierProvider.notifier).acceptProposal(visibleProposal.id);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Proposta aceita')),
                        );
                        await _showProposalPaymentSheet(visibleProposal, isRequester: isRequester);
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    },
                    onCancel: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref.read(chatDetailNotifierProvider.notifier).declineProposal(visibleProposal.id);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Proposta cancelada')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    },
                    onDecline: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref.read(chatDetailNotifierProvider.notifier).declineProposal(visibleProposal.id);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Proposta recusada')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    },
                    onComplete: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final txn = detailState.paymentTransaction.valueOrNull;
                      if (txn == null) return;
                      try {
                        await ref.read(chatDetailNotifierProvider.notifier).completeRequest(
                          requestId: widget.requestId,
                          transaction: txn,
                        );
                        if (!mounted) return;
                        await _showRatingDialog();
                        if (!mounted) return;
                        messenger.showSnackBar(const SnackBar(content: Text('Tarefa marcada como concluída')));
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text('Erro ao concluir tarefa: $e')));
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            // Messages ListView
            Expanded(
              child: detailState.messages.when(
                data: (messages) {
                  final items = messages.map((m) => (type: 'message', data: m)).toList();

                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhuma mensagem ainda',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.separated(
                    controller: _listViewController,
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _MessageBubble(message: item.data);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Text(
                    'Erro ao carregar chat: $e',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ),
              ),
            ),
            Container(
              color: const Color(0xFF1A1A1F),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Mensagem...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF252A33),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded, color: Colors.white70),
                  ),
                  if (isProvider) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _showCreateProposalDialog,
                      icon: const Icon(Icons.local_offer_rounded, color: Color(0xFF9A7BFF)),
                      tooltip: 'Criar Proposta',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.message});

  final MessageEntity message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isOwn = authState.whenData((state) {
      return state.user?.id == message.senderId;
    }).value ?? false;

    if (message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            'Mensagem removida',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white38,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isOwn ? const Color(0xFF9A7BFF) : const Color(0xFF2A2D3B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content ?? '',
              style: TextStyle(
                color: isOwn ? Colors.white : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: isOwn ? Colors.white60 : Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StickyProposalHeader extends StatelessWidget {
  const _StickyProposalHeader({
    required this.proposal,
    required this.isRequester,
    required this.paymentTransaction,
    required this.onAccept,
    required this.onCancel,
    required this.onDecline,
    this.onComplete,
  });

  final ProposalEntity proposal;
  final bool isRequester;
  final TransactionEntity? paymentTransaction;
  final VoidCallback onAccept;
  final VoidCallback onCancel;
  final VoidCallback onDecline;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final isAccepted = proposal.isAccepted;
    final transaction = paymentTransaction;
    final isEscrow = transaction?.isEscrow ?? false;
    final isReleased = transaction?.isReleased ?? false;
    final backgroundColor = isAccepted ? const Color(0xFF1B3A1B) : const Color(0xFF2A2F3E);
    final borderColor = isAccepted ? Colors.green : const Color(0xFF9A7BFF);
    final titleColor = isAccepted ? Colors.green : const Color(0xFF9A7BFF);
    final title = isReleased
      ? 'Tarefa concluída'
      : isEscrow
        ? 'Pagamento confirmado'
        : isAccepted
          ? 'Proposta aceita'
          : 'Proposta';
    final statusLabel = isReleased
      ? '✓ Liberada'
      : isEscrow
        ? 'Em escrow'
        : isAccepted
          ? 'Pagamento pendente'
          : 'Pendente';
    final statusBgColor = (isReleased || isEscrow)
      ? const Color(0xFF22C55E)
      : const Color(0xFF9A7BFF).withValues(alpha: 0.2);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Chip(
                label: Text(statusLabel),
                backgroundColor: statusBgColor,
                labelStyle: TextStyle(
                  color: isAccepted ? Colors.white : const Color(0xFF9A7BFF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ ${proposal.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (proposal.message != null && proposal.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              proposal.message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
          if (!isAccepted) ...[
            const SizedBox(height: 12),
            if (isRequester) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      child: const Text('Recusar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF9A7BFF),
                      ),
                      child: const Text('Aceitar'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text('Cancelar Proposta'),
                ),
              ),
            ],
          ] else if (!isReleased) ...[
            const SizedBox(height: 12),
            if (isEscrow && isRequester) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onComplete,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                  child: const Text('Marcar como concluída'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    backgroundColor: isEscrow ? const Color(0xFF22C55E) : const Color(0xFF9A7BFF),
                  ),
                  child: Text(
                    isEscrow ? 'Aguardando conclusão' : 'Aguardando pagamento',
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProposalPaymentSheet extends ConsumerStatefulWidget {
  const _ProposalPaymentSheet({
    required this.proposal,
    required this.requestId,
    required this.isRequester,
  });

  final ProposalEntity proposal;
  final String requestId;
  final bool isRequester;

  @override
  ConsumerState<_ProposalPaymentSheet> createState() => _ProposalPaymentSheetState();
}

class _ProposalPaymentSheetState extends ConsumerState<_ProposalPaymentSheet> {
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatDetailNotifierProvider.notifier).startPaymentForProposal(widget.proposal);
    });
  }

  Future<void> _confirmPayment(TransactionEntity transaction) async {
    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(chatDetailNotifierProvider.notifier).confirmPayment(
        requestId: widget.requestId,
        transaction: transaction,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Pagamento confirmado')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Erro ao confirmar pagamento: $e')));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _completeTask(TransactionEntity transaction) async {
    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(chatDetailNotifierProvider.notifier).completeRequest(
        requestId: widget.requestId,
        transaction: transaction,
      );
      if (!mounted) return;
      await _showRatingDialog();
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Tarefa marcada como concluída')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Erro ao concluir tarefa: $e')));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _showRatingDialog() async {
    int rating = 0;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF222431),
            title: const Text('Avalie este pedido', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Avaliação opcional de 5 estrelas', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    return IconButton(
                      onPressed: () => setState(() => rating = idx),
                      icon: Icon(
                        Icons.star,
                        color: idx <= rating ? Colors.amber : Colors.white24,
                      ),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Pular'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Enviar'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _cancelUnpaid() async {
    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(chatDetailNotifierProvider.notifier).cancelUnpaidProposal(
        requestId: widget.requestId,
        proposalId: widget.proposal.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Proposta cancelada')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Erro ao cancelar: $e')));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = ref.watch(chatDetailNotifierProvider).paymentTransaction.valueOrNull;
    final isReleased = transaction?.isReleased ?? false;
    final isEscrow = (transaction?.isEscrow ?? false) && !isReleased;
    final isPending = (transaction?.isPending ?? false) && !isReleased && !isEscrow;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pagamento da proposta',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isBusy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'R\$ ${widget.proposal.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              transaction == null
                  ? 'Preparando transação de pagamento.'
                  : isReleased
                      ? 'Pagamento liberado.'
                      : isEscrow
                          ? 'Pagamento confirmado e request em andamento.'
                          : 'Pagamento aguardando confirmação.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            if (transaction != null) ...[
              if (isReleased) ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                    const SizedBox(width: 8),
                    Text('Tarefa concluída', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Color(0xFF22C55E))),
                  ],
                ),
                const SizedBox(height: 12),
              ] else if (isEscrow && !widget.isRequester) ...[
                Row(
                  children: [
                    const Icon(Icons.hourglass_top, color: Colors.white54),
                    const SizedBox(width: 8),
                    Text('Aguardando conclusão pelo requester', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
            const SizedBox(height: 20),
            if (transaction == null) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (isReleased) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: null,
                  child: const Text('Tarefa concluída'),
                ),
              ),
            ] else if (isEscrow && widget.isRequester) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isBusy ? null : () => _completeTask(transaction),
                  child: const Text('Marcar como concluída'),
                ),
              ),
            ] else if (isPending) ...[
              if (widget.isRequester) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isBusy ? null : () => _confirmPayment(transaction),
                    child: const Text('Confirmar pagamento'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isBusy ? null : _cancelUnpaid,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('Cancelar sem pagar'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: null,
                  child: const Text('Aguardando conclusão'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
