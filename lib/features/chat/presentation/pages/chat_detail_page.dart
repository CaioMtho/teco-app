import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/chat_detail_providers.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  const ChatDetailPage({
    super.key,
    required this.chatId,
    required this.requestId,
    required this.participantName,
    required this.participantAvatarUrl,
    required this.requestTitle,
  });

  final String chatId;
  final String requestId;
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

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _proposalAmountController = TextEditingController();
    _proposalMessageController = TextEditingController();

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
    super.dispose();
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    final scaffold = ScaffoldMessenger.of(context);
    try {
      await ref.read(chatDetailNotifierProvider.notifier).sendMessage(widget.chatId, content);
    } catch (e) {
      if (!mounted) return;
      scaffold.showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $e')),
      );
    }
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
          icon: const Icon(Icons.arrow_back_rounded),
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
            Expanded(
              child: detailState.messages.when(
                data: (messages) {
                  final acceptedProposal = detailState.acceptedProposal;
                  final proposals = detailState.proposals.value ?? [];
                  final pendingProposals = proposals.where((p) => p.isPending).toList();

                  final items = <({String type, dynamic data})>[
                    if (acceptedProposal != null)
                      (type: 'acceptedProposal', data: acceptedProposal),
                    ...messages.map((m) => (type: 'message', data: m)),
                    ...pendingProposals.map((p) => (type: 'proposal', data: p)),
                  ];

                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhuma mensagem ou proposta ainda',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.separated(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item.type == 'message') {
                        return _MessageBubble(message: item.data);
                      } else if (item.type == 'proposal') {
                        return _ProposalCard(
                          proposal: item.data,
                          onAccept: () async {
                            try {
                              await ref.read(chatDetailNotifierProvider.notifier).acceptProposal(item.data.id);
                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Proposta aceita')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro: $e')),
                              );
                            }
                          },
                          onDecline: () async {
                            try {
                              await ref.read(chatDetailNotifierProvider.notifier).declineProposal(item.data.id);
                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Proposta recusada')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro: $e')),
                              );
                            }
                          },
                        );
                      } else {
                        return _AcceptedProposalBanner(proposal: item.data);
                      }
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.proposal,
    required this.onAccept,
    required this.onDecline,
  });

  final ProposalEntity proposal;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9A7BFF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proposta',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF9A7BFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Chip(
                label: const Text('Pendente'),
                backgroundColor: const Color(0xFF9A7BFF).withValues(alpha: 0.2),
                labelStyle: const TextStyle(color: Color(0xFF9A7BFF), fontSize: 12),
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
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}

class _AcceptedProposalBanner extends StatelessWidget {
  const _AcceptedProposalBanner({required this.proposal});

  final ProposalEntity proposal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A1B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proposta Aceita',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Chip(
                label: Text('✓ Aceita'),
                backgroundColor: Color(0xFF22C55E),
                labelStyle: TextStyle(color: Colors.white, fontSize: 12),
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
        ],
      ),
    );
  }
}
