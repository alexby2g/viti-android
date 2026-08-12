import 'package:flutter/material.dart';

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
  const HomeShell({
    required this.session,
    required this.repository,
    required this.appearance,
    super.key,
  });

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _showCompanySelector() async {
    if (clientCompanies.length < 2) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
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
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _selectCompany(_int(company['id']));
                  },
                ),
            ],
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
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !desktop,
            titleSpacing: desktop ? 24 : null,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(current.label, style: const TextStyle(fontWeight: FontWeight.w900)),
                if (desktop)
                  Text(
                    _moduleSubtitle(current.key),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            actions: [
              if (isClient && clientCompanies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                  child: TextButton.icon(
                    onPressed: clientCompanies.length > 1 ? _showCompanySelector : null,
                    icon: const Icon(Icons.business_outlined, size: 18),
                    label: Text(_activeCompanyName()),
                  ),
                ),
              if (desktop)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(child: Text(userName, style: const TextStyle(fontWeight: FontWeight.w700))),
                ),
              const SizedBox(width: 8),
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
      },
    );
  }

  String _activeCompanyName() {
    for (final company in clientCompanies) {
      if (_int(company['id']) == activeCompanyId) return _text(company['nombre_comercial'], 'Empresa');
    }
    return 'Empresa';
  }

  String _moduleSubtitle(String key) {
    return switch (key) {
      'inicio' => 'Resumen y accesos rápidos',
      'empresas' => 'Negocios y responsables',
      'solicitudes' => 'Solicitudes e historial',
      'proyectos' || 'proyecto' => 'Avances y seguimiento',
      'aplicaciones' => 'Sistemas conectados a VITI',
      'pagos' => 'Pagos y comprobantes',
      'mensajes' => 'Conversaciones y documentos',
      'trabajo' => 'Asignaciones de soporte interno',
      'guia' => 'Flujo y ayuda de VITI',
      _ => 'AGR Studio · VITI',
    };
  }

  Widget _content(VitiNavItem current) {
    final role = widget.session.user?.role ?? 'cliente';
    if (current.key == 'guia') {
      return GuideModuleScreen(key: ValueKey('guide-$role-$tenantEpoch'), repository: widget.repository, role: role);
    }

    if (role == 'soporte') {
      if (current.key == 'trabajo' || current.key == 'mensajes') {
        return SupportModuleScreen(repository: widget.repository, module: current.key);
      }
    }

    if (role == 'administrador' || role == 'superadmin') {
      if (const {'inicio', 'empresas', 'solicitudes', 'proyectos', 'aplicaciones'}.contains(current.key)) {
        return AdminModuleScreen(
          repository: widget.repository,
          module: current.key,
          superadmin: role == 'superadmin',
          onNavigate: _navigateTo,
        );
      }
      if (role == 'superadmin' && current.key == 'pagos') {
        return PaymentModuleScreen(repository: widget.repository, admin: true);
      }
      if (role == 'superadmin' && current.key == 'mensajes') {
        return MessageModuleScreen(repository: widget.repository, admin: true);
      }
    }

    if (const {'inicio', 'solicitudes', 'proyecto', 'aplicaciones'}.contains(current.key)) {
      return ClientModuleScreen(
        key: ValueKey('client-${current.key}-$tenantEpoch'),
        repository: widget.repository,
        module: current.key,
        onNavigate: _navigateTo,
      );
    }
    if (current.key == 'pagos') {
      return PaymentModuleScreen(key: ValueKey('payments-$tenantEpoch'), repository: widget.repository, admin: false);
    }
    if (current.key == 'mensajes') {
      return MessageModuleScreen(repository: widget.repository, admin: false);
    }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.construction, size: 34),
                const SizedBox(height: 12),
                Text(text),
                const SizedBox(height: 8),
                Text('Android y Windows comparten la misma base Flutter y la misma API VITI.', style: TextStyle(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
