import 'package:flutter/material.dart';

import 'session_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.session, super.key});

  final SessionController session;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final access = TextEditingController();
  final password = TextEditingController();
  final secret = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    access.dispose();
    password.dispose();
    secret.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (access.text.trim().isEmpty || password.text.isEmpty || widget.session.busy) return;
    await widget.session.login(access.text, password.text, secret.text);
    if (!mounted) return;
    final message = widget.session.error;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('AGR Studio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('VITI', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('Accede a la misma plataforma desde teléfono o computadora.', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 28),
                    TextField(
                      controller: access,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Usuario, teléfono o CI', prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: password,
                      obscureText: obscure,
                      onSubmitted: (_) => submit(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: secret,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Código secreto (solo Superadmin)',
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: widget.session.busy ? null : submit,
                      icon: widget.session.busy
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.login),
                      label: const Text('Entrar a VITI'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'La sesión se guarda de forma segura en este dispositivo. El código secreto solo se usa para la cuenta Superadmin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
