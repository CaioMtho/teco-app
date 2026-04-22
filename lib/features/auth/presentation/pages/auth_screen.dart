import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/auth_sign_up_payload.dart';
import '../providers/auth_providers.dart';

// ─── Paleta & Tema ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0A0A0A);
const _kAccent = Color.fromARGB(255, 246, 244, 244);
const _kCard = Color(0xFF1E1E1E);
const _kMuted = Color(0xFF6B6B6B);
const _kBorder = Color(0xFF2A2A2A);
const _kError = Color(0xFFFF4D4D);
const _kGreen = Color(0xFF22C55E);
const _kGreenBg = Color(0xFF0D2B0D);

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.initialMessage,
  });

  final String? initialMessage;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));

    final initialMessage = widget.initialMessage?.trim();
    if (initialMessage != null && initialMessage.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(initialMessage),
            backgroundColor: _kError,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bolt, color: _kPrimary, size: 24),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _tab.index == 0 ? 'Bem-vindo\nde volta.' : 'Crie sua\nconta.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tab.index == 0
                        ? 'Entre para continuar.'
                        : 'Comece a usar a plataforma.',
                    style: const TextStyle(
                      color: _kMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _TabSelector(controller: _tab),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _LoginForm(),
                  _RegisterForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Selector ─────────────────────────────────────────────────────────────
class _TabSelector extends StatelessWidget {
  final TabController controller;
  const _TabSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: _kAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: _kPrimary,
        unselectedLabelColor: _kMuted,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
        tabs: const [
          Tab(text: 'Entrar'),
          Tab(text: 'Cadastrar'),
        ],
      ),
    );
  }
}

