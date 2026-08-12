import 'package:flutter/material.dart';

import '../../core/theme/appearance_controller.dart';
import '../../core/theme/appearance_menu.dart';
import '../../core/theme/viti_theme.dart';
import 'session_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.session, required this.appearance, super.key});

  final SessionController session;
  final AppearanceController appearance;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final access = TextEditingController();
  final password = TextEditingController();
  final secret = TextEditingController();
  bool obscure = true;
  bool superadminMode = false;

  @override
  void dispose() {
    access.dispose();
    password.dispose();
    secret.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (access.text.trim().isEmpty || password.text.isEmpty || widget.session.busy) return;
    await widget.session.login(access.text, password.text, superadminMode ? secret.text : '');
    if (!mounted) return;
    final message = widget.session.error;
    if (message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 920;
          if (desktop) {
            return Row(
              children: [
                Expanded(flex: 11, child: _BrandPanel()),
                Expanded(flex: 9, child: _LoginArea(desktop: true)),
              ],
            );
          }
          return _LoginArea(desktop: false);
        },
      ),
    );
  }

  Widget _LoginArea({required bool desktop}) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          top: 12,
          right: 12,
          child: AppearanceMenuButton(controller: widget.appearance),
        ),
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(desktop ? 44 : 20, 64, desktop ? 44 : 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!desktop) ...[
                    const _MobileBrand(),
                    const SizedBox(height: 28),
                  ],
                  Text('Bienvenido a VITI', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                    'Tu plataforma de operación, desarrollo y atención de AGR Studio en una experiencia nativa.',
                    style: TextStyle(color: colors.onSurfaceVariant, height: 1.45),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: EdgeInsets.all(desktop ? 24 : 18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.outlineVariant),
                      boxShadow: Theme.of(context).brightness == Brightness.light
                          ? [BoxShadow(color: VitiTheme.navy.withValues(alpha: .06), blurRadius: 30, offset: const Offset(0, 12))]
                          : const [],
                    ),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(width: 34, height: 34, decoration: BoxDecoration(color: colors.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.lock_open_outlined, size: 18, color: colors.primary)),
                              const SizedBox(width: 10),
                              const Expanded(child: Text('Acceso seguro', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFF2FA86F).withValues(alpha: .10), borderRadius: BorderRadius.circular(999)),
                                child: const Text('NATIVO', style: TextStyle(color: Color(0xFF20895A), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .5)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: access,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            decoration: const InputDecoration(
                              labelText: 'Usuario, teléfono o CI',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: password,
                            obscureText: obscure,
                            textInputAction: superadminMode ? TextInputAction.next : TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: superadminMode ? null : (_) => submit(),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                                onPressed: () => setState(() => obscure = !obscure),
                                icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              superadminMode = !superadminMode;
                              if (!superadminMode) secret.clear();
                            }),
                            icon: Icon(superadminMode ? Icons.keyboard_arrow_up : Icons.admin_panel_settings_outlined, size: 18),
                            label: Text(superadminMode ? 'Ocultar acceso Superadmin' : 'Acceso Superadmin'),
                            style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 180),
                            crossFadeState: superadminMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            firstChild: const SizedBox.shrink(),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: TextField(
                                controller: secret,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => submit(),
                                decoration: const InputDecoration(
                                  labelText: 'Código secreto',
                                  prefixIcon: Icon(Icons.shield_outlined),
                                  helperText: 'Solo se valida para la cuenta Superadmin.',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: widget.session.busy ? null : submit,
                            icon: widget.session.busy
                                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.login),
                            label: Text(widget.session.busy ? 'Ingresando...' : 'Entrar a VITI'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined, size: 15, color: colors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'La sesión se conserva de forma segura en este dispositivo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _BrandPanel() {
    return Container(
      color: VitiTheme.navy,
      padding: const EdgeInsets.all(52),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DesktopBrand(),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 570),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Un solo centro de trabajo.\nToda la operación conectada.', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.08, letterSpacing: -1.3)),
                  const SizedBox(height: 18),
                  Text('Empresas, solicitudes, proyectos, aplicaciones, pagos, atención y soporte en la misma plataforma.', style: TextStyle(color: Colors.white.withValues(alpha: .70), fontSize: 16, height: 1.55)),
                  const SizedBox(height: 30),
                  const Wrap(spacing: 10, runSpacing: 10, children: [
                    _FeatureChip(icon: Icons.dashboard_customize_outlined, label: 'Operación'),
                    _FeatureChip(icon: Icons.account_tree_outlined, label: 'Proyectos'),
                    _FeatureChip(icon: Icons.apps_outlined, label: 'Aplicaciones'),
                    _FeatureChip(icon: Icons.forum_outlined, label: 'Atención VITI'),
                  ]),
                ],
              ),
            ),
            const Spacer(),
            Text('VITI · Visión Integral, Tecnología e Innovación', style: TextStyle(color: Colors.white.withValues(alpha: .46), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .25)),
          ],
        ),
      ),
    );
  }
}

class _DesktopBrand extends StatelessWidget {
  const _DesktopBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('AGR', style: TextStyle(color: VitiTheme.navy, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .7)),
            Container(width: 25, height: 2, margin: const EdgeInsets.only(top: 3), color: VitiTheme.blue),
          ]),
        ),
        const SizedBox(width: 13),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AGR STUDIO', style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.25)),
          const Text('VITI', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.7, height: 1)),
        ]),
      ],
    );
  }
}

class _MobileBrand extends StatelessWidget {
  const _MobileBrand();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: VitiTheme.navy, borderRadius: BorderRadius.circular(12)), child: const Text('AGR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('VITI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.3)), Text('AGR Studio', style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant, fontWeight: FontWeight.w700))]),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: .09))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: const Color(0xFF9DD5FF)), const SizedBox(width: 7), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))]),
    );
  }
}
