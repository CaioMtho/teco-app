import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

  Future<void> _logout() async {
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);

    await SupabaseService.client.auth.signOut();
  }

  Future<void> _openEditSheet() async {
    final profile = _profile;
    if (profile == null) {
      return;
    }

    final payload = await showModalBottomSheet<_ProfileEditPayload>(
      context: context,
      backgroundColor: const Color(0xFF222431),
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
        location: payload.location,
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
          content: Text('Não foi possível atualizar o perfil.'),
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
    final accountLabel = email ?? 'Sessão não autenticada';

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
                                title: 'Informações da conta',
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
                                    label: 'Verificação',
                                    value: profile.isVerified == true
                                        ? 'Verificado'
                                        : 'Não verificado',
                                  ),
                                  _ProfileInfoRow(
                                    label: 'Localização',
                                    value: profile.locationLabel ??
                                        'Não informada',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: _isSaving ? null : _openEditSheet,
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Editar informações'),
                              ),
                              const SizedBox(height: 22),
                              OutlinedButton.icon
                              (onPressed: _logout,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                              ),
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Sair da conta'),
                              )
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
                  : 'Conta não verificada',
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
  late final TextEditingController _addressController;
  late LatLng? _location;
  String? _resolvedAddress;

  bool _fetchingLocation = false;
  bool _manualMode = false;
  bool _geocoding = false;
  List<Location> _geocodingResults = const [];
  List<Placemark> _placemarks = const [];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _cpfCnpjController = TextEditingController(
      text: _formatCpfCnpjForInput(widget.profile.cpfCnpj),
    );
    _addressController = TextEditingController();
    _location = widget.profile.location;
    _resolvedAddress = widget.profile.locationLabel;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _cpfCnpjController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchAutoLocation() async {
    setState(() {
      _fetchingLocation = true;
      _geocodingResults = const [];
      _placemarks = const [];
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Serviço de localização desativado.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError('Permissão de localização negada.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Permissão de localização negada permanentemente.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final currentLocation = LatLng(position.latitude, position.longitude);
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final p = placemarks.isNotEmpty ? placemarks.first : null;
      final address = p != null
          ? _formatPlacemark(p)
          : '${position.latitude.toStringAsFixed(4)}, '
            '${position.longitude.toStringAsFixed(4)}';

      setState(() {
        _location = currentLocation;
        _resolvedAddress = address;
      });
    } catch (_) {
      _showError('Não foi possível obter localização.');
    } finally {
      if (mounted) {
        setState(() {
          _fetchingLocation = false;
        });
      }
    }
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      _showError('Digite um endereço para buscar.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _geocoding = true;
      _geocodingResults = const [];
      _placemarks = const [];
      _location = null;
      _resolvedAddress = null;
    });

    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) {
        if (!mounted) return;
        _showError('Nenhum resultado encontrado para esse endereço.');
        return;
      }

      final limited = locations.take(3).toList();
      final placemarks = await Future.wait(
        limited.map(
          (loc) => placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          ).then((list) => list.isNotEmpty ? list.first : Placemark()),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _geocoding = false;
        _geocodingResults = limited;
        _placemarks = placemarks;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _geocoding = false;
      });
      _showError('Erro ao buscar endereço. Tente novamente.');
    }
  }

  void _selectGeocodingResult(int index) {
    final selected = _geocodingResults[index];
    final placemark = _placemarks[index];
    setState(() {
      _location = LatLng(selected.latitude, selected.longitude);
      _resolvedAddress = _formatPlacemark(placemark);
      _geocodingResults = const [];
      _placemarks = const [];
    });
  }

  void _clearSelectedLocation() {
    setState(() {
      _location = null;
      _resolvedAddress = null;
      _addressController.clear();
      _geocodingResults = const [];
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatPlacemark(Placemark p) {
    final parts = [
      if (p.street != null && p.street!.isNotEmpty) p.street,
      if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
      if (p.locality != null && p.locality!.isNotEmpty) p.locality,
      if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
        p.administrativeArea,
    ];
    return parts.join(', ');
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_location == null) {
      _showError('Informe uma localização antes de salvar.');
      return;
    }

    Navigator.of(context).pop(
      _ProfileEditPayload(
        fullName: _fullNameController.text.trim(),
        cpfCnpj: _normalizeCpfCnpj(_cpfCnpjController.text),
        location: _location,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar perfil',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ajuste nome, CPF/CNPJ e localização.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(color: inputTextColor),
                  cursorColor: colorScheme.primary,
                  decoration: decoration(label: 'Nome completo'),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cpfCnpjController,
                  style: const TextStyle(color: inputTextColor),
                  cursorColor: colorScheme.primary,
                  decoration: decoration(
                    label: 'CPF/CNPJ',
                    hint: 'Opcional',
                  ),
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9./\- ]')),
                  ],
                  validator: (value) => _validateCpfCnpj(value),
                ),
                const SizedBox(height: 10),
                Text(
                  'Use CPF com 11 dígitos ou CNPJ com 14 dígitos.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Localização',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2D3B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      _ProfileLocationModeTab(
                        label: 'Automática',
                        icon: Icons.my_location,
                        selected: !_manualMode,
                        onTap: () {
                          setState(() {
                            _manualMode = false;
                            _geocodingResults = const [];
                          });
                        },
                      ),
                      _ProfileLocationModeTab(
                        label: 'Por endereço',
                        icon: Icons.search,
                        selected: _manualMode,
                        onTap: () {
                          setState(() {
                            _manualMode = true;
                            _geocodingResults = const [];
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (!_manualMode)
                  _ProfileLocationStatusCard(
                    location: _location,
                    address: _resolvedAddress,
                    loading: _fetchingLocation,
                    onTap: _fetchAutoLocation,
                    idleLabel: 'Usar minha localização atual',
                    idleIcon: Icons.location_off_outlined,
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: decoration(
                            label: 'Buscar endereço',
                            hint: 'Rua, bairro, cidade...',
                          ),
                          onFieldSubmitted: (_) => _searchAddress(),
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: ElevatedButton(
                          onPressed: _geocoding ? null : _searchAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            disabledBackgroundColor:
                                colorScheme.primary.withValues(alpha: 0.4),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _geocoding
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.search, size: 20),
                        ),
                      ),
                    ],
                  ),
                  if (_geocodingResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2D3B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        children: List.generate(_geocodingResults.length, (i) {
                              final label = _formatPlacemark(_placemarks[i]);
                          final isLast = i == _geocodingResults.length - 1;
                          return InkWell(
                            onTap: () => _selectGeocodingResult(i),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: isLast
                                    ? null
                                    : const Border(
                                        bottom: BorderSide(
                                          color: Colors.white12,
                                          width: 1,
                                        ),
                                      ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Colors.white60,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Colors.white60,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                  if (_location != null && _geocodingResults.isEmpty) ...[
                    const SizedBox(height: 10),
                    _ProfileLocationStatusCard(
                      location: _location,
                      address: _resolvedAddress,
                      loading: false,
                      onTap: _clearSelectedLocation,
                      idleLabel: '',
                      idleIcon: Icons.location_off_outlined,
                      isConfirmed: true,
                    ),
                  ],
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                        ),
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

class _ProfileLocationStatusCard extends StatelessWidget {
  const _ProfileLocationStatusCard({
    required this.location,
    required this.address,
    required this.loading,
    required this.onTap,
    required this.idleLabel,
    required this.idleIcon,
    this.isConfirmed = false,
  });

  final LatLng? location;
  final String? address;
  final bool loading;
  final VoidCallback onTap;
  final String idleLabel;
  final IconData idleIcon;
  final bool isConfirmed;

  @override
  Widget build(BuildContext context) {
    final hasLocation = location != null;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasLocation ? const Color(0x1222C55E) : const Color(0xFF2A2D3B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasLocation ? const Color(0xFF22C55E) : Colors.white24,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasLocation ? Icons.location_on : idleIcon,
              size: 18,
              color: hasLocation ? const Color(0xFF22C55E) : Colors.white60,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: loading
                  ? const Text(
                      'Obtendo localização...',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    )
                  : Text(
                      hasLocation
                          ? (address ?? 'Localização confirmada')
                          : idleLabel,
                      style: TextStyle(
                        color: hasLocation
                            ? const Color(0xFF22C55E)
                            : Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            const SizedBox(width: 8),
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white60,
                ),
              )
            else
              Icon(
                isConfirmed ? Icons.close : Icons.chevron_right,
                color: hasLocation ? const Color(0xFF22C55E) : Colors.white60,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLocationModeTab extends StatelessWidget {
  const _ProfileLocationModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary.withValues(alpha: 0.25) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileEditPayload {
  const _ProfileEditPayload({
    required this.fullName,
    required this.cpfCnpj,
    required this.location,
  });

  final String fullName;
  final String? cpfCnpj;
  final LatLng? location;
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
    return 'CPF deve ter 11 dígitos ou CNPJ 14 dígitos';
  }

  if (_allDigitsEqual(digits)) {
    return 'Documento inválido';
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
