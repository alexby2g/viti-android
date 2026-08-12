import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/appearance_controller.dart';
import '../admin/admin_module_screen.dart';
import '../auth/session_controller.dart';
import '../client/client_module_screen.dart';
import '../data/viti_repository.dart';
import '../guide/guide_module_screen.dart';
import '../messages/message_module_screen.dart';
import '../payments/payment_module_screen.dart';
import '../support/support_module_screen.dart';
import 'viti_sidebar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.session, required this.repository, required this.appearance, super.key});

  final SessionController session;
  final VitiRepository repository;
  final AppearanceController appearance;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selected = 0;
  int tenantEpoch = 0;
  int? activeCompanyId;
  bool sidebarCollapsed = false;
  List<Map<String, dynamic>> clientCompanies = const [];

  bool get isClient => (widget.session.user?.role ?? 'cliente') == 'cliente';

  @override
  void initState() {
    super.initState();
    if (isClient) _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await widget.repository.clientCompanies();
      final active = await widget.repository.activeCompanyId();
      if (!mounted) return;
      setState(() {
        clientCompanies = companies;
        activeCompanyId = active;
      });
    } catch (_) {}
  }

  Future<void> _selectCompany(int companyId) async {
    if (companyId <= 0 || companyId == activeCompanyId) return;
    try {
      await widget.repository.selectCompany(companyId);
      if (!mounted) return;
      setState(() {
        activeCompanyId = companyId;
        tenantEpoch++;
        selected = 0;
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _showCompanySelector() async {
    if (clientCompanies.length < 2) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 22),
              children: [
                const ListTile(
                  title: Text('Cambiar empresa activa', style: TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text('Proyecto, aplicaciones y pagos se cargarán para el negocio seleccionado.'),
                ),
                for (final company in clientCompanies)
                  ListTile(
                    selected: _int(company['id']) == activeCompanyId,
                    leading: Icon(_int(company['id']) == activeCompanyId ? Icons.check_circle : Icons.business_outlined),
                    title: Text(_text(company['nombre_comercial'], 'Empresa VITI')),
                    subtitle: Text(_text(company['actividad'], 'Actividad por definir')),
                    trailing: _int(company['id']) == activeCompanyId ? const Text('ACTIVA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)) : null,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _selectCompany(_int(company['id']));
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<VitiNavItem> get destinations {
    final role = widget.session.user?.role ?? 'cliente';
    if (role == 'soporte') {
      return const [
        VitiNavItem('trabajo', 'Mi trabajo', Icons.support_agent_outlined, group: 'Soporte'),
        VitiNavItem('mensajes', 'Mensajes', Icons.forum_outlined, group: 'Comunicación'),
        VitiNavItem('guia', 'Guía', Icons.route_outlined, group: 'Ayuda'),
      ];
    }
    if (role == 'superadmin') {
      return const [
        VitiNavItem('inicio', 'Inicio', Icons.dashboard_outlined, group: 'General'),
        VitiNavItem('empresas', 'Empresas', Icons.business_outlined, group: 'Gestión'),
        VitiNavItem('solicitudes', 'Solicitudes', Icons.assignment_outlined, group: 'Gestión'),
        VitiNavItem('proyectos', 'Proyectos', Icons.account_tree_outlined, group: 'Gestión'),
        VitiNavItem('aplicaciones', 'Aplicaciones', Icons.apps_outlined, group: 'Gestión'),
        VitiNavItem('pagos', 'Pagos', Icons.payments_outlined, group: 'Control'),
        VitiNavItem('mensajes', 'Mensajes', Icons.forum_outlined, group: 'Control'),
        VitiNavItem('guia', 'Guía', Icons.route_outlined, group: 'Ayuda'),
      ];
    }
    if (role == 'administrador') {
      return const [
        VitiNavItem('inicio', 'Inicio', Icons.dashboard_outlined, group: 'General'),
        VitiNavItem('empresas', 'Empresas', Icons.business_outlined, group: 'Gestión'),
        VitiNavItem('solicitudes', 'Solicitudes', Icons.assignment_outlined, group: 'Gestión'),
        VitiNavItem('proyectos', 'Proyectos', Icons.account_tree_outlined, group: 'Gestión'),
        VitiNavItem('aplicaciones', 'Aplicaciones', Icons.apps_outlined, group: 'Gestión'),
        VitiNavItem('guia', 'Guía', Icons.route_outlined, group: 'Ayuda'),
      ];
    }
    return const [
      VitiNavItem('inicio', 'Inicio', Icons.home_outlined, group: 'Mi espacio'),
      VitiNavItem('solicitudes', 'Solicitudes', Icons.assignment_outlined, group: 'Mi trabajo'),
      VitiNavItem('proyecto', 'Proyecto', Icons.account_tree_outlined, group: 'Mi trabajo'),
      VitiNavItem('aplicaciones', 'Aplicaciones', Icons.apps_outlined, group: 'Mi trabajo'),
      VitiNavItem('pagos', 'Pagos', Icons.payments_outlined, group: 'Control'),
      VitiNavItem('mensajes', 'Mensajes', Icons.forum_outlined, group: 'Control'),
      VitiNavItem('guia', 'Guía', Icons.route_outlined, group: 'Ayuda'),
    ];
  }

  void _navigateTo(String key) {
    final index = destinations.indexWhere((item) => item.key == key);
    if (index < 0 || index == selected) return;
    setState(() => selected = index);
  }

  Future<void> _showQuickSearch() async {
    final controller = TextEditingController();
    var query = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final term = query.trim().toLowerCase();
          final filtered = destinations.where((item) => term.isEmpty || '${item.group} ${item.label}'.toLowerCase().contains(term)).toList(growable: false);
          return Dialog(
            alignment: Alignment.topCenter,
            insetPadding: const EdgeInsets.fromLTRB(18, 72, 18, 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620, maxHeight: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 15, 12, 12),
                    child: Row(children: [
                      const Icon(Icons.search, size: 21),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          onChanged: (value) => setDialogState(() => query = value),
                          decoration: const InputDecoration(hintText: 'Buscar módulo o sección...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
                        ),
                      ),
                      IconButton(tooltip: 'Cerrar', onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close)),
                    ]),
                  ),
                  const Divider(),
                  Flexible(
                    child: filtered.isEmpty
                        ? const Padding(padding: EdgeInsets.all(34), child: Center(child: Text('No encontramos esa sección en VITI.')))
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(10),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 3),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final destinationIndex = destinations.indexWhere((candidate) => candidate.key == item.key);
                              return ListTile(
                                selected: destinationIndex == selected,
                                leading: Icon(item.icon),
                                title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                                subtitle: Text(item.group),
                                trailing: const Icon(Icons.arrow_forward, size: 17),
                                onTap: () {
                                  Navigator.of(dialogContext).pop();
                                  if (destinationIndex >= 0) setState(() => selected = destinationIndex);
                                },
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 9, 16, 13),
                    child: Row(children: [
                      Text('Navegación rápida VITI', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const Spacer(),
                      Text('Ctrl K', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = destinations;
    if (selected >= items.length) selected = 0;
    final current = items[selected];
    final userName = widget.session.user?.name ?? 'Usuario VITI';
    final role = widget.session.user?.role ?? 'cliente';

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final scaffold = Scaffold(
          appBar: AppBar(
            toolbarHeight: desktop ? 66 : 60,
            automaticallyImplyLeading: !desktop,
            titleSpacing: desktop ? 22 : 4,
            title: desktop ? _desktopCommandTitle(current) : _mobileTitle(current),
            actions: [
              if (desktop)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: SizedBox(
                    width: 196,
                    child: OutlinedButton.icon(
                      onPressed: _showQuickSearch,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Row(children: [Expanded(child: Text('Buscar en VITI', overflow: TextOverflow.ellipsis)), Text('Ctrl K', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900))]),
                    ),
                  ),
                )
              else
                IconButton(tooltip: 'Buscar en VITI', onPressed: _showQuickSearch, icon: const Icon(Icons.search)),
              if (isClient && clientCompanies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: OutlinedButton.icon(
                    onPressed: clientCompanies.length > 1 ? _showCompanySelector : null,
                    icon: const Icon(Icons.business_outlined, size: 17),
                    label: ConstrainedBox(constraints: BoxConstraints(maxWidth: desktop ? 170 : 100), child: Text(_activeCompanyName(), overflow: TextOverflow.ellipsis)),
                  ),
                ),
              if (desktop)
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 9, 14, 9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Row(children: [
                      CircleAvatar(radius: 15, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Text(_initials(userName), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900))),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 128),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          Text(_pretty(role), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ]),
                      ),
                    ]),
                  ),
                ),
            ],
          ),
          drawer: desktop
              ? null
              : Drawer(
                  child: VitiMobileDrawer(
                    items: items,
                    selectedIndex: selected,
                    onSelected: (index) {
                      setState(() => selected = index);
                      Navigator.of(context).pop();
                    },
                    appearance: widget.appearance,
                    userName: userName,
                    role: role,
                    companyName: isClient && clientCompanies.isNotEmpty ? _activeCompanyName() : null,
                    onCompanyTap: clientCompanies.length > 1 ? _showCompanySelector : null,
                    onLogout: widget.session.logout,
                  ),
                ),
          body: desktop
              ? Row(
                  children: [
                    VitiSidebar(
                      items: items,
                      selectedIndex: selected,
                      onSelected: (index) => setState(() => selected = index),
                      appearance: widget.appearance,
                      userName: userName,
                      role: role,
                      companyName: isClient && clientCompanies.isNotEmpty ? _activeCompanyName() : null,
                      onCompanyTap: clientCompanies.length > 1 ? _showCompanySelector : null,
                      collapsed: sidebarCollapsed,
                      onToggleCollapsed: () => setState(() => sidebarCollapsed = !sidebarCollapsed),
                      onLogout: widget.session.logout,
                    ),
                    Expanded(child: _content(current)),
                  ],
                )
              : _content(current),
        );

        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyK, control: true): _showQuickSearch,
            const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _showQuickSearch,
          },
          child: Focus(autofocus: true, child: scaffold),
        );
      },
    );
  }

  Widget _desktopCommandTitle(VitiNavItem current) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: colors.primary.withValues(alpha: .10), border: Border.all(color: colors.primary.withValues(alpha: .20))),
          child: Icon(current.icon, size: 17, color: colors.primary),
        ),
        const SizedBox(width: 11),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [const Text('VITI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.15)), const SizedBox(width: 8), Text('/', style: TextStyle(color: colors.onSurfaceVariant)), const SizedBox(width: 8), Text(current.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 2),
          Text(_moduleSubtitle(current.key), style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant)),
        ]),
      ],
    );
  }

  Widget _mobileTitle(VitiNavItem current) {
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(current.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      Text(_moduleSubtitle(current.key), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant)),
    ]);
  }

  String _activeCompanyName() {
    for (final company in clientCompanies) {
      if (_int(company['id']) == activeCompanyId) return _text(company['nombre_comercial'], 'Empresa');
    }
    return 'Empresa';
  }

  String _moduleSubtitle(String key) => switch (key) {
        'inicio' => 'Resumen, actividad y accesos rápidos',
        'empresas' => 'Negocios, responsables y contexto',
        'solicitudes' => 'Entrada de trabajo e historial',
        'proyectos' || 'proyecto' => 'Avances, hitos y seguimiento',
        'aplicaciones' => 'Sistemas conectados a VITI',
        'pagos' => 'Pagos, comprobantes y control',
        'mensajes' => 'Atención VITI y documentos',
        'trabajo' => 'Asignaciones de soporte interno',
        'guia' => 'Flujo, onboarding y ayuda',
        _ => 'AGR Studio · VITI',
      };

  Widget _content(VitiNavItem current) {
    final role = widget.session.user?.role ?? 'cliente';
    if (current.key == 'guia') return GuideModuleScreen(key: ValueKey('guide-$role-$tenantEpoch'), repository: widget.repository, role: role);
    if (role == 'soporte' && (current.key == 'trabajo' || current.key == 'mensajes')) return SupportModuleScreen(repository: widget.repository, module: current.key);
    if (role == 'administrador' || role == 'superadmin') {
      if (const {'inicio', 'empresas', 'solicitudes', 'proyectos', 'aplicaciones'}.contains(current.key)) return AdminModuleScreen(repository: widget.repository, module: current.key, superadmin: role == 'superadmin', onNavigate: _navigateTo);
      if (role == 'superadmin' && current.key == 'pagos') return PaymentModuleScreen(repository: widget.repository, admin: true);
      if (role == 'superadmin' && current.key == 'mensajes') return MessageModuleScreen(repository: widget.repository, admin: true);
    }
    if (const {'inicio', 'solicitudes', 'proyecto', 'aplicaciones'}.contains(current.key)) return ClientModuleScreen(key: ValueKey('client-${current.key}-$tenantEpoch'), repository: widget.repository, module: current.key, onNavigate: _navigateTo);
    if (current.key == 'pagos') return PaymentModuleScreen(key: ValueKey('payments-$tenantEpoch'), repository: widget.repository, admin: false);
    if (current.key == 'mensajes') return MessageModuleScreen(repository: widget.repository, admin: false);
    return const _NativePlaceholder(title: 'VITI', text: 'Este módulo todavía está en integración nativa.');
  }
}

class _NativePlaceholder extends StatelessWidget {
  const _NativePlaceholder({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.construction, size: 34),
              const SizedBox(height: 12),
              Text(text),
              const SizedBox(height: 8),
              Text('Android y Windows comparten la misma base Flutter y la misma API VITI.', style: TextStyle(color: colors.onSurfaceVariant)),
            ]),
          ),
        ),
      ],
    );
  }
}

int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
String _pretty(String value) {
  final text = value.replaceAll('_', ' ');
  if (text.isEmpty) return 'Usuario';
  return text[0].toUpperCase() + text.substring(1);
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).toList();
  if (parts.isEmpty) return 'V';
  return parts.map((part) => part.characters.first.toUpperCase()).join();
}
