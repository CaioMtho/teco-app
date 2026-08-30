import 'package:flutter/material.dart';

class PasswordChangePayload {
  const PasswordChangePayload({required this.password});

  final String password;
}

class PasswordChangeSheet extends StatefulWidget {
  const PasswordChangeSheet({super.key});

  @override
  State<PasswordChangeSheet> createState() => _PasswordChangeSheetState();
}

class _PasswordChangeSheetState extends State<PasswordChangeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(
      context,
    ).pop(PasswordChangePayload(password: _passwordCtrl.text));
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Informe uma senha';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return 'Inclua ao menos uma letra maiúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Inclua ao menos um número';
    return null;
  }

  InputDecoration _profileInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ThemeData.light().colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Trocar senha',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              style: const TextStyle(color: Colors.white),
              decoration: _profileInputDecoration('Nova senha').copyWith(
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: Colors.white),
              decoration: _profileInputDecoration('Confirmar senha').copyWith(
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Confirme senha';
                if (value != _passwordCtrl.text) return 'Senhas não coincidem';
                return null;
              },
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: _submit, child: const Text('Salvar senha')),
          ],
        ),
      ),
    );
  }
}
