import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../apps/business_app_screen.dart';
import '../apps/electrofrio_app_screen.dart';
import '../data/viti_repository.dart';

class ClientModuleScreen extends StatefulWidget {
  const ClientModuleScreen({
    required this.repository,
    required this.module,
    required this.onNavigate,
    super.key,
  });

  final VitiRepository repository;
  final String module;
  final ValueChanged<String> onNavigate;

  @override
  State<ClientModuleScreen> createState() => _ClientModuleScreenState();
}

class _ClientModuleScreenState extends State<ClientModuleScreen> {
  bool loading = true;
  String? error;
  dynamic data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ClientModuleScreen oldWidget) {
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
          final profile = await widget.repository.clientProfile(refresh: true);
          final requests = await widget.repository.clientRequests();
          final project = await widget.repository.clientProject();
          final apps = await widget.repository.clientApps();
          data = <String, dynamic>{'perfil': profile, 'solicitudes': requests, 'proyecto': project, 'aplicaciones': apps};
          break;
        case 'solicitudes':
          data = await widget.repository.clientRequests();
          break;
        case 'proyecto':
          data = await widget.repository.clientProject();
          break;
        case 'aplicaciones':
          data = await widget.repository.clientApps();
          break;
        default:
          data = null;
      }
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No se pudo cargar la información.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _newRequest() async {
    try {
      final created = await widget.repository.createClientRequest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nueva solicitud ${created['codigo'] ?? ''} creada.')));
      await _load();
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))])));
    }

    return switch (widget.module) {
      'inicio' => _home(),
      'solicitudes' => _requests(),
      'proyecto' => _project(),
      'aplicaciones' => _apps(),
      _ => const Center(child: Text('Módulo no disponible.')),
    };
  }

  Widget _home() {
    final map = _map(data);
    final profile = _map(map['perfil']);
    final client = _map(profile['cliente']);
    final requests = _items(map['solicitudes']);
    final project = _map(map['proyecto']);
    final apps = _items(map['aplicaciones']);
    final companies = _items(profile['empresas']);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Header(
            title: 'Mi espacio VITI',
            subtitle: 'Trabaja con tu empresa, solicitudes, proyecto y aplicaciones desde un solo lugar.',
            action: IconButton.filledTonal(onPressed: _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh)),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(onPressed: () => widget.onNavigate('solicitudes'), icon: const Icon(Icons.add_circle_outline), label: const Text('Nueva solicitud')),
            OutlinedButton.icon(onPressed: () => widget.onNavigate('aplicaciones'), icon: const Icon(Icons.apps_outlined), label: const Text('Abrir mis aplicaciones')),
            OutlinedButton.icon(onPressed: () => widget.onNavigate('mensajes'), icon: const Icon(Icons.forum_outlined), label: const Text('Escribir a VITI')),
            OutlinedButton.icon(onPressed: () => widget.onNavigate('pagos'), icon: const Icon(Icons.payments_outlined), label: const Text('Mis pagos')),
          ]),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_text(client['nombre'], 'Mi cuenta'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${_text(client['telefono'], 'Sin teléfono')} · ${_text(client['ci'], 'CI no registrado')}', style: TextStyle(color: muted)),
                if (companies.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('${companies.length} empresa${companies.length == 1 ? '' : 's'} asociada${companies.length == 1 ? '' : 's'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _Stat(label: 'Solicitudes', value: '${requests.length}', icon: Icons.assignment_outlined, onTap: () => widget.onNavigate('solicitudes')),
            _Stat(label: 'Proyecto', value: project.isEmpty ? 'Sin proyecto' : '${project['progreso'] ?? 0}%', icon: Icons.account_tree_outlined, onTap: () => widget.onNavigate('proyecto')),
            _Stat(label: 'Aplicaciones', value: '${apps.length}', icon: Icons.apps_outlined, onTap: () => widget.onNavigate('aplicaciones')),
          ]),
          const SizedBox(height: 20),
          if (requests.isNotEmpty) _RequestCard(request: requests.first, onTap: () => _showRequest(requests.first)),
          if (project.isNotEmpty) ...[const SizedBox(height: 12), _ProjectCard(project: project, onTap: () => widget.onNavigate('proyecto'))],
        ],
      ),
    );
  }

  Widget _requests() {
    final requests = _items(data);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Header(title: 'Mis solicitudes', subtitle: 'Cada nueva necesidad crea una solicitud independiente.', action: FilledButton.icon(onPressed: _newRequest, icon: const Icon(Icons.add), label: const Text('Nueva solicitud'))),
          const SizedBox(height: 18),
          if (requests.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Todavía no tienes solicitudes.'))),
          for (final request in requests) Padding(padding: const EdgeInsets.only(bottom: 10), child: _RequestCard(request: request, onTap: () => _showRequest(request))),
        ],
      ),
    );
  }

  Widget _project() {
    final project = _map(data);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Header(title: 'Mi proyecto', subtitle: 'Avance técnico y estado del proyecto activo.', action: IconButton.filledTonal(onPressed: _load, icon: const Icon(Icons.refresh))),
          const SizedBox(height: 18),
          if (project.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Todavía no tienes un proyecto activo para esta empresa.'))),
          if (project.isNotEmpty) _ProjectCard(project: project, detailed: true),
        ],
      ),
    );
  }

  Widget _apps() {
    final apps = _items(data);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Header(title: 'Mis aplicaciones', subtitle: 'Entra a tus sistemas entregados y trabaja directamente desde VITI.', action: IconButton.filledTonal(onPressed: _load, icon: const Icon(Icons.refresh))),
          const SizedBox(height: 18),
          if (apps.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No hay aplicaciones registradas para esta empresa.'))),
          for (final app in apps) _appCard(app),
        ],
      ),
    );
  }

  Widget _appCard(Map<String, dynamic> app) {
    final catalog = _map(app['catalogo']);
    final key = _text(catalog['clave'], '');
    final canUse = app['puede_usar'] == true && app['acceso_cliente'] == true;
    final native = const {'servicio-tecnico', 'electrofrio'}.contains(key);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openApp(app, key, canUse, native),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            CircleAvatar(radius: 24, child: Icon(key == 'electrofrio' ? Icons.ac_unit : Icons.apps)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_text(app['nombre'], 'Aplicación VITI'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('${_pretty(app['entorno'])} · ${_pretty(app['estado_servicio'] ?? app['estado'])}', style: TextStyle(color: muted)),
              if (_text(app['estado_mensaje'], '').isNotEmpty) ...[const SizedBox(height: 3), Text(_text(app['estado_mensaje'], ''), style: TextStyle(fontSize: 12, color: muted))],
            ])),
            const SizedBox(width: 12),
            Chip(label: Text(canUse ? (native ? 'Abrir' : 'Disponible') : 'Sin acceso')),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }

  Future<void> _openApp(Map<String, dynamic> app, String key, bool canUse, bool native) async {
    if (!canUse) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_text(app['estado_mensaje'], 'Esta aplicación todavía no está disponible.'))));
      return;
    }
    if (!native) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esta aplicación todavía se está adaptando a la versión nativa.')));
      return;
    }

    final name = _text(app['nombre'], 'VITI App');
    final Widget screen = key == 'electrofrio'
        ? ElectrofrioAppScreen(appName: name)
        : BusinessAppScreen(repository: widget.repository, appKey: key, appName: name);
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _load();
  }

  Future<void> _showRequest(Map<String, dynamic> request) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_text(request['codigo'], 'SOL')} · ${_text(request['titulo'], 'Solicitud')}'),
        content: SizedBox(width: 560, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _detail('Estado', _pretty(request['estado'])),
          _detail('Empresa', _text(request['empresa_nombre'], _text(_map(request['empresa'])['nombre_comercial'], 'Sin empresa'))),
          _detail('Prioridad', _pretty(request['prioridad'])),
          if (_text(request['descripcion'], '').isNotEmpty) _detail('Descripción', _text(request['descripcion'], '')),
        ])),
        actions: [
          if (_text(request['estado'], '') == 'borrador') FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.edit_note), label: const Text('Formulario en integración nativa')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)), const SizedBox(height: 3), SelectableText(value)]));
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});
  final Map<String, dynamic> request;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.description_outlined)),
            title: Text('${_text(request['codigo'], 'SOL')} · ${_text(request['titulo'], 'Solicitud de sistema')}'),
            subtitle: Text('${_pretty(request['estado'])}${request['empresa_nombre'] != null ? ' · ${request['empresa_nombre']}' : ''}'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, this.detailed = false, this.onTap});
  final Map<String, dynamic> project;
  final bool detailed;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final progress = double.tryParse('${project['progreso'] ?? 0}') ?? 0;
    final app = _map(project['aplicacion']);
    final updates = _items(project['avances']);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_text(project['codigo'], 'PRO')} · ${_text(project['nombre'], 'Proyecto VITI')}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text('${_pretty(project['fase'])} · ${progress.toInt()}%', style: TextStyle(color: muted)),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: (progress / 100).clamp(0, 1)),
        if (detailed && app.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('Aplicación: ${_text(app['nombre'], 'VITI App')}', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('${_pretty(app['entorno'])} · ${_pretty(app['estado_operativo'] ?? app['estado'])}', style: TextStyle(color: muted)),
        ],
        if (detailed && updates.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('Últimos avances', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final update in updates.take(5)) ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: const Icon(Icons.check_circle_outline, size: 20), title: Text(_text(update['titulo'], 'Actualización')), subtitle: Text(_text(update['descripcion'], ''))),
        ],
      ]),
    );
    return Card(clipBehavior: Clip.antiAlias, child: onTap == null ? content : InkWell(onTap: onTap, child: content));
  }
}

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
List<Map<String, dynamic>> _items(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
String _pretty(dynamic value) => _text(value, 'Sin estado').replaceAll('_', ' ');

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, this.action});
  final String title;
  final String subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))]),
          ),
          ?action,
        ],
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon, this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [CircleAvatar(child: Icon(icon)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))]))]),
            ),
          ),
        ),
      );
}
