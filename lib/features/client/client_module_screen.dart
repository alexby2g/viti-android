import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/ui/viti_ui.dart';
import '../apps/business_app_screen.dart';
import '../apps/electrofrio_app_screen.dart';
import '../data/viti_repository.dart';

class ClientModuleScreen extends StatefulWidget {
  const ClientModuleScreen({required this.repository, required this.module, required this.onNavigate, super.key});

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
    if (!mounted) return;
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
      return Center(child: VitiEmptyState(title: 'No se pudo cargar tu espacio', message: error!, icon: Icons.cloud_off, action: FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))));
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
    final source = _map(data);
    final profile = _map(source['perfil']);
    final client = _map(profile['cliente']);
    final requests = _items(source['solicitudes']);
    final project = _map(source['proyecto']);
    final apps = _items(source['aplicaciones']);
    final companies = _items(profile['empresas']);
    final latestRequest = requests.isEmpty ? <String, dynamic>{} : requests.first;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 38),
        children: [
          VitiPageHeader(
            title: 'Mi espacio VITI',
            subtitle: 'Tu empresa, solicitudes, proyecto y aplicaciones en una sola ruta. VITI te muestra dónde estás y cuál es el siguiente paso.',
            actions: [IconButton.filledTonal(onPressed: _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh))],
          ),
          const SizedBox(height: 18),
          _identityPanel(client, companies),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              VitiMetricTile(label: 'Solicitudes', value: '${requests.length}', icon: Icons.assignment_outlined, tone: VitiTone.warning, onTap: () => widget.onNavigate('solicitudes')),
              VitiMetricTile(label: 'Proyecto', value: project.isEmpty ? 'Sin proyecto' : '${project['progreso'] ?? 0}%', icon: Icons.account_tree_outlined, tone: VitiTone.primary, onTap: () => widget.onNavigate('proyecto')),
              VitiMetricTile(label: 'Aplicaciones', value: '${apps.length}', icon: Icons.apps_outlined, tone: VitiTone.success, onTap: () => widget.onNavigate('aplicaciones')),
              VitiMetricTile(label: 'Empresas', value: '${companies.length}', icon: Icons.business_outlined, tone: VitiTone.info),
            ],
          ),
          const SizedBox(height: 18),
          _nextStep(latestRequest, project, apps),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final requestPanel = latestRequest.isEmpty
                  ? VitiEmptyState(title: 'Crea tu primera solicitud', message: 'Una nueva idea genera su propia SOL y queda separada de solicitudes anteriores.', icon: Icons.assignment_add, action: FilledButton.icon(onPressed: _newRequest, icon: const Icon(Icons.add), label: const Text('Nueva solicitud')))
                  : _requestPanel(latestRequest);
              final projectPanel = project.isEmpty
                  ? const VitiEmptyState(title: 'Sin proyecto activo', message: 'Cuando una solicitud sea aprobada y convertida, el progreso aparecerá aquí.', icon: Icons.account_tree_outlined)
                  : _projectPanel(project, compact: true);
              if (!wide) return Column(children: [requestPanel, const SizedBox(height: 14), projectPanel]);
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: requestPanel), const SizedBox(width: 14), Expanded(child: projectPanel)]);
            },
          ),
        ],
      ),
    );
  }

  Widget _identityPanel(Map<String, dynamic> client, List<Map<String, dynamic>> companies) {
    final colors = Theme.of(context).colorScheme;
    return VitiPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final identity = Row(
            children: [
              Container(width: 54, height: 54, decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primary, colors.secondary]), borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.person_outline, color: Colors.white)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_text(client['nombre'], 'Mi cuenta'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('${_text(client['telefono'], 'Sin teléfono')} · ${_text(client['ci'], 'CI no registrado')}', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12))])),
            ],
          );
          final actions = Wrap(spacing: 8, runSpacing: 8, children: [FilledButton.icon(onPressed: _newRequest, icon: const Icon(Icons.add), label: const Text('Nueva solicitud')), OutlinedButton.icon(onPressed: () => widget.onNavigate('mensajes'), icon: const Icon(Icons.forum_outlined), label: const Text('Escribir a VITI')), OutlinedButton.icon(onPressed: () => widget.onNavigate('pagos'), icon: const Icon(Icons.payments_outlined), label: const Text('Mis pagos'))]);
          if (compact) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [identity, const SizedBox(height: 14), actions]);
          return Row(children: [Expanded(child: identity), const SizedBox(width: 14), actions]);
        },
      ),
    );
  }

  Widget _nextStep(Map<String, dynamic> request, Map<String, dynamic> project, List<Map<String, dynamic>> apps) {
    final requestStatus = '${request['estado'] ?? ''}';
    String title;
    String message;
    IconData icon;
    VitiTone tone;
    VoidCallback action;
    String actionLabel;

    if (request.isEmpty) {
      title = 'Empieza con una solicitud';
      message = 'Describe la necesidad de tu empresa. Cada solicitud mantiene su propio historial.';
      icon = Icons.assignment_add;
      tone = VitiTone.info;
      action = _newRequest;
      actionLabel = 'Crear solicitud';
    } else if (requestStatus == 'borrador') {
      title = 'Completa tu solicitud';
      message = 'La SOL todavía está en borrador. Completa la información para que AGR Studio pueda revisarla.';
      icon = Icons.edit_note;
      tone = VitiTone.warning;
      action = () => widget.onNavigate('solicitudes');
      actionLabel = 'Abrir solicitudes';
    } else if (project.isEmpty) {
      title = 'AGR Studio está revisando tu solicitud';
      message = 'Puedes seguir el estado y comunicarte por el buzón mientras se define alcance y propuesta.';
      icon = Icons.manage_search;
      tone = VitiTone.primary;
      action = () => widget.onNavigate('mensajes');
      actionLabel = 'Abrir buzón';
    } else if (apps.any((app) => app['puede_usar'] == true && app['acceso_cliente'] == true)) {
      title = 'Tu aplicación está disponible';
      message = 'Ya puedes entrar al sistema entregado y trabajar con la información de tu empresa.';
      icon = Icons.verified_user_outlined;
      tone = VitiTone.success;
      action = () => widget.onNavigate('aplicaciones');
      actionLabel = 'Abrir aplicaciones';
    } else {
      title = 'Tu proyecto está en desarrollo';
      message = 'Revisa el progreso, avances visibles y fechas del proyecto activo.';
      icon = Icons.terminal;
      tone = VitiTone.primary;
      action = () => widget.onNavigate('proyecto');
      actionLabel = 'Ver proyecto';
    }

    final color = vitiToneColor(context, tone);
    return VitiPanel(
      tone: tone,
      selected: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35))])),
          const SizedBox(width: 12),
          FilledButton(onPressed: action, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Widget _requests() {
    final requests = _items(data);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 38),
        children: [
          VitiPageHeader(title: 'Mis solicitudes', subtitle: 'Cada nueva necesidad genera una SOL independiente; las anteriores permanecen como historial.', actions: [FilledButton.icon(onPressed: _newRequest, icon: const Icon(Icons.add), label: const Text('Nueva solicitud'))]),
          const SizedBox(height: 18),
          if (requests.isEmpty) VitiEmptyState(title: 'Todavía no tienes solicitudes', message: 'Crea una solicitud para iniciar un nuevo proceso con AGR Studio.', icon: Icons.assignment_add, action: FilledButton.icon(onPressed: _newRequest, icon: const Icon(Icons.add), label: const Text('Nueva solicitud'))),
          for (final request in requests) _requestRow(request),
        ],
      ),
    );
  }

  Widget _requestRow(Map<String, dynamic> request) {
    final status = '${request['estado'] ?? 'borrador'}';
    return VitiEntityRow(
      title: '${_text(request['codigo'], 'SOL')} · ${_text(request['titulo'], 'Solicitud de sistema')}',
      subtitle: _text(request['empresa_nombre'], _text(_map(request['empresa'])['nombre_comercial'], 'Empresa por definir')),
      icon: Icons.description_outlined,
      badges: [VitiStatusBadge(vitiPretty(status), tone: vitiToneForStatus(status)), if (request['prioridad'] != null) VitiStatusBadge('Prioridad ${vitiPretty('${request['prioridad']}')}', tone: VitiTone.neutral)],
      onTap: () => _showRequest(request),
    );
  }

  Widget _requestPanel(Map<String, dynamic> request) {
    final status = '${request['estado'] ?? 'borrador'}';
    return VitiInspector(
      title: '${_text(request['codigo'], 'SOL')} · ${_text(request['titulo'], 'Solicitud')}',
      subtitle: 'Tu solicitud más reciente',
      icon: Icons.assignment_outlined,
      badges: [VitiStatusBadge(vitiPretty(status), tone: vitiToneForStatus(status))],
      children: [VitiKeyValue('Empresa', _text(request['empresa_nombre'], _text(_map(request['empresa'])['nombre_comercial'], 'Sin empresa')), icon: Icons.business_outlined), VitiKeyValue('Prioridad', vitiPretty('${request['prioridad'] ?? 'normal'}'), icon: Icons.flag_outlined)],
      actions: [OutlinedButton.icon(onPressed: () => _showRequest(request), icon: const Icon(Icons.open_in_new), label: const Text('Ver solicitud')), TextButton(onPressed: () => widget.onNavigate('solicitudes'), child: const Text('Ver historial'))],
    );
  }

  Widget _project() {
    final project = _map(data);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 38),
        children: [
          VitiPageHeader(title: 'Mi proyecto', subtitle: 'Progreso técnico, fase actual, aplicación y avances visibles de tu proyecto.', actions: [IconButton.filledTonal(onPressed: _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh))]),
          const SizedBox(height: 18),
          if (project.isEmpty) const VitiEmptyState(title: 'Todavía no tienes un proyecto activo', message: 'Cuando una solicitud aprobada se convierta en proyecto, aparecerá aquí.', icon: Icons.account_tree_outlined),
          if (project.isNotEmpty) _projectPanel(project, compact: false),
        ],
      ),
    );
  }

  Widget _projectPanel(Map<String, dynamic> project, {required bool compact}) {
    final progress = (double.tryParse('${project['progreso'] ?? 0}') ?? 0).clamp(0, 100);
    final app = _map(project['aplicacion']);
    final updates = _items(project['avances']);
    final phase = '${project['fase'] ?? 'desarrollo'}';
    final status = '${project['estado'] ?? 'activo'}';
    return VitiPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.account_tree_outlined)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_text(project['codigo'], 'PRO')} · ${_text(project['nombre'], 'Proyecto VITI')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Wrap(spacing: 6, runSpacing: 6, children: [VitiStatusBadge(vitiPretty(phase), tone: VitiTone.primary), VitiStatusBadge(vitiPretty(status), tone: vitiToneForStatus(status)), VitiStatusBadge('${progress.toInt()}%', tone: VitiTone.info)])]))]),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress / 100, minHeight: 9))), const SizedBox(width: 12), Text('${progress.toInt()}%', style: const TextStyle(fontWeight: FontWeight.w900))]),
          if (!compact) ...[
            const SizedBox(height: 18),
            LayoutBuilder(builder: (context, constraints) {
              final fields = <Widget>[VitiKeyValue('Fase actual', vitiPretty(phase), icon: Icons.route_outlined), VitiKeyValue('Estado', vitiPretty(status), icon: Icons.flag_outlined), if (app.isNotEmpty) VitiKeyValue('Aplicación', _text(app['nombre'], 'VITI App'), icon: Icons.apps_outlined), if (app.isNotEmpty) VitiKeyValue('Entorno', vitiPretty('${app['entorno'] ?? ''}'), icon: Icons.cloud_outlined)];
              return Wrap(spacing: 24, runSpacing: 4, children: [for (final field in fields) SizedBox(width: 230, child: field)]);
            }),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            const Text('Últimos avances', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (updates.isEmpty) Text('Todavía no hay avances visibles para tu empresa.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            for (final update in updates.take(6)) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.check_circle_outline, size: 20), title: Text(_text(update['titulo'], 'Actualización'), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(_text(update['descripcion'], 'Sin descripción'))),
          ],
        ],
      ),
    );
  }

  Widget _apps() {
    final apps = _items(data);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 38),
        children: [
          VitiPageHeader(title: 'Mis aplicaciones', subtitle: 'Tus sistemas conectados a VITI, con estado de acceso y operación claramente separados.', actions: [IconButton.filledTonal(onPressed: _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh))]),
          const SizedBox(height: 18),
          if (apps.isEmpty) const VitiEmptyState(title: 'No hay aplicaciones registradas', message: 'Cuando un proyecto sea entregado, su aplicación aparecerá aquí.', icon: Icons.apps_outlined),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth >= 980 ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth;
            return Wrap(spacing: 14, runSpacing: 14, children: [for (final app in apps) SizedBox(width: width, child: _appCard(app))]);
          }),
        ],
      ),
    );
  }

  Widget _appCard(Map<String, dynamic> app) {
    final catalog = _map(app['catalogo']);
    final key = _text(catalog['clave'], '');
    final canUse = app['puede_usar'] == true && app['acceso_cliente'] == true;
    final native = const {'servicio-tecnico', 'electrofrio'}.contains(key);
    final status = '${app['estado_servicio'] ?? app['estado'] ?? 'en_pruebas'}';
    final environment = '${app['entorno'] ?? 'desarrollo'}';
    return VitiPanel(
      selected: canUse,
      tone: canUse ? VitiTone.success : VitiTone.neutral,
      onTap: () => _openApp(app, key, canUse, native),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(key == 'electrofrio' ? Icons.ac_unit : Icons.apps_outlined)), const SizedBox(width: 12), Expanded(child: Text(_text(app['nombre'], 'Aplicación VITI'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant)]),
          const SizedBox(height: 13),
          Wrap(spacing: 6, runSpacing: 6, children: [VitiStatusBadge(vitiPretty(environment), tone: vitiToneForStatus(environment)), VitiStatusBadge(vitiPretty(status), tone: vitiToneForStatus(status)), VitiStatusBadge(canUse ? 'Acceso habilitado' : 'Sin acceso', tone: canUse ? VitiTone.success : VitiTone.warning)]),
          if (_text(app['estado_mensaje'], '').isNotEmpty) ...[const SizedBox(height: 12), Text(_text(app['estado_mensaje'], ''), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35))],
          const SizedBox(height: 14),
          Row(children: [Expanded(child: Text(canUse && native ? 'Lista para trabajar desde VITI' : native ? 'Integración nativa disponible' : 'Controlada desde VITI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant))), if (canUse && native) FilledButton.icon(onPressed: () => _openApp(app, key, canUse, native), icon: const Icon(Icons.open_in_new, size: 18), label: const Text('Abrir'))]),
        ],
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
    final Widget screen = key == 'electrofrio' ? ElectrofrioAppScreen(appName: name) : BusinessAppScreen(repository: widget.repository, appKey: key, appName: name);
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _load();
  }

  Future<void> _showRequest(Map<String, dynamic> request) async {
    final status = '${request['estado'] ?? 'borrador'}';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_text(request['codigo'], 'SOL')} · ${_text(request['titulo'], 'Solicitud')}'),
        content: SizedBox(
          width: 600,
          child: VitiPanel(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Wrap(spacing: 6, runSpacing: 6, children: [VitiStatusBadge(vitiPretty(status), tone: vitiToneForStatus(status)), VitiStatusBadge('Prioridad ${vitiPretty('${request['prioridad'] ?? 'normal'}')}', tone: VitiTone.neutral)]), const SizedBox(height: 16), VitiKeyValue('Empresa', _text(request['empresa_nombre'], _text(_map(request['empresa'])['nombre_comercial'], 'Sin empresa')), icon: Icons.business_outlined), if (_text(request['descripcion'], '').isNotEmpty) VitiKeyValue('Descripción', _text(request['descripcion'], ''), icon: Icons.notes)]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar'))],
      ),
    );
  }
}

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
List<Map<String, dynamic>> _items(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
