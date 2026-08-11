import 'package:flutter/material.dart';

import '../auth/session_controller.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.description);

  final String label;
  final IconData icon;
  final String description;
}

class HomeShell extends StatefulWidget {
  const HomeShell({required this.session, super.key});

  final SessionController session;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selected = 0;

  List<_Destination> get destinations {
    final role = widget.session.user?.role ?? 'cliente';
    if (role == 'soporte') {
      return const [
        _Destination('Mi trabajo', Icons.support_agent, 'Solicitudes, proyectos y casos asignados a tu cuenta.'),
        _Destination('Mensajes', Icons.forum_outlined, 'Conversaciones que AGR Studio te haya delegado.'),
        _Destination('Guía', Icons.route_outlined, 'Pasos y responsabilidades del soporte interno.'),
      ];
    }
    if (role == 'administrador' || role == 'superadmin') {
      return const [
        _Destination('Inicio', Icons.dashboard_outlined, 'Resumen operativo de AGR Studio y VITI.'),
        _Destination('Empresas', Icons.business_outlined, 'Clientes y empresas registradas en la plataforma.'),
        _Destination('Solicitudes', Icons.assignment_outlined, 'Solicitudes recibidas y su revisión.'),
        _Destination('Proyectos', Icons.account_tree_outlined, 'Desarrollo, avances y entregas.'),
        _Destination('Aplicaciones', Icons.apps_outlined, 'Ciclo técnico, acceso y aplicaciones entregadas.'),
        _Destination('Pagos', Icons.payments_outlined, 'Comprobantes, saldos y suscripciones.'),
        _Destination('Mensajes', Icons.forum_outlined, 'Buzones autorizados según tu rol.'),
        _Destination('Guía', Icons.route_outlined, 'Flujo operativo para administrar VITI.'),
      ];
    }
    return const [
      _Destination('Inicio', Icons.home_outlined, 'Tu espacio VITI y el estado general de tu cuenta.'),
      _Destination('Solicitudes', Icons.assignment_outlined, 'Crea y consulta solicitudes independientes.'),
      _Destination('Proyecto', Icons.account_tree_outlined, 'Avances, fechas y archivos del proyecto.'),
      _Destination('Aplicaciones', Icons.apps_outlined, 'Sistemas habilitados para tu empresa.'),
      _Destination('Pagos', Icons.payments_outlined, 'Comprobantes y estado de pagos.'),
      _Destination('Mensajes', Icons.forum_outlined, 'Habla con AGR Studio y comparte documentos.'),
      _Destination('Guía', Icons.route_outlined, 'Conoce los pasos desde la solicitud hasta la entrega.'),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(child: Text(widget.session.user?.name ?? 'VITI')),
              ),
              IconButton(onPressed: widget.session.busy ? null : widget.session.logout, icon: const Icon(Icons.logout)),
            ],
          ),
          drawer: desktop ? null : Drawer(child: _mobileMenu(items)),
          body: desktop
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selected,
                      extended: constraints.maxWidth >= 1180,
                      onDestinationSelected: (value) => setState(() => selected = value),
                      destinations: [
                        for (final item in items) NavigationRailDestination(icon: Icon(item.icon), label: Text(item.label)),
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
          const ListTile(title: Text('AGR Studio', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('VITI')),
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
    final user = widget.session.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(current.label, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(current.description, style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 25, child: Icon(Icons.verified_user_outlined)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? 'Usuario VITI', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            Text('Rol: ${user?.role ?? 'sin definir'} · API VITI conectada', style: const TextStyle(color: Colors.white60)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Base nativa activa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      SizedBox(height: 8),
                      Text('Esta primera fase ya comparte autenticación y permisos con VITI Web. Los módulos se irán conectando al mismo API sin duplicar la lógica de negocio.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
