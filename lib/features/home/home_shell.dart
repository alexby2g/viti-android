import 'package:flutter/material.dart';

import '../admin/admin_module_screen.dart';
import '../auth/session_controller.dart';
import '../client/client_module_screen.dart';
import '../data/viti_repository.dart';
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
    if (role == 'soporte') {
      if (current.key == 'trabajo' || current.key == 'mensajes') {
        return SupportModuleScreen(repository: widget.repository, module: current.key);
      }
      return const _NativePlaceholder(title: 'Guía de soporte', text: 'La guía interactiva se integrará aquí con el mismo flujo disponible en VITI Web.');
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
      return const _NativePlaceholder(title: 'Guía de administración', text: 'La guía interactiva de administración se integrará en esta vista.');
    }

    if (const {'inicio', 'solicitudes', 'proyecto', 'aplicaciones'}.contains(current.key)) {
      return ClientModuleScreen(repository: widget.repository, module: current.key);
    }
    if (current.key == 'pagos') {
      return PaymentModuleScreen(repository: widget.repository, admin: false);
    }
    if (current.key == 'mensajes') {
      return MessageModuleScreen(repository: widget.repository, admin: false);
    }
    return const _NativePlaceholder(title: 'Guía de empresa', text: 'La guía interactiva de empresa se integrará en esta vista.');
  }
}

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.route_outlined, size: 34),
                const SizedBox(height: 12),
                Text(text),
                const SizedBox(height: 8),
                const Text('Android y Windows comparten este mismo flujo Flutter y la misma API VITI.', style: TextStyle(color: Colors.white60)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
