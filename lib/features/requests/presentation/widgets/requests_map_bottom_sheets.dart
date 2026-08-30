import 'package:flutter/material.dart';
import '../../domain/entities/request_entity.dart';

class RequestDetailsModal extends StatelessWidget {
  const RequestDetailsModal({
    super.key,
    required this.request,
    required this.onClose,
    required this.isProvider,
    required this.onCreateChat,
  });

  final RequestEntity request;
  final VoidCallback onClose;
  final bool isProvider;
  final Future<void> Function() onCreateChat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final description = request.description?.trim();

    return Material(
      elevation: 10,
      color: const Color(0xFF222431),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Fechar',
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    hoverColor: Colors.white10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description != null && description.isNotEmpty
                  ? description
                  : 'Sem descrição para esta requisição.',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: isProvider
                    ? ''
                    : 'Somente prestadores de serviço podem iniciar chats',
                child: FilledButton.icon(
                  onPressed: isProvider ? onCreateChat : null,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Criar chat'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyRequestsModal extends StatelessWidget {
  const MyRequestsModal({
    super.key,
    required this.requests,
    required this.isLoading,
    required this.onClose,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.onCreateRequest,
  });

  final List<RequestEntity> requests;
  final bool isLoading;
  final VoidCallback onClose;
  final VoidCallback onRefresh;
  final ValueChanged<RequestEntity> onEdit;
  final ValueChanged<RequestEntity> onDelete;
  final VoidCallback onCreateRequest;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.62;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      elevation: 10,
      color: const Color(0xFF222431),
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Suas requisicoes abertas',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Nova requisição',
                    child: IconButton(
                      onPressed: onCreateRequest,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: Colors.white,
                      hoverColor: Colors.white10,
                    ),
                  ),
                  Tooltip(
                    message: 'Atualizar lista',
                    child: IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      color: Colors.white,
                      hoverColor: Colors.white10,
                    ),
                  ),
                  Tooltip(
                    message: 'Fechar',
                    child: IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                      hoverColor: Colors.white10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                requests.length == 1
                    ? '1 requisição aberta'
                    : '${requests.length} requisições abertas',
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : requests.isEmpty
                    ? Center(
                        child: Text(
                          'Você não possui requisições abertas no momento.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: requests.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          return MyRequestCard(
                            request: request,
                            onEdit: () => onEdit(request),
                            onDelete: () => onDelete(request),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyRequestCard extends StatelessWidget {
  const MyRequestCard({
    super.key,
    required this.request,
    required this.onEdit,
    required this.onDelete,
  });

  final RequestEntity request;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final description = request.description?.trim();

    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF2A2D3B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: const Text('Aberta'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colorScheme.primary.withOpacity(0.20),
                  labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description != null && description.isNotEmpty
                  ? description
                  : 'Sem descricao.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                RequestMetaChip(
                  icon: Icons.attach_money_rounded,
                  text: request.budgetRange != null
                      ? 'Até R\$ ${request.budgetRange!.toStringAsFixed(2)}'
                      : 'Valor a combinar',
                ),
                RequestMetaChip(
                  icon: request.isRemote == true
                      ? Icons.wifi_rounded
                      : Icons.location_on_outlined,
                  text: request.isRemote == true ? 'Remoto' : 'Presencial',
                ),
                RequestMetaChip(
                  icon: Icons.schedule_rounded,
                  text: _formatDate(request.createdAt),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Excluir'),
                    style: FilledButton.styleFrom(
                      foregroundColor: colorScheme.onErrorContainer,
                      backgroundColor: colorScheme.errorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Sem data';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

class RequestMetaChip extends StatelessWidget {
  const RequestMetaChip({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class RequestEditPayload {
  const RequestEditPayload({
    required this.title,
    required this.description,
    required this.budgetRange,
    required this.isRemote,
  });

  final String title;
  final String? description;
  final double? budgetRange;
  final bool isRemote;
}

class EditRequestSheet extends StatefulWidget {
  const EditRequestSheet({super.key, required this.request});

  final RequestEntity request;

  @override
  State<EditRequestSheet> createState() => _EditRequestSheetState();
}

class _EditRequestSheetState extends State<EditRequestSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _budgetRangeController;
  late bool _isRemote;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.request.title);
    _descriptionController = TextEditingController(
      text: widget.request.description,
    );
    _budgetRangeController = TextEditingController(
      text: widget.request.budgetRange?.toString() ?? '',
    );
    _isRemote = widget.request.isRemote ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetRangeController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um título para a requisição.')),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    final budgetText = _budgetRangeController.text.trim().replaceAll(',', '.');
    final budgetRange = budgetText.isNotEmpty ? double.tryParse(budgetText) : null;

    setState(() {
      _isSaving = true;
    });

    Navigator.of(context).pop(
      RequestEditPayload(
        title: title,
        description: description.isEmpty ? null : description,
        budgetRange: budgetRange,
        isRemote: _isRemote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final colorScheme = Theme.of(context).colorScheme;
    const inputTextColor = Colors.white;
    const inputLabelColor = Colors.white70;
    const inputHintColor = Colors.white54;

    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white38),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
    );

    InputDecoration decoration({required String label, String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF2A2D3B),
        border: enabledBorder,
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
        labelStyle: const TextStyle(color: inputLabelColor),
        hintStyle: const TextStyle(color: inputHintColor),
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar requisição',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: inputTextColor),
              cursorColor: colorScheme.primary,
              decoration: decoration(label: 'Título'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              textInputAction: TextInputAction.newline,
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(color: inputTextColor),
              cursorColor: colorScheme.primary,
              decoration: decoration(
                label: 'Descrição',
                hint:
                    'Ex.: Notebook não liga após atualização. Preciso de diagnóstico e possível troca de peça.',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _budgetRangeController,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: inputTextColor),
              cursorColor: colorScheme.primary,
              decoration: decoration(
                label: 'Até quanto pode pagar',
                hint: 'Ex.: R\$ 600',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _isRemote,
              onChanged: (value) {
                setState(() {
                  _isRemote = value;
                });
              },
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Aceita trabalho remoto',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar alteracoes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RequestCreatePayload {
  const RequestCreatePayload({
    required this.title,
    required this.description,
    required this.budgetRange,
    required this.isRemote,
    required this.lat,
    required this.lon,
  });

  final String title;
  final String? description;
  final double? budgetRange;
  final bool isRemote;
  final double lat;
  final double lon;
}

class CreateRequestSheet extends StatefulWidget {
  const CreateRequestSheet({
    super.key,
    required this.initialLat,
    required this.initialLon,
  });

  final double initialLat;
  final double initialLon;

  @override
  State<CreateRequestSheet> createState() => _CreateRequestSheetState();
}

class _CreateRequestSheetState extends State<CreateRequestSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  String? _titleError;
  String? _budgetError;
  bool _isRemote = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final budgetText = _budgetController.text.trim().replaceAll(',', '.');
    final budgetRange = budgetText.isNotEmpty
        ? double.tryParse(budgetText)
        : null;
    final titleError = title.isEmpty
        ? 'Informe um título para a requisição.'
        : null;
    final budgetError = budgetText.isNotEmpty && budgetRange == null
        ? 'Informe um valor numérico válido.'
        : null;

    if (titleError != null || budgetError != null) {
      setState(() {
        _titleError = titleError;
        _budgetError = budgetError;
      });
      return;
    }

    setState(() {
      _titleError = null;
      _budgetError = null;
      _isSaving = true;
    });

    Navigator.of(context).pop(
      RequestCreatePayload(
        title: title,
        description: description.isEmpty ? null : description,
        budgetRange: budgetRange,
        isRemote: _isRemote,
        lat: widget.initialLat,
        lon: widget.initialLon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final colorScheme = Theme.of(context).colorScheme;
    const inputTextColor = Colors.white;
    const inputLabelColor = Colors.white70;
    const inputHintColor = Colors.white54;

    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white38),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.error),
    );

    InputDecoration decoration({
      required String label,
      String? hint,
      String? errorText,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: const Color(0xFF2A2D3B),
        border: enabledBorder,
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        labelStyle: const TextStyle(color: inputLabelColor),
        hintStyle: const TextStyle(color: inputHintColor),
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nova requisição',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: inputTextColor),
              cursorColor: colorScheme.primary,
              onChanged: (_) {
                if (_titleError != null) {
                  setState(() {
                    _titleError = null;
                  });
                }
              },
              decoration: decoration(label: 'Título *', errorText: _titleError),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              textInputAction: TextInputAction.newline,
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(color: inputTextColor),
              cursorColor: colorScheme.primary,
              decoration: decoration(
                label: 'Descrição',
                hint:
                    'Ex.: Computador lento, sem acesso à internet e impressora não conecta. Preciso de suporte presencial.',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _budgetController,
              textInputAction: TextInputAction.done,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: inputTextColor),
              cursorColor: colorScheme.primary,
              onChanged: (_) {
                if (_budgetError != null) {
                  setState(() {
                    _budgetError = null;
                  });
                }
              },
              decoration: decoration(
                label: 'Até quanto pode pagar (R\$)',
                hint: 'Ex.: 500',
                errorText: _budgetError,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _isRemote,
              onChanged: (value) => setState(() => _isRemote = value),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Aceita trabalho remoto',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.white38,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Localização: ${widget.initialLat.toStringAsFixed(5)}, '
                    '${widget.initialLon.toStringAsFixed(5)}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.white54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Criar requisição'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
