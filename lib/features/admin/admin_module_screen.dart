import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../apps/business_app_screen.dart';
import '../data/viti_repository.dart';

class AdminModuleScreen extends StatefulWidget {
  const AdminModuleScreen({
    required this.repository,
    required this.module,
    required this.onNavigate,
    required this.superadmin,
    super.key,
  });

  final VitiRepository repository;
  final String module;
  final ValueChanged<String> onNavigate;
  final bool superadmin;

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
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      data = switch (widget.module) {
        'inicio' => await widget.repository.adminDashboard(),
        'empresas' => await widget.repository.adminCompanies(),
        'solicitudes' => await widget.repository.adminRequests(),
        'proyectos' => await widget.repository.adminProjects(),
        'aplicaciones' => await widget.repository.adminApps(),
        _ => null,
      };
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
        _AdminHeader(title: 'Centro de operación VITI', subtitle: 'Revisa, abre y continúa cada proceso desde un solo lugar.', onRefresh: _load),
        const SizedBox(height: 18),
        _QuickActions(superadmin: widget.superadmin, onNavigate: widget.onNavigate),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _AdminStat('Negocios', summary['negocios_activos'], Icons.business_outlined, onTap: () => widget.onNavigate('empresas')),
            _AdminStat('Solicitudes activas', summary['solicitudes_activas'], Icons.assignment_outlined, onTap: () => widget.onNavigate('solicitudes')),
            _AdminStat('Proyectos activos', summary['proyectos_activos'], Icons.account_tree_outlined, onTap: () => widget.onNavigate('proyectos')),
            _AdminStat('Apps activas', summary['aplicaciones_activas'], Icons.apps_outlined, onTap: () => widget.onNavigate('aplicaciones')),
            _AdminStat('Pendientes entrega', summary['aplicaciones_pendientes_entrega'], Icons.key_outlined, onTap: () => widget.onNavigate('aplicaciones')),
            _AdminStat('Soportes abiertos', summary['mantenimientos_abiertos'], Icons.support_agent_outlined, onTap: widget.superadmin ? () => widget.onNavigate('mensajes') : null),
          ],
        ),
        const SizedBox(height: 22),
        _RecentBlock(
          title: 'Solicitudes recientes',
          icon: Icons.assignment_outlined,
          items: requests,
          titleBuilder: (row) => '${_text(row['codigo'], 'SOL')} · ${_text(row['titulo'], 'Solicitud')}',
          subtitleBuilder: (row) => _text(_map(row['empresa'])['nombre_comercial'], _text(_map(row['cliente'])['nombre'], 'Sin empresa')),
          onTap: (row) => _openDetails('solicitud', row),
          onViewAll: () => widget.onNavigate('solicitudes'),
        ),
        const SizedBox(height: 16),
        _RecentBlock(
          title: 'Proyectos recientes',
          icon: Icons.account_tree_outlined,
          items: projects,
          titleBuilder: (row) => '${_text(row['codigo'], 'PRO')} · ${_text(row['nombre'], 'Proyecto')}',
          subtitleBuilder: (row) => '${_text(_map(row['empresa'])['nombre_comercial'], 'Sin empresa')} · ${row['progreso'] ?? 0}%',
          onTap: (row) => _openDetails('proyecto', row),
          onViewAll: () => widget.onNavigate('proyectos'),
        ),
      ],
    );
  }

  Widget _companies(List<Map<String, dynamic>> items) => _listPage(
        title: 'Empresas',
        subtitle: 'Negocios registrados y su actividad dentro de VITI.',
        items: items,
        icon: Icons.business_outlined,
        kind: 'empresa',
        titleBuilder: (row) => _text(row['nombre_comercial'], 'Empresa'),
        subtitleBuilder: (row) => '${_text(row['codigo'], '')} · ${_text(row['actividad'], 'Actividad por definir')}\n${_text(_map(row['cliente'])['nombre'], 'Sin responsable')} · ${_pretty(row['estado'])}',
      );

  Widget _requests(List<Map<String, dynamic>> items) => _listPage(
        title: 'Solicitudes',
        subtitle: 'Solicitudes recibidas de todas las empresas.',
        items: items,
        icon: Icons.assignment_outlined,
        kind: 'solicitud',
        titleBuilder: (row) => '${_text(row['codigo'], 'SOL')} · ${_text(row['titulo'], 'Solicitud')}',
        subtitleBuilder: (row) => '${_text(_map(row['empresa'])['nombre_comercial'], 'Empresa por definir')} · ${_text(_map(row['cliente'])['nombre'], 'Sin cliente')}\n${_pretty(row['estado'])} · Prioridad ${_pretty(row['prioridad'])}',
      );

  Widget _projects(List<Map<String, dynamic>> items) => _listPage(
        title: 'Proyectos',
        subtitle: 'Desarrollo, progreso y responsables.',
        items: items,
        icon: Icons.account_tree_outlined,
        kind: 'proyecto',
        titleBuilder: (row) => '${_text(row['codigo'], 'PRO')} · ${_text(row['nombre'], 'Proyecto')}',
        subtitleBuilder: (row) => '${_text(_map(row['empresa'])['nombre_comercial'], 'Sin empresa')} · ${_pretty(row['fase'])}\n${row['progreso'] ?? 0}% · ${_pretty(row['estado'])}',
      );

  Widget _apps(List<Map<String, dynamic>> items) => _listPage(
        title: 'Aplicaciones',
        subtitle: 'Ciclo técnico, operación, acceso y entrega de los sistemas.',
        items: items,
        icon: Icons.apps_outlined,
        kind: 'aplicacion',
        titleBuilder: (row) => _text(row['nombre'], 'Aplicación'),
        subtitleBuilder: (row) => '${_text(_map(row['empresa'])['nombre_comercial'], 'Sin empresa')} · ${_pretty(row['entorno'])}\n${_pretty(row['estado'])} · ${row['acceso_cliente'] == true ? 'Entregada' : 'Entrega pendiente'}',
      );

  Widget _listPage({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> items,
    required IconData icon,
    required String kind,
    required String Function(Map<String, dynamic>) titleBuilder,
    required String Function(Map<String, dynamic>) subtitleBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdminHeader(title: title, subtitle: '$subtitle · ${items.length} registros cargados', onRefresh: _load),
        const SizedBox(height: 18),
        if (items.isEmpty) const _AdminEmpty(text: 'No hay registros para mostrar.'),
        for (final row in items)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openDetails(kind, row),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: CircleAvatar(child: Icon(icon)),
                title: Text(titleBuilder(row), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(subtitleBuilder(row)),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
      ],
    );
  }

  Future<Map<String, dynamic>> _fetchDetails(String kind, int id) => switch (kind) {
        'empresa' => widget.repository.adminCompany(id),
        'solicitud' => widget.repository.adminRequest(id),
        'proyecto' => widget.repository.adminProject(id),
        'aplicacion' => widget.repository.adminApp(id),
        _ => throw const ApiException('Tipo de registro no soportado.'),
      };

  Future<void> _openDetails(String kind, Map<String, dynamic> row) async {
    final id = _int(row['id']);
    if (id <= 0) return;
    try {
      final details = await _fetchDetails(kind, id);
      if (!mounted) return;
      if (kind == 'aplicacion') {
        await _showApplication(details);
      } else {
        await _showGenericDetails(kind, details);
      }
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  Future<void> _showGenericDetails(String kind, Map<String, dynamic> details) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(32),
        child: SizedBox(
          width: 780,
          height: kind == 'proyecto' ? 680 : 520,
          child: _GenericEntityDetails(
            kind: kind,
            data: details,
            onAddProgress: kind == 'proyecto'
                ? () {
                    Navigator.of(dialogContext).pop();
                    _showAddProgress(details);
                  }
                : null,
          ),
        ),
      ),
    );
  }

  Future<void> _showApplication(Map<String, dynamic> source) async {
    var app = Map<String, dynamic>.from(source);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final company = _map(app['empresa']);
          final catalog = _map(app['catalogo']);
          final project = _map(app['proyecto']);
          final key = _text(catalog['clave'], '');
          final companyId = _int(app['empresa_id'] ?? company['id']);
          final native = const {'servicio-tecnico', 'electrofrio'}.contains(key);
          final colors = Theme.of(context).colorScheme;

          Future<void> refreshApp() async {
            final refreshed = await widget.repository.adminApp(_int(app['id']));
            if (dialogContext.mounted) setDialogState(() => app = refreshed);
            if (mounted) await _load();
          }

          Future<void> perform(Future<void> Function() action) async {
            try {
              await action();
              await refreshApp();
            } on ApiException catch (exception) {
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(exception.message)));
            }
          }

          return Dialog(
            insetPadding: const EdgeInsets.all(30),
            child: SizedBox(
              width: 860,
              height: 650,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 18, 12, 16),
                    decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
                    child: Row(
                      children: [
                        CircleAvatar(child: const Icon(Icons.apps_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_text(app['nombre'], 'Aplicación VITI'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text('${_pretty(app['entorno'])} · ${_pretty(app['estado'])}', style: TextStyle(color: colors.onSurfaceVariant))])),
                        IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _DetailField(label: 'Versión', value: _text(app['version'], 'Sin versión')),
                            _DetailField(label: 'Entorno', value: _pretty(app['entorno'])),
                            _DetailField(label: 'Estado', value: _pretty(app['estado'])),
                            _DetailField(label: 'Acceso', value: app['acceso_cliente'] == true ? 'Entregada' : 'Pendiente'),
                            _DetailField(label: 'Empresa', value: _text(company['nombre_comercial'], 'Sin empresa')),
                            _DetailField(label: 'Proyecto', value: _text(project['nombre'], _text(project['codigo'], 'Sin proyecto'))),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Operación de la aplicación', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 6),
                                Text('Controla el ciclo técnico, acceso y entra al sistema cuando tenga integración nativa.', style: TextStyle(color: colors.onSurfaceVariant)),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (native && companyId > 0)
                                      FilledButton.icon(
                                        onPressed: () async {
                                          Navigator.of(dialogContext).pop();
                                          await Navigator.of(context).push(MaterialPageRoute<void>(
                                            builder: (_) => BusinessAppScreen(
                                              repository: widget.repository,
                                              appKey: key,
                                              appName: _text(app['nombre'], 'VITI App'),
                                              adminMode: true,
                                              companyId: companyId,
                                            ),
                                          ));
                                          if (mounted) await _load();
                                        },
                                        icon: const Icon(Icons.open_in_new),
                                        label: const Text('Abrir sistema'),
                                      ),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final cycle = await _showAppCycleDialog(app);
                                        if (cycle == null) return;
                                        await perform(() async {
                                          app = await widget.repository.updateAdminAppCycle(
                                            appId: _int(app['id']),
                                            environment: '${cycle['entorno']}',
                                            state: '${cycle['estado']}',
                                          );
                                        });
                                      },
                                      icon: const Icon(Icons.tune),
                                      label: const Text('Cambiar ciclo'),
                                    ),
                                    if (app['acceso_cliente'] == true)
                                      OutlinedButton.icon(
                                        onPressed: () => perform(() async => app = await widget.repository.revokeAdminApp(_int(app['id']))),
                                        icon: const Icon(Icons.lock_outline),
                                        label: const Text('Revocar acceso'),
                                      )
                                    else
                                      OutlinedButton.icon(
                                        onPressed: () => perform(() async => app = await widget.repository.deliverAdminApp(_int(app['id']))),
                                        icon: const Icon(Icons.key_outlined),
                                        label: const Text('Entregar acceso'),
                                      ),
                                  ],
                                ),
                                if (!native) ...[
                                  const SizedBox(height: 12),
                                  Text('Esta aplicación todavía no tiene workspace nativo Flutter. El control de ciclo y entrega sí está disponible.', style: TextStyle(color: colors.onSurfaceVariant)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _showAppCycleDialog(Map<String, dynamic> app) async {
    var environment = const {'desarrollo', 'beta', 'produccion'}.contains('${app['entorno']}') ? '${app['entorno']}' : 'desarrollo';
    var state = const {'en_pruebas', 'activo', 'pausado', 'retirado'}.contains('${app['estado']}') ? '${app['estado']}' : 'en_pruebas';
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ciclo técnico y operativo'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: environment,
                  decoration: const InputDecoration(labelText: 'Entorno', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'desarrollo', child: Text('Desarrollo')),
                    DropdownMenuItem(value: 'beta', child: Text('Beta')),
                    DropdownMenuItem(value: 'produccion', child: Text('Producción')),
                  ],
                  onChanged: (value) => setDialogState(() => environment = value ?? environment),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: state,
                  decoration: const InputDecoration(labelText: 'Estado operativo', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'en_pruebas', child: Text('En pruebas')),
                    DropdownMenuItem(value: 'activo', child: Text('Activo')),
                    DropdownMenuItem(value: 'pausado', child: Text('Pausado')),
                    DropdownMenuItem(value: 'retirado', child: Text('Retirado')),
                  ],
                  onChanged: (value) => setDialogState(() => state = value ?? state),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, <String, dynamic>{'entorno': environment, 'estado': state}), child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddProgress(Map<String, dynamic> project) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final phases = const ['levantamiento', 'analisis', 'diseno', 'desarrollo', 'beta', 'pruebas', 'ajustes', 'implementacion', 'finalizado', 'mantenimiento'];
    final areas = const ['general', 'analisis', 'diseno', 'frontend', 'backend', 'movil', 'infraestructura', 'qa'];
    var phase = phases.contains(project['fase']) ? '${project['fase']}' : 'desarrollo';
    var area = 'general';
    var progress = _int(project['progreso']).clamp(0, 100);
    var visibleClient = true;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Registrar avance · ${_text(project['codigo'], 'Proyecto')}'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título del avance', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descriptionController, maxLines: 4, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(initialValue: phase, decoration: const InputDecoration(labelText: 'Fase', border: OutlineInputBorder()), items: [for (final item in phases) DropdownMenuItem(value: item, child: Text(_pretty(item)))], onChanged: saving ? null : (value) => setDialogState(() => phase = value ?? phase))),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(initialValue: area, decoration: const InputDecoration(labelText: 'Área', border: OutlineInputBorder()), items: [for (final item in areas) DropdownMenuItem(value: item, child: Text(_pretty(item)))], onChanged: saving ? null : (value) => setDialogState(() => area = value ?? area))),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [Text('Progreso $progress%', style: const TextStyle(fontWeight: FontWeight.w700)), Expanded(child: Slider(value: progress.toDouble(), min: 0, max: 100, divisions: 20, label: '$progress%', onChanged: saving ? null : (value) => setDialogState(() => progress = value.round())))]),
                  CheckboxListTile(contentPadding: EdgeInsets.zero, value: visibleClient, onChanged: saving ? null : (value) => setDialogState(() => visibleClient = value ?? true), title: const Text('Visible para la empresa')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
            FilledButton.icon(
              onPressed: saving ? null : () async {
                if (titleController.text.trim().isEmpty) return;
                setDialogState(() => saving = true);
                try {
                  await widget.repository.addProjectProgress(projectId: _int(project['id']), phase: phase, title: titleController.text.trim(), description: descriptionController.text, progress: progress, area: area, visibleClient: visibleClient);
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avance registrado correctamente.')));
                    await _load();
                  }
                } on ApiException catch (exception) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(exception.message)));
                    setDialogState(() => saving = false);
                  }
                }
              },
              icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_task),
              label: const Text('Guardar avance'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.superadmin, required this.onNavigate});
  final bool superadmin;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Acciones rápidas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              FilledButton.tonalIcon(onPressed: () => onNavigate('solicitudes'), icon: const Icon(Icons.fact_check_outlined), label: const Text('Revisar solicitudes')),
              FilledButton.tonalIcon(onPressed: () => onNavigate('proyectos'), icon: const Icon(Icons.account_tree_outlined), label: const Text('Gestionar proyectos')),
              FilledButton.tonalIcon(onPressed: () => onNavigate('aplicaciones'), icon: const Icon(Icons.apps_outlined), label: const Text('Controlar aplicaciones')),
              if (superadmin) FilledButton.tonalIcon(onPressed: () => onNavigate('pagos'), icon: const Icon(Icons.receipt_long_outlined), label: const Text('Revisar pagos')),
              if (superadmin) FilledButton.tonalIcon(onPressed: () => onNavigate('mensajes'), icon: const Icon(Icons.forum_outlined), label: const Text('Atender mensajes')),
              OutlinedButton.icon(onPressed: () => onNavigate('guia'), icon: const Icon(Icons.route_outlined), label: const Text('Ver guía')),
            ]),
          ]),
        ),
      );
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.title, required this.subtitle, required this.onRefresh});
  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))])),
        IconButton.filledTonal(onPressed: onRefresh, tooltip: 'Actualizar', icon: const Icon(Icons.refresh)),
      ]);
}

