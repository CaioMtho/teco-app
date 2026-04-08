import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// ─── Paleta & Tema ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0A0A0A);
const _kAccent = Color.fromARGB(255, 246, 244, 244); // lime elétrico
const _kSurface = Color(0xFF141414);
const _kCard = Color(0xFF1E1E1E);
const _kMuted = Color(0xFF6B6B6B);
const _kBorder = Color(0xFF2A2A2A);
const _kError = Color(0xFFFF4D4D);

// ─── Entry point (substitua pelo seu main.dart / router) ─────────────────────
//
//   void main() async {
//     WidgetsFlutterBinding.ensureInitialized();
//     await Supabase.initialize(url: 'URL', anonKey: 'KEY');
//     runApp(MaterialApp(home: AuthScreen()));
//   }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

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
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo mark
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bolt,
                        color: _kPrimary, size: 24),
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
                  // ── Tab Selector ───────────────────────────────────────────
                  _TabSelector(controller: _tab),
                ],
              ),
            ),
            // ── Forms ────────────────────────────────────────────────────────
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
class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      // Navegar para home após login bem-sucedido
      // Navigator.of(context).pushReplacement(...)
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _kError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                onPressed: () {}, // esqueci senha
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
class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();

  String _userType = 'requester';
  bool _obscure = true;
  bool _loading = false;
  LatLng? _location;
  bool _fetchingLocation = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _cpfCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
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
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _location = LatLng(pos.latitude, pos.longitude);
      });
    } catch (_) {
      _showError('Não foi possível obter localização.');
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      _showError('Obtenha sua localização antes de continuar.');
      return;
    }
    setState(() => _loading = true);
    try {
      final data = <String, dynamic>{
        'full_name': _nameCtrl.text.trim(),
        'type': _userType,
        'location': {
          'lat': _location!.latitude,
          'lng': _location!.longitude,
        },
      };
      if (_userType == 'provider') {
        data['cpf_cnpj'] = _cpfCtrl.text.trim();
      }
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        data: data,
      );
      _showSuccess('Conta criada! Verifique seu e-mail.');
    } on AuthException catch (e) {
      _showError(e.message);
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
      backgroundColor: const Color(0xFF22C55E),
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
            const Text('Você é…',
                style: TextStyle(
                    color: _kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
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
            _Field(
              controller: _nameCtrl,
              label: 'Nome completo',
              hint: 'João da Silva',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
            ),
            const SizedBox(height: 14),
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
            // ── CPF/CNPJ apenas para provider ─────────────────────────────
            if (_userType == 'provider') ...[
              const SizedBox(height: 14),
              _Field(
                controller: _cpfCtrl,
                label: 'CPF / CNPJ',
                hint: '000.000.000-00',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CpfCnpjFormatter(),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe CPF ou CNPJ';
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length != 11 && digits.length != 14) {
                    return 'CPF (11 dígitos) ou CNPJ (14 dígitos)';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 14),
            // ── Localização ───────────────────────────────────────────────
            _LocationButton(
              location: _location,
              loading: _fetchingLocation,
              onTap: _fetchLocation,
            ),
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

// ─── Chips de tipo ────────────────────────────────────────────────────────────
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
              Icon(icon,
                  size: 18,
                  color: selected ? _kPrimary : _kMuted),
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

// ─── Botão de localização ─────────────────────────────────────────────────────
class _LocationButton extends StatelessWidget {
  final LatLng? location;
  final bool loading;
  final VoidCallback onTap;

  const _LocationButton({
    required this.location,
    required this.loading,
    required this.onTap,
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
          color: hasLocation
              ? const Color(0xFF0D2B0D)
              : _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasLocation
                ? const Color(0xFF22C55E)
                : _kBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasLocation ? Icons.location_on : Icons.location_off_outlined,
              size: 18,
              color: hasLocation
                  ? const Color(0xFF22C55E)
                  : _kMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: loading
                  ? const Text('Obtendo localização…',
                      style: TextStyle(color: _kMuted, fontSize: 14))
                  : Text(
                      hasLocation
                          ? 'Localização obtida (${location!.latitude.toStringAsFixed(4)}, ${location!.longitude.toStringAsFixed(4)})'
                          : 'Usar minha localização atual',
                      style: TextStyle(
                        color: hasLocation
                            ? const Color(0xFF22C55E)
                            : _kMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kMuted,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: hasLocation ? const Color(0xFF22C55E) : _kMuted,
                size: 18,
              ),
          ],
        ),
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
        Text(
          label,
          style: const TextStyle(
            color: _kMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
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
          disabledBackgroundColor: _kAccent.withOpacity(0.5),
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

// ─── Helpers ──────────────────────────────────────────────────────────────────
String? _validateEmail(String? v) {
  if (v == null || v.isEmpty) return 'Informe seu e-mail';
  final re = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.\w{2,}$');
  if (!re.hasMatch(v.trim())) return 'E-mail inválido';
  return null;
}

/// Formata automaticamente CPF (000.000.000-00) ou CNPJ (00.000.000/0000-00)
class _CpfCnpjFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted;

    if (digits.length <= 11) {
      // CPF: 000.000.000-00
      formatted = _applyCpfMask(digits);
    } else {
      // CNPJ: 00.000.000/0000-00
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
