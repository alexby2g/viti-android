import 'package:flutter/material.dart';

import '../admin/admin_module_screen.dart';
import '../auth/session_controller.dart';
import '../client/client_module_screen.dart';
import '../data/viti_repository.dart';
import '../guide/guide_module_screen.dart';
import '../messages/message_module_screen.dart';
import '../payments/payment_module_screen.dart';
import '../support/support_module_screen.dart';

class _Destination {
  const _Destination(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;
}

class HomeShell extends StatefulWidget {
  const HomeShell({required this.session, required this.repository, super.key});

  final SessionController session;
  final VitiRepository repository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selected = 0;
  int tenantEpoch = 0;
  int? activeCompanyId;
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

  List<_Destination> get destinations {
    final role = widget.session.user?.role ?? 'cliente';
    if (role == 'soporte') {
      return const [
        _Destination('trabajo', 'Mi trabajo', Icons.support_agent),
        _Destination('mensajes', 'Mensajes', Icons.forum_outlined),
        _Destination('guia', 'Guía', Icons.route_outlined),
      ];
    }
    if (role == 'superadmin') {
      return const [
        _Destination('inicio', 'Inicio', Icons.dashboard_outlined),
        _Destination('empresas', 'Empresas', Icons.business_outlined),
        _Destination('solicitudes', 'Solicitudes', Icons.assignment_outlined),
        _Destination('proyectos', 'Proyectos', Icons.account_tree_outlined),
        _Destination('aplicaciones', 'Aplicaciones', Icons.apps_outlined),
        _Destination('pagos', 'Pagos', Icons.payments_outlined),
        _Destination('mensajes', 'Mensajes', Icons.forum_outlined),
        _Destination('guia', 'Guía', Icons.route_outlined),
      ];
    }
    if (role == 'administrador') {
      return const [
        _Destination('inicio', 'Inicio', Icons.dashboard_outlined),
        _Destination('empresas', 'Empresas', Icons.business_outlined),
        _Destination('solicitudes', 'Solicitudes', Icons.assignment_outlined),
        _Destination('proyectos', 'Proyectos', Icons.account_tree_outlined),
        _Destination('aplicaciones', 'Aplicaciones', Icons.apps_outlined),
        _Destination('guia', 'Guía', Icons.route_outlined),
      ];
    }
    return const [
      _Destination('inicio', 'Inicio', Icons.home_outlined),
      _Destination('solicitudes', 'Solicitudes', Icons.assignment_outlined),
      _Destination('proyecto', 'Proyecto', Icons.account_tree_outlined),
      _Destination('aplicaciones', 'Aplicaciones', Icons.apps_outlined),
      _Destination('pagos', 'Pagos', Icons.payments_outlined),
      _Destination('mensajes', 'Mensajes', Icons.forum_outlined),
      _Destination('guia', 'Guía', Icons.route_outlined),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = destinations;
    if (selected >= items.length) selected = 0;
    final current = items[selected];

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: Text(desktop ? 'VITI · AGR Studio' : current.label),
            actions: [
              if (isClient && clientCompanies.isNotEmpty)
                PopupMenuButton<int>(
                  tooltip: 'Cambiar empresa',
                  initialValue: activeCompanyId,
                  onSelected: _selectCompany,
                  itemBuilder: (context) => [
                    for (final company in clientCompanies)
                      PopupMenuItem<int>(
                        value: _int(company['id']),
                        child: Row(children: [
                          if (_int(company['id']) == activeCompanyId) const Icon(Icons.check, size: 18),
                          if (_int(company['id']) == activeCompanyId) const SizedBox(width: 8),
                          Flexible(child: Text(_text(company['nombre_comercial'], 'Empresa VITI'))),
                        ]),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(children: [const Icon(Icons.business_outlined, size: 19), if (desktop) ...[const SizedBox(width: 6), Text(_activeCompanyName())], const Icon(Icons.arrow_drop_down)]),
                  ),
                ),
              if (desktop)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(child: Text(widget.session.user?.name ?? 'VITI')),
                ),
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: widget.session.busy ? null : widget.session.logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          drawer: desktop ? null : Drawer(child: _mobileMenu(items)),
          body: desktop
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selected,
                      extended: constraints.maxWidth >= 1180,
                      labelType: constraints.maxWidth >= 1180 ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
                      onDestinationSelected: (value) => setState(() => selected = value),
                      leading: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: CircleAvatar(radius: 24, child: Text('V', style: TextStyle(fontWeight: FontWeight.w900))),
                      ),
                      destinations: [
                        for (final item in items)
                          NavigationRailDestination(icon: Icon(item.icon), selectedIcon: Icon(item.icon), label: Text(item.label)),
                      ],
                    ),
                    const VerticalDivider(width: 1),
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

  Widget _mobileMenu(List<_Destination> items) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Text('V', style: TextStyle(fontWeight: FontWeight.w900))),
            title: const Text('AGR Studio', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('VITI · ${widget.session.user?.role ?? 'usuario'}'),
          ),
          if (isClient && clientCompanies.isNotEmpty)
            ListTile(leading: const Icon(Icons.business_outlined), title: Text(_activeCompanyName()), subtitle: const Text('Empresa activa')),
          const Divider(),
          for (var index = 0; index < items.length; index++)
            ListTile(
              selected: selected == index,
              leading: Icon(items[index].icon),
              title: Text(items[index].label),
              onTap: () {
                setState(() => selected = index);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  Widget _content(_Destination current) {
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
        return AdminModuleScreen(repository: widget.repository, module: current.key);
      }
      if (role == 'superadmin' && current.key == 'pagos') {
        return PaymentModuleScreen(repository: widget.repository, admin: true);
      }
      if (role == 'superadmin' && current.key == 'mensajes') {
        return MessageModuleScreen(repository: widget.repository, admin: true);
      }
    }

    if (const {'inicio', 'solicitudes', 'proyecto', 'aplicaciones'}.contains(current.key)) {
      return ClientModuleScreen(key: ValueKey('client-${current.key}-$tenantEpoch'), repository: widget.repository, module: current.key);
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

int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();

class _NativePlaceholder extends StatelessWidget {
  const _NativePlaceholder({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.construction, size: 34), const SizedBox(height: 12), Text(text), const SizedBox(height: 8), const Text('Android y Windows comparten la misma base Flutter y la misma API VITI.', style: TextStyle(color: Colors.white60))]),
          ),
        ),
      ],
    );
  }
}