class _AdminStat extends StatelessWidget {
  const _AdminStat(this.label, this.value, this.icon, {this.onTap});
  final String label;
  final dynamic value;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [CircleAvatar(child: Icon(icon)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${value ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))]))]))),
        ),
      );
}

class _RecentBlock extends StatelessWidget {
  const _RecentBlock({required this.title, required this.icon, required this.items, required this.titleBuilder, required this.subtitleBuilder, required this.onTap, required this.onViewAll});
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) titleBuilder;
  final String Function(Map<String, dynamic>) subtitleBuilder;
  final ValueChanged<Map<String, dynamic>> onTap;
  final VoidCallback onViewAll;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), TextButton(onPressed: onViewAll, child: const Text('Ver todos'))]),
            const SizedBox(height: 6),
            if (items.isEmpty) Text('Sin registros recientes.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            for (final row in items) ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon), title: Text(titleBuilder(row)), subtitle: Text(subtitleBuilder(row)), trailing: const Icon(Icons.chevron_right), onTap: () => onTap(row)),
          ]),
        ),
      );
}

class _GenericEntityDetails extends StatelessWidget {
  const _GenericEntityDetails({required this.kind, required this.data, this.onAddProgress});
  final String kind;
  final Map<String, dynamic> data;
  final VoidCallback? onAddProgress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = switch (kind) {
      'empresa' => _text(data['nombre_comercial'], 'Empresa'),
      'solicitud' => '${_text(data['codigo'], 'SOL')} · ${_text(data['titulo'], 'Solicitud')}',
      'proyecto' => '${_text(data['codigo'], 'PRO')} · ${_text(data['nombre'], 'Proyecto')}',
      _ => 'Detalle',
    };
    final icon = switch (kind) {
      'empresa' => Icons.business_outlined,
      'solicitud' => Icons.assignment_outlined,
      'proyecto' => Icons.account_tree_outlined,
      _ => Icons.info_outline,
    };
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 12, 16),
        decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: Row(children: [CircleAvatar(child: Icon(icon)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(_pretty(data['estado']), style: TextStyle(color: colors.onSurfaceVariant))])), IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close))]),
      ),
      Expanded(child: ListView(padding: const EdgeInsets.all(22), children: [
        Wrap(spacing: 12, runSpacing: 12, children: _detailFields(kind, data).map((field) => _DetailField(label: field.$1, value: field.$2)).toList()),
        if (kind == 'proyecto') ...[
          const SizedBox(height: 22),
          Row(children: [const Expanded(child: Text('Avances del proyecto', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))), if (onAddProgress != null) FilledButton.icon(onPressed: onAddProgress, icon: const Icon(Icons.add_task), label: const Text('Registrar avance'))]),
          const SizedBox(height: 8),
          if (_items(data['avances']).isEmpty) Text('Todavía no hay avances registrados.', style: TextStyle(color: colors.onSurfaceVariant)),
          for (final advance in _items(data['avances']).reversed.take(8)) ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Text('${advance['progreso'] ?? 0}%')), title: Text(_text(advance['titulo'], 'Avance')), subtitle: Text('${_pretty(advance['fase'])} · ${_text(advance['descripcion'], 'Sin descripción')}')),
        ],
      ])),
    ]);
  }
}

