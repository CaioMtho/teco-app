import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_entity.dart';
import '../providers/chat_providers.dart';

class ChatListPanel extends ConsumerStatefulWidget {
  const ChatListPanel({super.key});

  @override
  ConsumerState<ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends ConsumerState<ChatListPanel> {
  String _search = '';
  bool _onlyWithMessages = false;
  bool _onlyWithAvatar = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[ChatListPanel] initState chamado');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[ChatListPanel] Post frame callback: iniciando load de chats');
      ref.read(chatListNotifierProvider.notifier).load();
    });
  }

  void _openFilterDialog() async {
    debugPrint('[ChatListPanel] Abrindo dialog de filtros');
    final result = await showModalBottomSheet<Map<String, bool>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF222431),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        var hasMessages = _onlyWithMessages;
        var hasAvatar = _onlyWithAvatar;
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filtros', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: hasMessages,
                        onChanged: (v) => setState(() => hasMessages = v),
                        title: const Text('Somente com mensagens', style: TextStyle(color: Colors.white70)),
                      ),
                      SwitchListTile.adaptive(
                        value: hasAvatar,
                        onChanged: (v) => setState(() => hasAvatar = v),
                        title: const Text('Somente com avatar', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(<String, bool>{'hasMessages': false, 'hasAvatar': false}),
                              child: const Text('Limpar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(<String, bool>{'hasMessages': hasMessages, 'hasAvatar': hasAvatar}),
                              child: const Text('Aplicar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      debugPrint('[ChatListPanel] Filtros aplicados: mensagens=${ result['hasMessages']}, avatar=${result['hasAvatar']}');
      setState(() {
        _onlyWithMessages = result['hasMessages'] ?? false;
        _onlyWithAvatar = result['hasAvatar'] ?? false;
      });
    } else {
      debugPrint('[ChatListPanel] Dialog de filtros cancelado');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[ChatListPanel] build chamado');
    final state = ref.watch(chatListNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xDD222431),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: SizedBox(
          height: 42,
          child: TextField(
            onChanged: (v) => setState(() => _search = v.trim()),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar por chats',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                      onPressed: () => setState(() => _search = ''),
                    ),
              filled: true,
              fillColor: const Color(0xFF1E1E23),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openFilterDialog,
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white54),
            tooltip: 'Filtros',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: state.when(
            data: (chats) {
              debugPrint('[ChatListPanel] Estado: sucesso com ${chats.length} chats');
              final filtered = _applyFilters(chats);
              debugPrint('[ChatListPanel] Após filtros: ${filtered.length} chats exibidos');
              return _buildList(filtered);
            },
            loading: () {
              debugPrint('[ChatListPanel] Estado: carregando...');
              return const Center(child: CircularProgressIndicator());
            },
            error: (e, st) {
              debugPrint('[ChatListPanel] Estado: erro\nStackTrace: $st');
              return Center(child: Text('Erro ao carregar chats: $e', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<ChatEntity> chats) {
    if (chats.isEmpty) {
      return const Center(child: Text('Nenhum chat disponível', style: TextStyle(color: Colors.white70)));
    }

    return ListView.separated(
      itemCount: chats.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return _ChatListItem(chat: chat);
      },
    );
  }

  List<ChatEntity> _applyFilters(List<ChatEntity> chats) {
    debugPrint('[ChatListPanel] Aplicando filtros: search="$_search", onlyMessages=$_onlyWithMessages, onlyAvatar=$_onlyWithAvatar');
    return chats.where((c) {
      if (_onlyWithMessages && (c.lastMessage == null)) {
        debugPrint('[ChatListPanel] Chat filtrado (sem mensagens): ${c.participantName}');
        return false;
      }
      if (_onlyWithAvatar && (c.participantAvatarUrl == null || c.participantAvatarUrl!.isEmpty)) {
        debugPrint('[ChatListPanel] Chat filtrado (sem avatar): ${c.participantName}');
        return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final inName = c.participantName.toLowerCase().contains(q);
        final inRequest = c.requestTitle.toLowerCase().contains(q);
        final inMessage = (c.lastMessage?.content ?? '').toLowerCase().contains(q);
        if (!(inName || inRequest || inMessage)) {
          debugPrint('[ChatListPanel] Chat filtrado (não atende busca): ${c.participantName}');
          return false;
        }
      }
      return true;
    }).toList();
  }
}

class _ChatListItem extends StatelessWidget {
  const _ChatListItem({required this.chat});

  final ChatEntity chat;

  @override
  Widget build(BuildContext context) {
    final last = chat.lastMessage;
    final content = (last == null)
        ? 'Sem mensagens ainda.'
        : (last.deletedAt != null
            ? 'Mensagem removida'
            : (last.content?.trim().isEmpty ?? true
                ? 'Mensagem sem texto'
                : last.content!));
    final initials = _initialsFromName(chat.participantName);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF9A7BFF),
            backgroundImage: chat.participantAvatarUrl == null || chat.participantAvatarUrl!.isEmpty
                ? null
                : NetworkImage(chat.participantAvatarUrl!),
            child: chat.participantAvatarUrl == null || chat.participantAvatarUrl!.isEmpty
                ? Text(
                    initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.participantName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  chat.requestTitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ],
      ),
    );
  }

  String _initialsFromName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
