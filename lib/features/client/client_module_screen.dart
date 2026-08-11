import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../data/viti_repository.dart';

class ClientModuleScreen extends StatefulWidget {
  const ClientModuleScreen({required this.repository, required this.module, super.key});

  final VitiRepository repository;
  final String module;

  @override
  State<ClientModuleScreen> createState() => _ClientModuleScreenState();
}

class _ClientModuleScreenState extends State<ClientModuleScreen> {
  bool loading = true;
  bool creating = false;
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
          final values = await Future.wait<dynamic>([
            widget.repository.clientProfile(),
            widget.repository.clientRequests(),
            widget.repository.clientProject(),
            widget.repository.clientApps(),
          ]);
          data = <String, dynamic>{
            'profile': values[0],
            'requests': values[1],
            'project': values[2],
            'apps': values[3],
          };
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
      error = 'No se pudo cargar este módulo de VITI.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _createRequest() async {
    if (creating) return;
    setState(() => creating = true);
    try {
      final created = await widget.repository.createClientRequest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_text(created['codigo'], 'Nueva solicitud')} creada correctamente.')),
      );
      await _load();
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return _ErrorState(message: error!, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.module == 'inicio') _home(data as Map<String, dynamic>),
          if (widget.module == 'solicitudes') _requests((data as List).whereType<Map<String, dynamic>>().toList()),
          if (widget.module == 'proyecto') _project(data as Map<String, dynamic>?),
          if (widget.module == 'aplicaciones') _apps((data as List).whereType<Map<String, dynamic>>().toList()),
          if (!const {'inicio', 'solicitudes', 'proyecto', 'aplicaciones'}.contains(widget.module))
            const _ComingSoon(title: 'Módulo en conexión', text: 'Esta sección se conectará al mismo backend VITI en el siguiente bloque funcional.'),
        ],
      ),
    );
  }

  Widget _home(Map<String, dynamic> source) {
    final profile = _map(source['profile']);
    final requests = (source['requests'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
    final project = source['project'] is Map<String, dynamic> ? source['project'] as Map<String, dynamic> : null;
    final apps = (source['apps'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
    final companies = (profile['empresas'] as List?)?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(title: 'Mi espacio VITI', subtitle: _text(profile['nombre'], 'Empresa cliente')),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Stat(label: 'Empresas', value: '$companies', icon: Icons.business_outlined),
            _Stat(label: 'Solicitudes', value: '${requests.length}', icon: Icons.assignment_outlined),
            _Stat(label: 'Proyecto', value: project == null ? 'Sin activo' : '${project['progreso'] ?? 0}%', icon: Icons.account_tree_outlined),
            _Stat(label: 'Aplicaciones', value: '${apps.length}', icon: Icons.apps_outlined),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estado actual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(project == null
                    ? 'Todavía no hay un proyecto activo para el negocio seleccionado.'
                    : '${_text(project['codigo'], 'Proyecto')} · ${_text(project['fase'], 'fase por definir')} · ${project['progreso'] ?? 0}%'),
                if (requests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Última solicitud: ${_text(requests.first['codigo'], '')} · ${_text(requests.first['estado'], 'sin estado')}'),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _requests(List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          title: 'Mis solicitudes',
          subtitle: 'Cada nueva idea se guarda como una solicitud independiente.',
          action: FilledButton.icon(
            onPressed: creating ? null : _createRequest,
            icon: creating
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add),
            label: const Text('Nueva solicitud'),
          ),
        ),
        const SizedBox(height: 18),
        if (items.isEmpty) const _Empty(text: 'Todavía no tienes solicitudes registradas.'),
        for (final item in items)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.description_outlined)),
              title: Text('${_text(item['codigo'], 'SOL')} · ${_text(item['titulo'], 'Solicitud')}'),
              subtitle: Text('${_text(_map(item['empresa'])['nombre_comercial'], 'Empresa por definir')}\nEstado: ${_pretty(item['estado'])}'),
              isThreeLine: true,
              trailing: _StatusChip(label: _pretty(item['estado'])),
            ),
          ),
      ],
    );
  }

  Widget _project(Map<String, dynamic>? project) {
    if (project == null || project.isEmpty) {
      return const _Empty(text: 'Cuando una solicitud sea convertida en proyecto aparecerá aquí.');
    }
    final progress = double.tryParse('${project['progreso'] ?? 0}') ?? 0;
    final app = _map(project['aplicacion']);
    final advances = (project['avances'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(title: '${_text(project['codigo'], 'Proyecto')} · ${_text(project['nombre'], 'Mi proyecto')}', subtitle: '${_pretty(project['fase'])} · ${_pretty(project['estado'])}'),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [const Text('Avance', style: TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Text('${progress.round()}%')]),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: (progress.clamp(0, 100)) / 100),
                if (app.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text('Aplicación: ${_text(app['nombre'], '')} · ${_pretty(app['entorno'])} · ${_pretty(app['estado'])}'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Avances publicados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (advances.isEmpty) const _Empty(text: 'Todavía no hay avances visibles publicados.'),
        for (final advance in advances)
          Card(
            child: ListTile(
              leading: const Icon(Icons.task_alt),
              title: Text(_text(advance['titulo'], 'Avance')),
              subtitle: Text('${_pretty(advance['fase'])}${advance['descripcion'] == null ? '' : '\n${advance['descripcion']}'}'),
              isThreeLine: advance['descripcion'] != null,
            ),
          ),
      ],
    );
  }

  Widget _apps(List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(title: 'Mis aplicaciones', subtitle: 'Beta, producción, entrega y suscripción se muestran por separado.'),
        const SizedBox(height: 18),
        if (items.isEmpty) const _Empty(text: 'Todavía no tienes aplicaciones asociadas a este negocio.'),
        for (final app in items)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Expanded(child: Text(_text(app['nombre'], 'Aplicación'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), _StatusChip(label: _pretty(app['estado_servicio'] ?? app['estado']))]),
                  const SizedBox(height: 8),
                  Text('Versión ${_text(app['version'], 'en desarrollo')} · ${_pretty(app['entorno'])} · ${_pretty(app['estado'])}'),
                  const SizedBox(height: 6),
                  Text(_text(app['estado_mensaje'], app['acceso_cliente'] == true ? 'Acceso habilitado' : 'Acceso pendiente'), style: const TextStyle(color: Colors.white60)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.white60))]),
          ),
          if (action != null) action!,
        ],
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [CircleAvatar(child: Icon(icon)), const SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: Colors.white60))])]),
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Chip(label: Text(label), visualDensity: VisualDensity.compact);
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(text, style: const TextStyle(color: Colors.white60))));
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.text});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(text)])));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 42), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))])));
}