List<(String, String)> _detailFields(String kind, Map<String, dynamic> data) {
  final company = _map(data['empresa']);
  final client = _map(data['cliente']);
  final responsible = _map(data['responsable']);
  switch (kind) {
    case 'empresa':
      return [('Código', _text(data['codigo'], 'Sin código')), ('Actividad', _text(data['actividad'], 'No definida')), ('Estado', _pretty(data['estado'])), ('Responsable', _text(client['nombre'], 'Sin responsable')), ('Teléfono', _text(client['telefono'], _text(data['telefono'], 'No registrado'))), ('Ciudad', _text(data['ciudad'], 'No registrada'))];
    case 'solicitud':
      return [('Código', _text(data['codigo'], 'Sin código')), ('Estado', _pretty(data['estado'])), ('Prioridad', _pretty(data['prioridad'])), ('Empresa', _text(company['nombre_comercial'], 'Sin empresa')), ('Cliente', _text(client['nombre'], 'Sin cliente')), ('Tipo', _text(data['tipo_proyecto'], 'Sistema VITI'))];
    case 'proyecto':
      return [('Código', _text(data['codigo'], 'Sin código')), ('Fase', _pretty(data['fase'])), ('Estado', _pretty(data['estado'])), ('Progreso', '${data['progreso'] ?? 0}%'), ('Empresa', _text(company['nombre_comercial'], 'Sin empresa')), ('Cliente', _text(client['nombre'], 'Sin cliente')), ('Responsable', _text(responsible['nombre'], 'Sin asignar')), ('Beta', _date(data['fecha_beta'])), ('Entrega', _date(data['fecha_entrega']))];
    default:
      return const [];
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]),
      );
}

class _AdminEmpty extends StatelessWidget {
  const _AdminEmpty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))));
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.message, required this.retry});
  final String message;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 42), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))])));
}

List<Map<String, dynamic>> _items(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
String _pretty(dynamic value) => _text(value, 'Sin estado').replaceAll('_', ' ');
String _date(dynamic value) {
  final parsed = DateTime.tryParse('${value ?? ''}')?.toLocal();
  if (parsed == null) return 'No definida';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year}';
}
int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
