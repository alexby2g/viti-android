import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../data/viti_repository.dart';

class AdminModuleScreen extends StatefulWidget {
  const AdminModuleScreen({required this.repository, required this.module, super.key});

  final VitiRepository repository;
  final String module;

  @override
  State<AdminModuleScreen> createState() => _AdminModuleScreenState();
}

class _AdminModuleScreenState extends State<AdminModuleScreen> {
  bool loading = true;
  String? error;
  dynamic data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminModuleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.module != widget.module) _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      switch (widget.module) {
        case 'inicio':
          data = await widget.repository.adminDashboard();
          break;
        case 'empresas':
          data = await widget.repository.adminCompanies();
          break;
        case 'solicitudes':
          data = await widget.repository.adminRequests();
          break;
        case 'proyectos':
          data = await widget.repository.adminProjects();
          break;
        case 'aplicaciones':
          data = await widget.repository.adminApps();
          break;
        default:
          data = null;
      }
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No se pudo cargar este módulo administrativo.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return _AdminError(message: error!, retry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.module == 'inicio') _dashboard(_map(data)),
          if (widget.module == 'empresas') _companies(_items(data)),
          if (widget.module == 'solicitudes') _requests(_items(data)),
          if (widget.module == 'proyectos') _projects(_items(data)),
          if (widget.module == 'aplicaciones') _apps(_items(data)),
          if (!const {'inicio', 'empresas', 'solicitudes', 'proyectos', 'aplicaciones'}.contains(widget.module))
            const _AdminEmpty(text: 'Este módulo se conectará en el siguiente bloque funcional de Flutter.'),
        ],
      ),
    );
  }

  Widget _dashboard(Map<String, dynamic> source) {
    final summary = _map(source['resumen']);
    final requests = _items(source['solicitudes_recientes']);
    final projects = _items(source['proyectos_recientes']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AdminHeader(title: 'Panel VITI', subtitle: 'La operación de AGR Studio usando la misma información del panel web.'),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _AdminStat('Negocios', summary['negocios_activos'], Icons.business_outlined),
            _AdminStat('Solicitudes activas', summary['solicitudes_activas'], Icons.assignment_outlined),
            _AdminStat('Proyectos activos', summary['proyectos_activos'], Icons.account_tree_outlined),
            _AdminStat('Apps activas', summary['aplicaciones_activas'], Icons.apps_outlined),
            _AdminStat('Pendientes entrega', summary['aplicaciones_pendientes_entrega'], Icons.key_outlined),
            _AdminStat('Soportes abiertos', summary['mantenimientos_abiertos'], Icons.support_agent_outlined),
          ],
        ),
        const SizedBox(height: 22),
        _RecentBlock(title: 'Solicitudes recientes', icon: Icons.assignment_outlined, items: requests, titleBuilder: (row) => '${_text(row['codigo'], 'SOL')} · ${_text(row['titulo'], 'Solicitud')}', subtitleBuilder: (row) => _text(_map(row['empresa'])['nombre_comercial'], _text(_map(row['cliente'])['nombre'], 'Sin empresa'))),
        const SizedBox(height: 16),
        _RecentBlock(title: 'Proyectos recientes', icon: Icons.account_tree_outlined, items: projects, titleBuilder: (row) => '${_text(row['codigo'], 'PRO')} · ${_text(row['nombre'], 'Proyecto')}', subtitleBuilder: (row) => '${_text(_map(row['empresa'])['nombre_comercial'], 'Sin empresa')} · ${row['progreso'] ?? 0}%'),
      ],
    );
  }

  Widget _companies(List<Map<String, dynamic>> items) => _listPage(
        title: 'Empresas',
        subtitle: 'Negocios registrados y su actividad dentro de VITI.',
        items: items,
        icon: Icons.business_outlined,
        titleBuilder: (row) => _text(row['nombre_comercial'], 'Empresa'),
        subtitleBuilder: (row) => '${_text(row['codigo'], '')} · ${_text(row['actividad'], 'Actividad por definir')}\n${_text(_map(row['cliente'])['nombre'], 'Sin responsable')} · ${_pretty(row['estado'])}',
      );

  Widget _requests(List<Map<String, dynamic>> items) => _listPage(
        title: 'Solicitudes',
        subtitle: 'Solicitudes recibidas de todas las empresas.',
        items: items,
        icon: Icons.assignment_outlined,
        titleBuilder: (row) => '${_text(row['codigo'], 'SOL')} · ${_text(row['titulo'], 'Solicitud')}',
        subtitleBuilder: (row) => '${_text(_map(row['empresa'])['nombre_comercial'], 'Empresa por definir')} · ${_text(_map(row['cliente'])['nombre'], 'Sin cliente')}\n${_pretty(row['estado'])} · Prioridad ${_pretty(row['prioridad'])}',
      );

  Widget _projects(List<Map<String, dynamic>> items) => _listPage(
        title: 'Proyectos',
        subtitle: 'Desarrollo, progreso y responsables.',
        items: items,
        icon: Icons.account_tree_outlined,
        titleBuilder: (row) => '${_text(row['codigo'], 'PRO')} · ${_text(row['nombre'], 'Proyecto')}',
        subtitleBuilder: (row) => '${_text(_map(row['empresa'])['nombre_comercial'], 'Sin empresa')} · ${_pretty(row['fase'])}\n${row['progreso'] ?? 0}% · ${_pretty(row['estado'])}',
      );

  Widget _apps(List<Map<String, dynamic>> items) => _listPage(
        title: 'Aplicaciones',
        subtitle: 'Ciclo técnico, operación y entrega de los sistemas.',
        items: items,
        icon: Icons.apps_outlined,
        titleBuilder: (row) => _text(row['nombre'], 'Aplicación'),
        subtitleBuilder: (row) => '${_text(_map(row['empresa'])['nombre_comercial'], 'Sin empresa')} · ${_pretty(row['entorno'])}\n${_pretty(row['estado'])} · ${row['acceso_cliente'] == true ? 'Entregada' : 'Entrega pendiente'}',
      );

  Widget _listPage({required String title, required String subtitle, required List<Map<String, dynamic>> items, required IconData icon, required String Function(Map<String, dynamic>) titleBuilder, required String Function(Map<String, dynamic>) subtitleBuilder}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdminHeader(title: title, subtitle: '$subtitle · ${items.length} registros cargados'),
        const SizedBox(height: 18),
        if (items.isEmpty) const _AdminEmpty(text: 'No hay registros para mostrar.'),
        for (final row in items)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(child: Icon(icon)),
              title: Text(titleBuilder(row)),
              subtitle: Text(subtitleBuilder(row)),
              isThreeLine: true,
            ),
          ),
      ],
    );
  }
}

List<Map<String, dynamic>> _items(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
String _pretty(dynamic value) => _text(value, 'Sin estado').replaceAll('_', ' ');

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.white60))]);
}

class _AdminStat extends StatelessWidget {
  const _AdminStat(this.label, this.value, this.icon);
  final String label;
  final dynamic value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: 220, child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [CircleAvatar(child: Icon(icon)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${value ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: Colors.white60))]))]))));
}

class _RecentBlock extends StatelessWidget {
  const _RecentBlock({required this.title, required this.icon, required this.items, required this.titleBuilder, required this.subtitleBuilder});
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) titleBuilder;
  final String Function(Map<String, dynamic>) subtitleBuilder;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (items.isEmpty) const Text('Sin registros recientes.', style: TextStyle(color: Colors.white60)),
            for (final row in items) ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon), title: Text(titleBuilder(row)), subtitle: Text(subtitleBuilder(row))),
          ]),
        ),
      );
}

class _AdminEmpty extends StatelessWidget {
  const _AdminEmpty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(text, style: const TextStyle(color: Colors.white60))));
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.message, required this.retry});
  final String message;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 42), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))])));
}
