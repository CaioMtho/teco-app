import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_current_user_profile_usecase.dart';
import '../../domain/usecases/update_current_user_profile_usecase.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileRepository _profileRepository =
      ProfileRepositoryImpl(ProfileRemoteDataSource());

  late final GetCurrentUserProfileUseCase _getCurrentUserProfileUseCase =
      GetCurrentUserProfileUseCase(_profileRepository);
  late final UpdateCurrentUserProfileUseCase
      _updateCurrentUserProfileUseCase =
      UpdateCurrentUserProfileUseCase(_profileRepository);

  ProfileEntity? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _getCurrentUserProfileUseCase.call();
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _profileLoadErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openEditSheet() async {
    final profile = _profile;
    if (profile == null) {
      return;
    }

    final payload = await showModalBottomSheet<_ProfileEditPayload>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EditProfileSheet(profile: profile),
    );

    if (payload == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile = await _updateCurrentUserProfileUseCase.call(
        fullName: payload.fullName,
        cpfCnpj: payload.cpfCnpj,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = updatedProfile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel atualizar o perfil.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final email = SupabaseService.client.auth.currentUser?.email;
    final accountLabel = email ?? 'Sessao nao autenticada';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B1E2A), Color(0xFF0F1115)],
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadProfile,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.of(context).size.height - 88,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProfileHeader(
                              onBack: () => Navigator.of(context).pop(),
                              onEdit: _openEditSheet,
                            ),
                            const SizedBox(height: 20),
                            if (_errorMessage != null)
                              _ProfileErrorCard(
                                message: _errorMessage!,
                                onRetry: _loadProfile,
                              )
                            else if (profile != null) ...[
                              _ProfileHero(
                                profile: profile,
                                email: accountLabel,
                              ),
                              const SizedBox(height: 20),
                              _ProfileSectionCard(
                                title: 'Informacoes da conta',
                                subtitle:
                                    'O que aparece aqui vem do seu registro em profiles.',
                                children: [
                                  _ProfileInfoRow(
                                    label: 'Nome completo',
                                    value: profile.fullName,
                                  ),
                                  _ProfileInfoRow(
                                    label: 'E-mail',
                                    value: accountLabel,
                                  ),
                                  _ProfileInfoRow(
                                    label: 'CPF/CNPJ',
                                    value: _formatCpfCnpjForDisplay(
                                      profile.cpfCnpj,
                                    ),
                                  ),
                                  _ProfileInfoRow(
                                    label: 'Tipo',
                                    value: _formatLabel(profile.type),
                                  ),
                                  _ProfileInfoRow(
                                    label: 'Verificacao',
                                    value: profile.isVerified == true
                                        ? 'Verificado'
                                        : 'Nao verificado',
                                  ),
                                  _ProfileInfoRow(
                                    label: 'Localizacao',
                                    value: profile.locationLabel ??
                                        'Nao informada',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _ProfileSectionCard(
                                title: 'Dados de sincronizacao',
                                subtitle:
                                    'Campos apenas para consulta nesta versao.',
                                children: [
                                  _ProfileInfoRow(
                                    label: 'Criado em',
                                    value: _formatDateTime(profile.createdAt),
                                  ),
                                  _ProfileInfoRow(
                                    label: 'Atualizado em',
                                    value: _formatDateTime(profile.updatedAt),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: _isSaving ? null : _openEditSheet,
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Editar informacoes'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          if (_isSaving)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

String _profileLoadErrorMessage(Object error) {
  if (error is ProfileAuthRequiredException) {
    return 'Voce precisa estar autenticado para carregar seu perfil.';
  }

  if (error is ProfileNotFoundException) {
    return 'Perfil nao encontrado para o usuario autenticado.';
  }

  final raw = error.toString();
  if (raw.isEmpty) {
    return 'Nao foi possivel carregar o perfil.';
  }

  return raw.length > 220 ? '${raw.substring(0, 220)}...' : raw;
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onBack, required this.onEdit});

  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        _HeaderActionButton(
          tooltip: 'Voltar',
          icon: Icons.close_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Perfil',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        _HeaderActionButton(
          tooltip: 'Editar',
          icon: Icons.edit_rounded,
          onTap: onEdit,
          color: colorScheme.primary,
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.email});

  final ProfileEntity profile;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final profileTypeLabel = _formatLabel(profile.type);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2F3E), Color(0xFF1D2130)],
        ),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _ProfileAvatar(url: profile.avatarUrl, fullName: profile.fullName),
          const SizedBox(height: 16),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            email ?? 'Nao informado',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _ProfileBadge(
                icon: profile.isVerified == true
                    ? Icons.verified_rounded
                    : Icons.info_outline_rounded,
                label: profile.isVerified == true
                    ? 'Verificado'
                    : 'Conta nao verificada',
              ),
              _ProfileBadge(
                icon: Icons.badge_rounded,
                label: profileTypeLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.url, required this.fullName});

  final String? url;
  final String fullName;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFromName(fullName);

    return Container(
      width: 148,
      height: 148,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF7B61FF), Color(0xFF145CFF)],
        ),
      ),
      child: CircleAvatar(
        radius: 70,
        backgroundColor: const Color(0xFF343846),
        backgroundImage: url != null && url!.trim().isNotEmpty
            ? NetworkImage(url!)
            : null,
        child: url != null && url!.trim().isNotEmpty
            ? null
            : Text(
                initials,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 22,
          hoverColor: Colors.white10,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: color ?? Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileErrorCard extends StatelessWidget {
  const _ProfileErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1720),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile});

  final ProfileEntity profile;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _cpfCnpjController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _cpfCnpjController = TextEditingController(
      text: _formatCpfCnpjForInput(widget.profile.cpfCnpj),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _cpfCnpjController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      _ProfileEditPayload(
        fullName: _fullNameController.text.trim(),
        cpfCnpj: _normalizeCpfCnpj(_cpfCnpjController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar perfil',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ajuste seu nome e CPF/CNPJ. Os outros dados permanecem apenas para consulta.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe seu nome completo';
                    }
                    if (value.trim().length < 3) {
                      return 'Nome muito curto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cpfCnpjController,
                  decoration: const InputDecoration(
                    labelText: 'CPF/CNPJ',
                    hintText: 'Opcional',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9./\- ]')),
                  ],
                  validator: (value) => _validateCpfCnpj(value),
                ),
                const SizedBox(height: 14),
                Text(
                  'Digite apenas CPF com 11 digitos ou CNPJ com 14 digitos. Pontuacao e aceita, mas sera normalizada ao salvar.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileEditPayload {
  const _ProfileEditPayload({required this.fullName, required this.cpfCnpj});

  final String fullName;
  final String? cpfCnpj;
}

String _initialsFromName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return 'U';
  }

  if (parts.length == 1) {
    final first = parts.first;
    return first.length >= 2 ? first.substring(0, 2).toUpperCase() : first.substring(0, 1).toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _formatLabel(String value) {
  final normalized = value.replaceAll('_', ' ').trim();
  if (normalized.isEmpty) {
    return 'Nao informado';
  }

  return normalized
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Nao informado';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}

String _formatCpfCnpjForDisplay(String? value) {
  final digits = _onlyDigits(value);
  if (digits.isEmpty) {
    return 'Nao informado';
  }

  return _formatCpfCnpjDigits(digits);
}

String _formatCpfCnpjForInput(String? value) {
  final digits = _onlyDigits(value);
  if (digits.isEmpty) {
    return '';
  }

  return _formatCpfCnpjDigits(digits);
}

String _formatCpfCnpjDigits(String digits) {
  if (digits.length <= 11) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write('.');
      }
      if (i == 9) {
        buffer.write('-');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i == 2 || i == 5) {
      buffer.write('.');
    }
    if (i == 8) {
      buffer.write('/');
    }
    if (i == 12) {
      buffer.write('-');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String? _validateCpfCnpj(String? value) {
  final digits = _onlyDigits(value);
  if (digits.isEmpty) {
    return null;
  }

  if (digits.length != 11 && digits.length != 14) {
    return 'CPF deve ter 11 digitos ou CNPJ 14 digitos';
  }

  if (_allDigitsEqual(digits)) {
    return 'Documento invalido';
  }

  return null;
}

String? _normalizeCpfCnpj(String? value) {
  final digits = _onlyDigits(value);
  if (digits.isEmpty) {
    return null;
  }

  return digits;
}

String _onlyDigits(String? value) {
  if (value == null) {
    return '';
  }

  return value.replaceAll(RegExp(r'\D'), '');
}

bool _allDigitsEqual(String digits) {
  if (digits.isEmpty) {
    return false;
  }

  return digits.split('').every((digit) => digit == digits[0]);
}