// ─── Login Form ───────────────────────────────────────────────────────────────
class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).signIn(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } on AuthException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _kError,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _Field(
              controller: _emailCtrl,
              label: 'E-mail',
              hint: 'voce@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            _Field(
              controller: _passCtrl,
              label: 'Senha',
              hint: '••••••••',
              obscure: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: _kMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: _kMuted,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Esqueci minha senha',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(height: 28),
            _PrimaryButton(
              label: 'Entrar',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Register Form ────────────────────────────────────────────────────────────
class _RegisterForm extends ConsumerStatefulWidget {
  const _RegisterForm();

  @override
  ConsumerState<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();

  String _userType = 'requester';
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  // ── Localização ───────────────────────────────────────────────────────────
  LatLng? _location;
  String? _resolvedAddress; // endereço legível confirmado
  bool _fetchingLocation = false;
  bool _manualMode = false;

  // ── Geocoding manual ──────────────────────────────────────────────────────
  final _addressCtrl = TextEditingController();
  bool _geocoding = false;
  List<Location> _geocodingResults = [];
  List<Placemark> _placemarks = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _cpfCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Localização automática ────────────────────────────────────────────────
  Future<void> _fetchAutoLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Serviço de localização desativado.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permissão de localização negada.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError('Permissão de localização negada permanentemente.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      final p = placemarks.isNotEmpty ? placemarks.first : null;
      final address = p != null
          ? _formatPlacemark(p)
          : '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';

      setState(() {
        _location = LatLng(pos.latitude, pos.longitude);
        _resolvedAddress = address;
      });
    } catch (_) {
      _showError('Não foi possível obter localização.');
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  // ── Geocoding por endereço ────────────────────────────────────────────────
  Future<void> _searchAddress() async {
    final query = _addressCtrl.text.trim();
    if (query.isEmpty) {
      _showError('Digite um endereço para buscar.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _geocoding = true;
      _geocodingResults = [];
      _placemarks = [];
      _location = null;
      _resolvedAddress = null;
    });
    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) {
        _showError('Nenhum resultado encontrado para esse endereço.');
        return;
      }
      // Busca placemark para cada resultado (máx. 3)
      final limited = locations.take(3).toList();
      final placemarks = await Future.wait(
        limited.map((loc) => placemarkFromCoordinates(
              loc.latitude,
              loc.longitude,
            ).then((list) => list.isNotEmpty ? list.first : Placemark())),
      );
      setState(() {
        _geocodingResults = limited;
        _placemarks = placemarks;
      });
    } on NoResultFoundException {
      _showError('Nenhum resultado encontrado para esse endereço.');
    } catch (_) {
      _showError('Erro ao buscar endereço. Tente novamente.');
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  void _selectGeocodingResult(int index) {
    final loc = _geocodingResults[index];
    final pm = _placemarks[index];
    setState(() {
      _location = LatLng(loc.latitude, loc.longitude);
      _resolvedAddress = _formatPlacemark(pm);
      _geocodingResults = [];
      _placemarks = [];
    });
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      _showError('Informe sua localização antes de continuar.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).signUp(
        AuthSignUpPayload(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          userType: _userType,
          cpfCnpj: _cpfCtrl.text.trim(),
          location: _location!,
        ),
      );
      _showSuccess('Conta criada! Verifique seu e-mail.');
    } on AuthException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _kError,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tipo de usuário ────────────────────────────────────────────
            const _FieldLabel(text: 'Você é…'),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeChip(
                  label: 'Contratante',
                  icon: Icons.person_outline,
                  selected: _userType == 'requester',
                  onTap: () => setState(() => _userType = 'requester'),
                ),
                const SizedBox(width: 10),
                _TypeChip(
                  label: 'Prestador',
                  icon: Icons.handyman_outlined,
                  selected: _userType == 'provider',
                  onTap: () => setState(() => _userType = 'provider'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Nome completo ──────────────────────────────────────────────
            _Field(
              controller: _nameCtrl,
              label: 'Nome completo',
              hint: 'João da Silva',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe seu nome';
                if (v.trim().split(' ').length < 2) {
                  return 'Informe nome e sobrenome';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── E-mail ─────────────────────────────────────────────────────
            _Field(
              controller: _emailCtrl,
              label: 'E-mail',
              hint: 'voce@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),

            // ── Senha ──────────────────────────────────────────────────────
            _Field(
              controller: _passCtrl,
              label: 'Senha',
              hint: '••••••••',
              obscure: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: _kMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 14),

            // ── Confirmar senha ────────────────────────────────────────────
            _Field(
              controller: _confirmPassCtrl,
              label: 'Confirmar senha',
              hint: '••••••••',
              obscure: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: _kMuted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirme sua senha';
                if (v != _passCtrl.text) return 'As senhas não coincidem';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── CPF / CNPJ (obrigatório para todos) ───────────────────────
            _Field(
              controller: _cpfCtrl,
              label: _userType == 'provider' ? 'CPF / CNPJ' : 'CPF',
              hint: _userType == 'provider'
                  ? '000.000.000-00 ou 00.000.000/0000-00'
                  : '000.000.000-00',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CpfCnpjFormatter(),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return _userType == 'provider'
                      ? 'Informe CPF ou CNPJ'
                      : 'Informe seu CPF';
                }
                final digits = v.replaceAll(RegExp(r'\D'), '');
                if (_userType == 'requester' && digits.length != 11) {
                  return 'CPF deve ter 11 dígitos';
                }
                if (_userType == 'provider' &&
                    digits.length != 11 &&
                    digits.length != 14) {
                  return 'CPF (11 dígitos) ou CNPJ (14 dígitos)';
                }
                if (digits.length == 11 && !_isValidCpf(digits)) {
                  return 'CPF inválido';
                }
                if (digits.length == 14 && !_isValidCnpj(digits)) {
                  return 'CNPJ inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Localização ────────────────────────────────────────────────
            const _FieldLabel(text: 'Localização'),
            const SizedBox(height: 8),

            // Toggle automático / manual
            Container(
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                children: [
                  _LocationModeTab(
                    label: 'Automática',
                    icon: Icons.my_location,
                    selected: !_manualMode,
                    onTap: () => setState(() {
                      _manualMode = false;
                      _location = null;
                      _resolvedAddress = null;
                      _geocodingResults = [];
                      _placemarks = [];
                    }),
                  ),
                  _LocationModeTab(
                    label: 'Por endereço',
                    icon: Icons.search,
                    selected: _manualMode,
                    onTap: () => setState(() {
                      _manualMode = true;
                      _location = null;
                      _resolvedAddress = null;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (!_manualMode) ...[
              // ── Localização automática ───────────────────────────────────
              _LocationStatusCard(
                location: _location,
                address: _resolvedAddress,
                loading: _fetchingLocation,
                onTap: _fetchAutoLocation,
                idleLabel: 'Usar minha localização atual',
                idleIcon: Icons.location_off_outlined,
              ),
            ] else ...[
              // ── Busca por endereço ────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressCtrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Rua, bairro, cidade…',
                        hintStyle:
                            const TextStyle(color: _kMuted, fontSize: 14),
                        filled: true,
                        fillColor: _kCard,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _kAccent, width: 1.5),
                        ),
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
                        backgroundColor: _kAccent,
                        foregroundColor: _kPrimary,
                        disabledBackgroundColor:
                            _kAccent.withValues(alpha: 0.4),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _geocoding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _kPrimary),
                            )
                          : const Icon(Icons.search, size: 20),
                    ),
                  ),
                ],
              ),

              // ── Resultados do geocoding ───────────────────────────────────
              if (_geocodingResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Column(
                    children: List.generate(_geocodingResults.length, (i) {
                      final pm = _placemarks[i];
                      final label = _formatPlacemark(pm);
                      final isLast = i == _geocodingResults.length - 1;
                      return InkWell(
                        onTap: () => _selectGeocodingResult(i),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : const Border(
                                    bottom:
                                        BorderSide(color: _kBorder, width: 1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: _kMuted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  label.isNotEmpty ? label : 'Endereço encontrado',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  size: 16, color: _kMuted),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],

              // ── Endereço confirmado ───────────────────────────────────────
              if (_location != null && _geocodingResults.isEmpty) ...[
                const SizedBox(height: 10),
                _LocationStatusCard(
                  location: _location,
                  address: _resolvedAddress,
                  loading: false,
                  onTap: () => setState(() {
                    _location = null;
                    _resolvedAddress = null;
                    _addressCtrl.clear();
                  }),
                  idleLabel: '',
                  idleIcon: Icons.location_off_outlined,
                  isConfirmed: true,
                ),
              ],
            ],

            const SizedBox(height: 28),
            _PrimaryButton(
              label: 'Criar conta',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card de status de localização ───────────────────────────────────────────
class _LocationStatusCard extends StatelessWidget {
  final LatLng? location;
  final String? address;
  final bool loading;
  final VoidCallback onTap;
  final String idleLabel;
  final IconData idleIcon;
  final bool isConfirmed;

  const _LocationStatusCard({
    required this.location,
    required this.address,
    required this.loading,
    required this.onTap,
    required this.idleLabel,
    required this.idleIcon,
    this.isConfirmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = location != null;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasLocation ? _kGreenBg : _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasLocation ? _kGreen : _kBorder),
        ),
        child: Row(
          children: [
            Icon(
              hasLocation ? Icons.location_on : idleIcon,
              size: 18,
              color: hasLocation ? _kGreen : _kMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: loading
                  ? const Text('Obtendo localização…',
                      style: TextStyle(color: _kMuted, fontSize: 14))
                  : Text(
                      hasLocation
                          ? (address ?? 'Localização confirmada')
                          : idleLabel,
                      style: TextStyle(
                        color: hasLocation ? _kGreen : _kMuted,
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
                    strokeWidth: 2, color: _kMuted),
              )
            else
              Icon(
                isConfirmed ? Icons.close : Icons.chevron_right,
                color: hasLocation ? _kGreen : _kMuted,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab de modo de localização ───────────────────────────────────────────────
class _LocationModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _LocationModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _kAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? _kPrimary : _kMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? _kPrimary : _kMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chips de tipo de usuário ─────────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _kAccent : _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _kAccent : _kBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? _kPrimary : _kMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? _kPrimary : _kMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Label de campo ───────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _kMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ─── Campo de texto reutilizável ──────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _kMuted, fontSize: 15),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _kCard,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kError),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kError, width: 1.5),
            ),
            errorStyle: const TextStyle(color: _kError, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ─── Botão primário ───────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kAccent,
          foregroundColor: _kPrimary,
          disabledBackgroundColor: _kAccent.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _kPrimary,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

// ─── Helpers & Validadores ────────────────────────────────────────────────────
String? _validateEmail(String? v) {
  if (v == null || v.isEmpty) return 'Informe seu e-mail';
  final re = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.\w{2,}$');
  if (!re.hasMatch(v.trim())) return 'E-mail inválido';
  return null;
}

String? _validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Informe uma senha';
  if (v.length < 8) return 'Mínimo 8 caracteres';
  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Inclua ao menos uma letra maiúscula';
  if (!RegExp(r'[0-9]').hasMatch(v)) return 'Inclua ao menos um número';
  return null;
}

bool _isValidCpf(String digits) {
  if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;
  int sum = 0;
  for (int i = 0; i < 9; i++) {
    sum += int.parse(digits[i]) * (10 - i);
  }
  int remainder = (sum * 10) % 11;
  if (remainder == 10 || remainder == 11) remainder = 0;
  if (remainder != int.parse(digits[9])) return false;
  sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += int.parse(digits[i]) * (11 - i);
  }
  remainder = (sum * 10) % 11;
  if (remainder == 10 || remainder == 11) remainder = 0;
  return remainder == int.parse(digits[10]);
}

bool _isValidCnpj(String digits) {
  if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) return false;
  const weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  int sum = 0;
  for (int i = 0; i < 12; i++) {
    sum += int.parse(digits[i]) * weights1[i];
  }
  int remainder = sum % 11;
  int d1 = remainder < 2 ? 0 : 11 - remainder;
  if (d1 != int.parse(digits[12])) return false;
  sum = 0;
  for (int i = 0; i < 13; i++) {
    sum += int.parse(digits[i]) * weights2[i];
  }
  remainder = sum % 11;
  int d2 = remainder < 2 ? 0 : 11 - remainder;
  return d2 == int.parse(digits[13]);
}

class _CpfCnpjFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted;
    if (digits.length <= 11) {
      formatted = _applyCpfMask(digits);
    } else {
      formatted = _applyCnpjMask(digits.substring(0, 14));
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _applyCpfMask(String digits) {
    final sb = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) sb.write('.');
      if (i == 9) sb.write('-');
      sb.write(digits[i]);
    }
    return sb.toString();
  }

  String _applyCnpjMask(String digits) {
    final sb = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) sb.write('.');
      if (i == 8) sb.write('/');
      if (i == 12) sb.write('-');
      sb.write(digits[i]);
    }
    return sb.toString();
  }
}