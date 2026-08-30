import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/profile_entity.dart';

class ProfileEditPayload {
  const ProfileEditPayload({
    required this.fullName,
    required this.cpfCnpj,
    required this.location,
  });

  final String fullName;
  final String? cpfCnpj;
  final LatLng? location;
}

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      ProfileEditPayload(
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
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
                  decoration: decoration(label: 'CPF/CNPJ', hint: 'Opcional'),
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9./\- ]')),
                  ],
                  validator: (value) => _validateCpfCnpj(value),
                ),
                const SizedBox(height: 10),
                Text(
                  'Use CPF com 11 dígitos ou CNPJ com 14 dígitos.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white60),
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
                            disabledBackgroundColor: colorScheme.primary
                                .withValues(alpha: 0.4),
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
          color: hasLocation
              ? const Color(0x1222C55E)
              : const Color(0xFF2A2D3B),
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
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.25)
                : null,
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
  for (var i = 1; i < digits.length; i++) {
    if (digits[i] != digits[0]) {
      return false;
    }
  }
  return true;
}
