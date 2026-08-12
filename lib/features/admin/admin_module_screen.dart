import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/ui/viti_ui.dart';
import '../apps/business_app_screen.dart';
import '../apps/electrofrio_app_screen.dart';
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
  final searchController = TextEditingController();
  bool loading = true;
  String? error;
  dynamic data;
  String query = '';
  String statusFilter = 'todos';
  Map<String, dynamic>? selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminModuleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.module != widget.module) {
      selected = null;
      query = '';
      statusFilter = 'todos';
      searchController.clear();
      _load();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
      if (widget.module != 'inicio' && selected != null) {
        final rows = _items(data);
        final selectedId = _int(selected!['id']);
        Map<String, dynamic>? refreshed;
        for (final row in rows) {
          if (_int(row['id']) == selectedId) {
            refreshed = row;
            break;
          }
        }
        selected = refreshed;
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
    if (widget.module == 'inicio') {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 38),
          children: [_dashboard(_map(data))],
        ),
      );
    }
    return _collectionExperience(_items(data));
  }

  Widget _dashboard(Map<String, dynamic> source) {
    final summary = _map(source['resumen']);
    final requests = _items(source['solicitudes_recientes']);
    final projects = _items(source['proyectos_recientes']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VitiPageHeader(
          title: 'Centro de operación',
          subtitle: 'Solicitudes, proyectos, entregas y soporte en una vista ejecutiva. Entra al dato y continúa el trabajo sin perder contexto.',
          actions: [IconButton.filledTonal(onPressed: _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh))],
        ),
        const SizedBox(height: 20),
        _quickActions(),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            VitiMetricTile(label: 'Negocios', value: '${summary['negocios_activos'] ?? 0}', icon: Icons.business_outlined, tone: VitiTone.info, onTap: () => widget.onNavigate('empresas')),
            VitiMetricTile(label: 'Solicitudes activas', value: '${summary['solicitudes_activas'] ?? 0}', icon: Icons.assignment_outlined, tone: VitiTone.warning, onTap: () => widget.onNavigate('solicitudes')),
            VitiMetricTile(label: 'Proyectos activos', value: '${summary['proyectos_activos'] ?? 0}', icon: Icons.account_tree_outlined, tone: VitiTone.primary, onTap: () => widget.onNavigate('proyectos')),
            VitiMetricTile(label: 'Apps activas', value: '${summary['aplicaciones_activas'] ?? 0}', icon: Icons.apps_outlined, tone: VitiTone.success, onTap: () => widget.onNavigate('aplicaciones')),
            VitiMetricTile(label: 'Pendientes de entrega', value: '${summary['aplicaciones_pendientes_entrega'] ?? 0}', icon: Icons.key_outlined, tone: VitiTone.warning, onTap: () => widget.onNavigate('aplicaciones')),
            VitiMetricTile(label: 'Soportes abiertos', value: '${summary['mantenimientos_abiertos'] ?? 0}', icon: Icons.support_agent_outlined, tone: VitiTone.info, onTap: widget.superadmin ? () => widget.onNavigate('mensajes') : null),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1040;
            final requestsPanel = _recentPanel(
              title: 'Solicitudes recientes',
              subtitle: 'Entrada de nuevos trabajos',
              icon: Icons.assignment_outlined,
              items: requests,
              kind: 'solicitud',
              onViewAll: () => widget.onNavigate('solicitudes'),
            );
            final projectsPanel = _recentPanel(
              title: 'Proyectos recientes',
              subtitle: 'Desarrollo y progreso',
              icon: Icons.account_tree_outlined,
              items: projects,
              kind: 'proyecto',
              onViewAll: () => widget.onNavigate('proyectos'),
            );
            if (!wide) return Column(children: [requestsPanel, const SizedBox(height: 14), projectsPanel]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: requestsPanel), const SizedBox(width: 14), Expanded(child: projectsPanel)],
            );
          },
        ),
      ],
    );
  }

  Widget _quickActions() {
    return VitiPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Acciones rápidas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Los accesos más frecuentes de operación VITI.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(onPressed: () => widget.onNavigate('solicitudes'), icon: const Icon(Icons.fact_check_outlined), label: const Text('Revisar solicitudes')),
              FilledButton.tonalIcon(onPressed: () => widget.onNavigate('proyectos'), icon: const Icon(Icons.account_tree_outlined), label: const Text('Gestionar proyectos')),
              FilledButton.tonalIcon(onPressed: () => widget.onNavigate('aplicaciones'), icon: const Icon(Icons.apps_outlined), label: const Text('Controlar aplicaciones')),
              if (widget.superadmin) FilledButton.tonalIcon(onPressed: () => widget.onNavigate('pagos'), icon: const Icon(Icons.receipt_long_outlined), label: const Text('Revisar pagos')),
              if (widget.superadmin) FilledButton.tonalIcon(onPressed: () => widget.onNavigate('mensajes'), icon: const Icon(Icons.forum_outlined), label: const Text('Atender mensajes')),
              OutlinedButton.icon(onPressed: () => widget.onNavigate('guia'), icon: const Icon(Icons.route_outlined), label: const Text('Guía VITI')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentPanel({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String kind,
    required VoidCallback onViewAll,
  }) {
    return VitiPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 19)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant))])),
              TextButton(onPressed: onViewAll, child: const Text('Ver todos')),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty) const VitiEmptyState(title: 'Sin actividad reciente', message: 'Los nuevos movimientos aparecerán aquí.'),
          for (final row in items.take(5))
            VitiEntityRow(
              icon: _kindIcon(kind),
              title: _rowTitle(kind, row),
              subtitle: _rowSubtitle(kind, row).replaceAll('\n', ' · '),
              badges: _rowBadges(kind, row),
              onTap: () => _openDetails(kind, row),
            ),
        ],
      ),
    );
  }

  Widget _collectionExperience(List<Map<String, dynamic>> source) {
    final meta = _metaFor(widget.module);
    final filtered = source.where((row) {
      final haystack = '${_rowTitle(meta.kind, row)} ${_rowSubtitle(meta.kind, row)}'.toLowerCase();
      final matchesQuery = query.trim().isEmpty || haystack.contains(query.toLowerCase().trim());
      final rowStatus = _statusFor(meta.kind, row);
      final matchesStatus = statusFilter == 'todos' || rowStatus == statusFilter;
      return matchesQuery && matchesStatus;
    }).toList(growable: false);
    final statuses = <String>{for (final row in source) _statusFor(meta.kind, row)}..removeWhere((value) => value.trim().isEmpty);

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1040;
        if (!desktop) {
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
              children: [
                VitiPageHeader(
                  title: meta.title,
                  subtitle: '${meta.subtitle} · ${source.length} registrados · ${filtered.length} visibles',
                  actions: [IconButton.filledTonal(onPressed: _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh))],
                ),
                const SizedBox(height: 16),
                _filters(statuses),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const VitiEmptyState(title: 'Sin resultados', message: 'Ajusta la búsqueda o los filtros para encontrar registros.')
                else
                  _entityList(meta.kind, filtered, scrollable: false),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VitiPageHeader(
                title: meta.title,
                subtitle: '${meta.subtitle} · ${source.length} registrados · ${filtered.length} visibles',
                actions: [IconButton.filledTonal(onPressed: _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh))],
              ),
              const SizedBox(height: 16),
              _filters(statuses),
              const SizedBox(height: 14),
              Expanded(
                child: filtered.isEmpty
                    ? const VitiEmptyState(title: 'Sin resultados', message: 'Ajusta la búsqueda o los filtros para encontrar registros.')
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 6, child: _entityList(meta.kind, filtered, scrollable: true)),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 4,
                            child: selected == null
                                ? _emptyInspector(meta)
                                : VitiPanel(
                                    padding: EdgeInsets.zero,
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: _inspector(meta.kind, selected!),
                                    ),
                                  ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filters(Set<String> statuses) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        VitiSearchField(controller: searchController, hint: 'Buscar por código, empresa, cliente o nombre…', onChanged: (value) => setState(() => query = value)),
        ChoiceChip(label: const Text('Todos'), selected: statusFilter == 'todos', onSelected: (_) => setState(() => statusFilter = 'todos')),
        for (final value in statuses.take(5)) ChoiceChip(label: Text(vitiPretty(value)), selected: statusFilter == value, onSelected: (_) => setState(() => statusFilter = value)),
      ],
    );
  }

  Widget _entityList(String kind, List<Map<String, dynamic>> rows, {required bool scrollable}) {
    final body = ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: !scrollable,
      physics: scrollable ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return VitiEntityRow(
          title: _rowTitle(kind, row),
          subtitle: _rowSubtitle(kind, row).replaceAll('\n', ' · '),
          icon: _kindIcon(kind),
          selected: selected != null && _int(selected!['id']) == _int(row['id']),
          badges: _rowBadges(kind, row),
          onTap: () {
            if (MediaQuery.sizeOf(context).width < 1040) {
              _openDetails(kind, row);
            } else {
              setState(() => selected = row);
            }
          },
        );
      },
    );
    return VitiPanel(padding: const EdgeInsets.all(10), child: body);
  }

  Widget _emptyInspector(_ModuleMeta meta) {
    return VitiEmptyState(
      title: 'Selecciona un registro',
      message: 'La ficha rápida aparecerá aquí. Puedes revisar contexto y ejecutar la acción principal sin cubrir la lista.',
      icon: meta.icon,
    );
  }

  Widget _inspector(String kind, Map<String, dynamic> row) {
    final company = _map(row['empresa']);
    final client = _map(row['cliente']);
    final catalog = _map(row['catalogo']);
    final appKey = _text(catalog['clave'], '');
    final nativeApp = kind == 'aplicacion' && const {'servicio-tecnico', 'electrofrio'}.contains(appKey);

    final fields = switch (kind) {
      'empresa' => <(String, String, IconData)>[
          ('Código', _text(row['codigo'], 'Sin código'), Icons.tag),
          ('Actividad', _text(row['actividad'], 'No definida'), Icons.work_outline),
          ('Responsable', _text(client['nombre'], 'Sin responsable'), Icons.person_outline),
          ('Teléfono', _text(client['telefono'], _text(row['telefono'], 'No registrado')), Icons.phone_outlined),
          ('Ciudad', _text(row['ciudad'], 'No registrada'), Icons.location_city_outlined),
        ],
      'solicitud' => <(String, String, IconData)>[
          ('Código', _text(row['codigo'], 'Sin código'), Icons.tag),
          ('Empresa', _text(company['nombre_comercial'], 'Sin empresa'), Icons.business_outlined),
          ('Cliente', _text(client['nombre'], 'Sin cliente'), Icons.person_outline),
          ('Prioridad', vitiPretty('${row['prioridad'] ?? 'normal'}'), Icons.flag_outlined),
        ],
      'proyecto' => <(String, String, IconData)>[
          ('Código', _text(row['codigo'], 'Sin código'), Icons.tag),
          ('Empresa', _text(company['nombre_comercial'], 'Sin empresa'), Icons.business_outlined),
          ('Fase', vitiPretty('${row['fase'] ?? ''}'), Icons.route_outlined),
          ('Progreso', '${row['progreso'] ?? 0}%', Icons.trending_up),
        ],
      'aplicacion' => <(String, String, IconData)>[
          ('Empresa', _text(company['nombre_comercial'], 'Sin empresa'), Icons.business_outlined),
          ('Entorno', vitiPretty('${row['entorno'] ?? ''}'), Icons.cloud_outlined),
          ('Versión', _text(row['version'], 'Sin versión'), Icons.commit_outlined),
          ('Acceso', row['acceso_cliente'] == true ? 'Entregado' : 'Pendiente', Icons.key_outlined),
          ('Proyecto', _text(_map(row['proyecto'])['codigo'], 'Sin proyecto'), Icons.account_tree_outlined),
        ],
      _ => const <(String, String, IconData)>[],
    };

    final actions = <Widget>[
      if (nativeApp) FilledButton.icon(onPressed: () => _openNativeApplication(row), icon: const Icon(Icons.open_in_new), label: const Text('Abrir sistema')),
      if (!nativeApp) FilledButton.icon(onPressed: () => _openDetails(kind, row), icon: const Icon(Icons.open_in_new), label: const Text('Abrir detalle')),
      if (kind == 'proyecto') OutlinedButton.icon(onPressed: () => _showAddProgress(row), icon: const Icon(Icons.add_task), label: const Text('Registrar avance')),
      if (kind == 'aplicacion') OutlinedButton.icon(onPressed: () => _openDetails(kind, row), icon: const Icon(Icons.tune), label: Text(nativeApp ? 'Operar app' : 'Ver operación')),
    ];

    return VitiInspector(
      title: _rowTitle(kind, row),
      subtitle: _rowSubtitle(kind, row).replaceAll('\n', ' · '),
      icon: _kindIcon(kind),
      badges: _rowBadges(kind, row),
      actions: actions,
      children: [
        for (final field in fields) VitiKeyValue(field.$1, field.$2, icon: field.$3),
        if (kind == 'proyecto') ...[
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: (_int(row['progreso']).clamp(0, 100)) / 100, minHeight: 7)),
        ],
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

  Future<void> _openNativeApplication(Map<String, dynamic> row) async {
    final id = _int(row['id']);
    if (id <= 0) return;
    try {
      final app = await widget.repository.adminApp(id);
      if (!mounted) return;
      final catalog = _map(app['catalogo']);
      final company = _map(app['empresa']);
      final key = _text(catalog['clave'], '');
      final companyId = _int(app['empresa_id'] ?? company['id']);
      if (!const {'servicio-tecnico', 'electrofrio'}.contains(key) || companyId <= 0) {
        await _showApplication(app);
        return;
      }
      final name = _text(app['nombre'], 'VITI App');
      final Widget screen = key == 'electrofrio'
          ? ElectrofrioAppScreen(appName: name, adminMode: true, companyId: companyId)
          : BusinessAppScreen(repository: widget.repository, appKey: key, appName: name, adminMode: true, companyId: companyId);
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
      if (mounted) await _load();
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  Future<void> _showGenericDetails(String kind, Map<String, dynamic> details) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 900, maxHeight: size.height * .82),
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
        );
      },
    );
  }

  Future<void> _showApplication(Map<String, dynamic> source) async {
    final hostContext = context;
    var app = Map<String, dynamic>.from(source);
    await showDialog<void>(
      context: hostContext,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogBodyContext, setDialogState) {
          final company = _map(app['empresa']);
          final catalog = _map(app['catalogo']);
          final project = _map(app['proyecto']);
          final key = _text(catalog['clave'], '');
          final companyId = _int(app['empresa_id'] ?? company['id']);
          final native = const {'servicio-tecnico', 'electrofrio'}.contains(key);

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

          final media = MediaQuery.sizeOf(dialogBodyContext);
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 960, maxHeight: media.height * .86),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 12, 16),
                    child: Row(
                      children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: Theme.of(dialogBodyContext).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(key == 'electrofrio' ? Icons.ac_unit : Icons.apps_outlined)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_text(app['nombre'], 'Aplicación VITI'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 5),
                              Wrap(spacing: 6, runSpacing: 6, children: [
                                VitiStatusBadge(vitiPretty('${app['entorno']}'), tone: vitiToneForStatus('${app['entorno']}')),
                                VitiStatusBadge(vitiPretty('${app['estado']}'), tone: vitiToneForStatus('${app['estado']}')),
                                VitiStatusBadge(app['acceso_cliente'] == true ? 'Entregada' : 'Entrega pendiente', tone: app['acceso_cliente'] == true ? VitiTone.success : VitiTone.warning),
                              ]),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 760;
                          final info = VitiPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Información', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 14),
                                VitiKeyValue('Versión', _text(app['version'], 'Sin versión'), icon: Icons.commit_outlined),
                                VitiKeyValue('Empresa', _text(company['nombre_comercial'], 'Sin empresa'), icon: Icons.business_outlined),
                                VitiKeyValue('Proyecto', _text(project['nombre'], _text(project['codigo'], 'Sin proyecto')), icon: Icons.account_tree_outlined),
                                VitiKeyValue('Entorno', vitiPretty('${app['entorno'] ?? ''}'), icon: Icons.cloud_outlined),
                              ],
                            ),
                          );
                          final operation = VitiPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Operación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 5),
                                Text('Controla ciclo, acceso y entra al sistema sin abandonar VITI.', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (native && companyId > 0)
                                      FilledButton.icon(
                                        onPressed: () async {
                                          final appName = _text(app['nombre'], 'VITI App');
                                          Navigator.of(dialogContext).pop();
                                          if (!hostContext.mounted) return;
                                          final Widget screen = key == 'electrofrio'
                                              ? ElectrofrioAppScreen(appName: appName, adminMode: true, companyId: companyId)
                                              : BusinessAppScreen(repository: widget.repository, appKey: key, appName: appName, adminMode: true, companyId: companyId);
                                          await Navigator.of(hostContext).push(MaterialPageRoute<void>(builder: (_) => screen));
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
                                          app = await widget.repository.updateAdminAppCycle(appId: _int(app['id']), environment: '${cycle['entorno']}', state: '${cycle['estado']}');
                                        });
                                      },
                                      icon: const Icon(Icons.tune),
                                      label: const Text('Cambiar ciclo'),
                                    ),
                                    if (app['acceso_cliente'] == true)
                                      OutlinedButton.icon(onPressed: () => perform(() async => app = await widget.repository.revokeAdminApp(_int(app['id']))), icon: const Icon(Icons.lock_outline), label: const Text('Revocar acceso'))
                                    else
                                      OutlinedButton.icon(onPressed: () => perform(() async => app = await widget.repository.deliverAdminApp(_int(app['id']))), icon: const Icon(Icons.key_outlined), label: const Text('Entregar acceso')),
                                  ],
                                ),
                                if (!native) ...[
                                  const SizedBox(height: 12),
                                  Text('El control administrativo está disponible; esta app todavía no tiene workspace nativo Flutter.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                                ],
                              ],
                            ),
                          );
                          if (!wide) return Column(children: [info, const SizedBox(height: 12), operation]);
                          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: info), const SizedBox(width: 12), Expanded(child: operation)]);
                        },
                      ),
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
                DropdownButtonFormField<String>(initialValue: environment, decoration: const InputDecoration(labelText: 'Entorno'), items: const [DropdownMenuItem(value: 'desarrollo', child: Text('Desarrollo')), DropdownMenuItem(value: 'beta', child: Text('Beta')), DropdownMenuItem(value: 'produccion', child: Text('Producción'))], onChanged: (value) => setDialogState(() => environment = value ?? environment)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(initialValue: state, decoration: const InputDecoration(labelText: 'Estado operativo'), items: const [DropdownMenuItem(value: 'en_pruebas', child: Text('En pruebas')), DropdownMenuItem(value: 'activo', child: Text('Activo')), DropdownMenuItem(value: 'pausado', child: Text('Pausado')), DropdownMenuItem(value: 'retirado', child: Text('Retirado'))], onChanged: (value) => setDialogState(() => state = value ?? state)),
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
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título del avance')),
                  const SizedBox(height: 12),
                  TextField(controller: descriptionController, maxLines: 4, decoration: const InputDecoration(labelText: 'Descripción')),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 500;
                      final phaseField = DropdownButtonFormField<String>(initialValue: phase, decoration: const InputDecoration(labelText: 'Fase'), items: [for (final item in phases) DropdownMenuItem(value: item, child: Text(vitiPretty(item)))], onChanged: saving ? null : (value) => setDialogState(() => phase = value ?? phase));
                      final areaField = DropdownButtonFormField<String>(initialValue: area, decoration: const InputDecoration(labelText: 'Área'), items: [for (final item in areas) DropdownMenuItem(value: item, child: Text(vitiPretty(item)))], onChanged: saving ? null : (value) => setDialogState(() => area = value ?? area));
                      if (compact) return Column(children: [phaseField, const SizedBox(height: 12), areaField]);
                      return Row(children: [Expanded(child: phaseField), const SizedBox(width: 12), Expanded(child: areaField)]);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(children: [Text('Progreso $progress%', style: const TextStyle(fontWeight: FontWeight.w800)), Expanded(child: Slider(value: progress.toDouble(), min: 0, max: 100, divisions: 20, label: '$progress%', onChanged: saving ? null : (value) => setDialogState(() => progress = value.round())))]),
                  CheckboxListTile(contentPadding: EdgeInsets.zero, value: visibleClient, onChanged: saving ? null : (value) => setDialogState(() => visibleClient = value ?? true), title: const Text('Visible para la empresa')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
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

class _GenericEntityDetails extends StatelessWidget {
  const _GenericEntityDetails({required this.kind, required this.data, this.onAddProgress});

  final String kind;
  final Map<String, dynamic> data;
  final VoidCallback? onAddProgress;

  @override
  Widget build(BuildContext context) {
    final title = _rowTitle(kind, data);
    final fields = _detailFields(kind, data);
    final related = _relatedCounts(kind, data);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 12, 16),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(_kindIcon(kind))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Wrap(spacing: 6, runSpacing: 6, children: _rowBadges(kind, data))])),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(22),
            children: [
              VitiPanel(
                child: Wrap(
                  spacing: 22,
                  runSpacing: 14,
                  children: [for (final field in fields) SizedBox(width: 220, child: VitiKeyValue(field.$1, field.$2))],
                ),
              ),
              if (related.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [for (final item in related) VitiMetricTile(label: item.$1, value: '${item.$2}', icon: item.$3, tone: VitiTone.info)],
                ),
              ],
              if (kind == 'proyecto') ...[
                const SizedBox(height: 16),
                VitiPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [const Expanded(child: Text('Avances del proyecto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900))), if (onAddProgress != null) FilledButton.icon(onPressed: onAddProgress, icon: const Icon(Icons.add_task), label: const Text('Registrar avance'))]),
                      const SizedBox(height: 10),
                      if (_items(data['avances']).isEmpty) Text('Todavía no hay avances registrados.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      for (final advance in _items(data['avances']).reversed.take(8))
                        ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Text('${advance['progreso'] ?? 0}%')), title: Text(_text(advance['titulo'], 'Avance'), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${vitiPretty('${advance['fase']}')} · ${_text(advance['descripcion'], 'Sin descripción')}')),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

_ModuleMeta _metaFor(String module) => switch (module) {
      'empresas' => const _ModuleMeta('Empresas', 'Negocios, responsables y estado de relación dentro de VITI.', 'empresa', Icons.business_outlined),
      'solicitudes' => const _ModuleMeta('Solicitudes', 'Entrada de nuevos sistemas, prioridades y avance de análisis.', 'solicitud', Icons.assignment_outlined),
      'proyectos' => const _ModuleMeta('Proyectos', 'Desarrollo, progreso, fase y responsables.', 'proyecto', Icons.account_tree_outlined),
      'aplicaciones' => const _ModuleMeta('Aplicaciones', 'Ciclo técnico, operación, acceso y entrega.', 'aplicacion', Icons.apps_outlined),
      _ => const _ModuleMeta('VITI', 'Operación administrativa.', 'registro', Icons.dashboard_outlined),
    };

class _ModuleMeta {
  const _ModuleMeta(this.title, this.subtitle, this.kind, this.icon);
  final String title;
  final String subtitle;
  final String kind;
  final IconData icon;
}

String _rowTitle(String kind, Map<String, dynamic> row) => switch (kind) {
      'empresa' => _text(row['nombre_comercial'], 'Empresa'),
      'solicitud' => '${_text(row['codigo'], 'SOL')} · ${_text(row['titulo'], 'Solicitud')}',
      'proyecto' => '${_text(row['codigo'], 'PRO')} · ${_text(row['nombre'], 'Proyecto')}',
      'aplicacion' => _text(row['nombre'], 'Aplicación'),
      _ => _text(row['nombre'], 'Registro'),
    };

String _rowSubtitle(String kind, Map<String, dynamic> row) {
  final company = _map(row['empresa']);
  final client = _map(row['cliente']);
  return switch (kind) {
    'empresa' => '${_text(row['codigo'], 'Sin código')} · ${_text(row['actividad'], 'Actividad por definir')}\n${_text(client['nombre'], 'Sin responsable')}',
    'solicitud' => '${_text(company['nombre_comercial'], 'Empresa por definir')} · ${_text(client['nombre'], 'Sin cliente')}\nPrioridad ${vitiPretty('${row['prioridad'] ?? 'normal'}')}',
    'proyecto' => '${_text(company['nombre_comercial'], 'Sin empresa')} · ${vitiPretty('${row['fase'] ?? ''}')}\n${row['progreso'] ?? 0}% de progreso',
    'aplicacion' => '${_text(company['nombre_comercial'], 'Sin empresa')} · ${vitiPretty('${row['entorno'] ?? ''}')}\n${row['acceso_cliente'] == true ? 'Acceso entregado' : 'Entrega pendiente'}',
    _ => '',
  };
}

String _statusFor(String kind, Map<String, dynamic> row) => switch (kind) {
      'aplicacion' => '${row['estado'] ?? 'sin_estado'}',
      'proyecto' => '${row['estado'] ?? row['fase'] ?? 'sin_estado'}',
      _ => '${row['estado'] ?? 'sin_estado'}',
    };

List<Widget> _rowBadges(String kind, Map<String, dynamic> row) {
  final status = _statusFor(kind, row);
  final widgets = <Widget>[VitiStatusBadge(vitiPretty(status), tone: vitiToneForStatus(status))];
  if (kind == 'solicitud') {
    final priority = '${row['prioridad'] ?? 'normal'}';
    widgets.add(VitiStatusBadge('Prioridad ${vitiPretty(priority)}', tone: priority == 'alta' || priority == 'urgente' ? VitiTone.warning : VitiTone.neutral));
  }
  if (kind == 'proyecto') widgets.add(VitiStatusBadge('${row['progreso'] ?? 0}%', tone: VitiTone.primary));
  if (kind == 'aplicacion') {
    final environment = '${row['entorno'] ?? 'desarrollo'}';
    widgets.add(VitiStatusBadge(vitiPretty(environment), tone: vitiToneForStatus(environment)));
    widgets.add(VitiStatusBadge(row['acceso_cliente'] == true ? 'Entregada' : 'Pendiente entrega', tone: row['acceso_cliente'] == true ? VitiTone.success : VitiTone.warning));
  }
  return widgets;
}

IconData _kindIcon(String kind) => switch (kind) {
      'empresa' => Icons.business_outlined,
      'solicitud' => Icons.assignment_outlined,
      'proyecto' => Icons.account_tree_outlined,
      'aplicacion' => Icons.apps_outlined,
      _ => Icons.info_outline,
    };

List<(String, String)> _detailFields(String kind, Map<String, dynamic> data) {
  final company = _map(data['empresa']);
  final client = _map(data['cliente']);
  final responsible = _map(data['responsable']);
  return switch (kind) {
    'empresa' => [
        ('Código', _text(data['codigo'], 'Sin código')),
        ('Actividad', _text(data['actividad'], 'No definida')),
        ('Estado', vitiPretty('${data['estado']}')),
        ('Responsable', _text(client['nombre'], 'Sin responsable')),
        ('Teléfono', _text(client['telefono'], _text(data['telefono'], 'No registrado'))),
        ('Ciudad', _text(data['ciudad'], 'No registrada')),
      ],
    'solicitud' => [
        ('Código', _text(data['codigo'], 'Sin código')),
        ('Estado', vitiPretty('${data['estado']}')),
        ('Prioridad', vitiPretty('${data['prioridad']}')),
        ('Empresa', _text(company['nombre_comercial'], 'Sin empresa')),
        ('Cliente', _text(client['nombre'], 'Sin cliente')),
        ('Tipo', _text(data['tipo_proyecto'], 'Sistema VITI')),
        if (_text(data['descripcion'], '').isNotEmpty) ('Descripción', _text(data['descripcion'], '')),
      ],
    'proyecto' => [
        ('Código', _text(data['codigo'], 'Sin código')),
        ('Fase', vitiPretty('${data['fase']}')),
        ('Estado', vitiPretty('${data['estado']}')),
        ('Progreso', '${data['progreso'] ?? 0}%'),
        ('Empresa', _text(company['nombre_comercial'], 'Sin empresa')),
        ('Cliente', _text(client['nombre'], 'Sin cliente')),
        ('Responsable', _text(responsible['nombre'], 'Sin asignar')),
        ('Beta', _date(data['fecha_beta'])),
        ('Entrega', _date(data['fecha_entrega'])),
      ],
    _ => const [],
  };
}

List<(String, int, IconData)> _relatedCounts(String kind, Map<String, dynamic> data) {
  if (kind != 'empresa') return const [];
  final requests = _items(data['solicitudes']);
  final projects = _items(data['proyectos']);
  final apps = _items(data['aplicaciones']);
  final result = <(String, int, IconData)>[];
  if (requests.isNotEmpty) result.add(('Solicitudes', requests.length, Icons.assignment_outlined));
  if (projects.isNotEmpty) result.add(('Proyectos', projects.length, Icons.account_tree_outlined));
  if (apps.isNotEmpty) result.add(('Aplicaciones', apps.length, Icons.apps_outlined));
  return result;
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.message, required this.retry});
  final String message;
  final Future<void> Function() retry;

  @override
  Widget build(BuildContext context) => Center(
        child: VitiEmptyState(
          title: 'No se pudo cargar VITI',
          message: message,
          icon: Icons.cloud_off,
          action: FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
        ),
      );
}

List<Map<String, dynamic>> _items(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
String _date(dynamic value) {
  final parsed = DateTime.tryParse('${value ?? ''}')?.toLocal();
  if (parsed == null) return 'No definida';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year}';
}
int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
