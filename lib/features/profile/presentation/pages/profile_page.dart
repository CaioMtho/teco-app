import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/exceptions/profile_exceptions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_notifier.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/password_change_sheet.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja encerrar sua sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openEditSheet(BuildContext context, WidgetRef ref, ProfileEntity profile) async {
    final payload = await showModalBottomSheet<ProfileEditPayload>(
      context: context,
      backgroundColor: const Color(0xFF222431),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => EditProfileSheet(profile: profile),
    );

    if (payload == null) return;
    
    try {
      await ref.read(profileNotifierProvider.notifier).updateProfile(
        fullName: payload.fullName,
        cpfCnpj: payload.cpfCnpj,
        location: payload.location,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar o perfil.')),
      );
    }
  }

  Future<void> _openPasswordSheet(BuildContext context, WidgetRef ref) async {
    final payload = await showModalBottomSheet<PasswordChangePayload>(
      context: context,
      backgroundColor: const Color(0xFF222431),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const PasswordChangeSheet(),
    );

    if (payload == null) return;

    try {
      await ref.read(authControllerProvider.notifier).updatePassword(password: payload.password);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha atualizada com sucesso.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar a senha.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final isSaving = profileAsync.isLoading && profileAsync.hasValue;
    
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
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _ProfileErrorCard(
                message: _profileLoadErrorMessage(error),
                onRetry: () => ref.invalidate(profileNotifierProvider),
              ),
              data: (profile) {
                final email = ref.watch(authControllerProvider).valueOrNull?.user?.email;
                final accountLabel = email ?? 'Sessão não autenticada';
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(profileNotifierProvider);
                    try {
                      await ref.read(profileNotifierProvider.future);
                    } catch (_) {}
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 88,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileHeader(
                            onBack: () => Navigator.of(context).pop(),
                            onEdit: () => _openEditSheet(context, ref, profile),
                          ),
                          const SizedBox(height: 20),
                          _ProfileHero(profile: profile, email: accountLabel),
                          const SizedBox(height: 20),
                          _ProfileSectionCard(
                            title: 'Informações da conta',
                            subtitle: 'O que aparece aqui vem do seu registro em profiles.',
                            children: [
                              _ProfileInfoRow(label: 'Nome completo', value: profile.fullName),
                              _ProfileInfoRow(label: 'E-mail', value: accountLabel),
                              _ProfileInfoRow(label: 'CPF/CNPJ', value: _formatCpfCnpjForDisplay(profile.cpfCnpj)),
                              _ProfileInfoRow(label: 'Tipo', value: _formatLabel(profile.type)),
                              _ProfileInfoRow(
                                label: 'Verificação',
                                value: profile.isVerified == true ? 'Verificado' : 'Não verificado',
                              ),
                              _ProfileInfoRow(
                                label: 'Localização',
                                value: profile.locationLabel ?? 'Não informada',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: isSaving ? null : () => _openEditSheet(context, ref, profile),
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Editar informações'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: isSaving ? null : () => _openPasswordSheet(context, ref),
                            icon: const Icon(Icons.lock_reset_rounded),
                            label: const Text('Trocar senha'),
                          ),
                          const SizedBox(height: 22),
                          OutlinedButton.icon(
                            onPressed: () => _logout(context, ref),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Sair da conta'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isSaving)
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
    return 'Você precisa estar autenticado para carregar seu perfil.';
  }

  if (error is ProfileNotFoundException) {
    return 'Perfil não encontrado para o usuário autenticado.';
  }

  final raw = error.toString();
  if (raw.isEmpty) {
    return 'Não foi possível carregar o perfil.';
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
            email ?? 'Não informado',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
                    : 'Conta não verificada',
              ),
              _ProfileBadge(icon: Icons.badge_rounded, label: profileTypeLabel),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white54),
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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
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
            child: Icon(icon, color: color ?? Colors.white),
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
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
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

String _initialsFromName(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'U';
  }

  if (parts.length == 1) {
    final first = parts.first;
    return first.length >= 2
        ? first.substring(0, 2).toUpperCase()
        : first.substring(0, 1).toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _formatLabel(String value) {
  final normalized = value.replaceAll('_', ' ').trim();
  if (normalized.isEmpty) {
    return 'Não informado';
  }

  return normalized
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String _formatCpfCnpjForDisplay(String? value) {
  final digits = _onlyDigits(value);
  if (digits.isEmpty) {
    return 'Não informado';
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

String _onlyDigits(String? value) {
  if (value == null) {
    return '';
  }

  return value.replaceAll(RegExp(r'\D'), '');
}
