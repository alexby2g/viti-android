import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/ui/viti_ui.dart';
import '../data/viti_repository.dart';
import 'technical_order_form.dart';
import 'technical_order_workspace.dart';
import 'technical_people_forms.dart';

class BusinessAppScreen extends StatefulWidget {
  const BusinessAppScreen({
    required this.repository,
    required this.appKey,
    required this.appName,
    this.adminMode = false,
    this.companyId,
    super.key,
  });

  final VitiRepository repository;
  final String appKey;
  final String appName;
  final bool adminMode;
  final int? companyId;

  @override
  State<BusinessAppScreen> createState() => _BusinessAppScreenState();
}

class _BusinessAppScreenState extends State<BusinessAppScreen> {
  static const _allModules = <_Module>[
    _Module('inicio', 'Inicio', Icons.dashboard_outlined),
    _Module('clientes', 'Clientes', Icons.people_outline),
    _Module('equipos', 'Computadoras', Icons.computer_outlined),
    _Module('tecnicos', 'Técnicos', Icons.engineering_outlined),
    _Module('ordenes', 'Órdenes', Icons.assignment_outlined),
    _Module('pagos', 'Pagos', Icons.payments_outlined),
    _Module('garantias', 'Garantías', Icons.verified_outlined),
    _Module('historial', 'Historial', Icons.history),
  ];

  String module = 'inicio';
  bool loading = true;
  String? error;
  dynamic data;
  Map<String, dynamic> appState = const <String, dynamic>{};

  bool get isTechnical => widget.appKey == 'servicio-tecnico';
  bool get canManage => isTechnical && appState['puede_administrar'] == true;

  Set<String> get enabledModuleKeys {
    if (!isTechnical) {
      return _allModules.where((item) => item.key != 'tecnicos').map((item) => item.key).toSet();
    }
    final raw = appState['modulos'];
    final configured = raw is List ? raw.map((item) => '$item').toSet() : <String>{};
    if (configured.isEmpty) return _allModules.map((item) => item.key).toSet();
    return <String>{'inicio', ...configured};
  }

  bool get hasPayments => enabledModuleKeys.contains('pagos');

  List<_Module> get visibleModules => _allModules
      .where((item) => enabledModuleKeys.contains(item.key) && (isTechnical || item.key != 'tecnicos'))
      .toList(growable: false);

  _Module get currentModule => visibleModules.firstWhere((item) => item.key == module, orElse: () => _allModules.first);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (isTechnical) {
      try {
        appState = await widget.repository.businessAppState(
          widget.appKey,
          admin: widget.adminMode,
          companyId: widget.companyId,
        );
      } on ApiException catch (exception) {
        if (!mounted) return;
        setState(() {
          error = exception.message;
          loading = false;
        });
        return;
      }
    }
    if (!enabledModuleKeys.contains(module)) module = 'inicio';
    await _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      data = module == 'inicio'
          ? await widget.repository.businessAppSummary(widget.appKey, admin: widget.adminMode, companyId: widget.companyId)
          : await widget.repository.businessAppList(widget.appKey, module, admin: widget.adminMode, companyId: widget.companyId);
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No se pudo cargar este módulo.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _select(String key) {
    if (module == key || !enabledModuleKeys.contains(key)) return;
    setState(() => module = key);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            titleSpacing: 2,
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(isTechnical ? Icons.computer_outlined : Icons.apps_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      Text(
                        isTechnical ? 'VITI App · servicio técnico' : 'VITI App · operación',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (isTechnical && desktop)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: VitiStatusBadge(
                    widget.adminMode ? 'Administración VITI' : canManage ? 'Administración' : 'Consulta',
                    tone: canManage ? VitiTone.primary : VitiTone.neutral,
                    icon: canManage ? Icons.edit_outlined : Icons.visibility_outlined,
                  ),
                ),
              IconButton(onPressed: loading ? null : _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh)),
              const SizedBox(width: 6),
            ],
          ),
          drawer: desktop ? null : Drawer(child: _menu(closeDrawer: true)),
          body: desktop
              ? Row(
                  children: [
                    SizedBox(width: 252, child: _menu()),
                    Expanded(child: _content()),
                  ],
                )
              : _content(),
        );
      },
    );
  }

  Widget _menu({bool closeDrawer = false}) {
    final company = _map(appState['empresa']);
    return ColoredBox(
      color: const Color(0xFF092B55),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
                        child: Text(isTechnical ? 'PC' : 'VT', style: const TextStyle(color: Color(0xFF092B55), fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VITI APP', style: TextStyle(fontSize: 8, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: .48))),
                            const SizedBox(height: 2),
                            Text(widget.appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isTechnical && company.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .07), borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white.withValues(alpha: .08))),
                      child: Row(
                        children: [
                          const Icon(Icons.business_outlined, size: 16, color: Color(0xFF9DD5FF)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EMPRESA', style: TextStyle(fontSize: 7, letterSpacing: 1, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: .42))),
                                const SizedBox(height: 2),
                                Text(_text(company['nombre_comercial'], 'Empresa VITI'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
                    child: Text('OPERACIÓN', style: TextStyle(fontSize: 8, letterSpacing: 1.25, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: .42))),
                  ),
                  for (final item in visibleModules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: module == item.key ? Colors.white.withValues(alpha: .13) : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          hoverColor: Colors.white.withValues(alpha: .06),
                          onTap: () {
                            if (closeDrawer) Navigator.of(context).pop();
                            _select(item.key);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            child: Row(
                              children: [
                                Icon(item.icon, size: 20, color: module == item.key ? Colors.white : const Color(0xFFB8CEE5)),
                                const SizedBox(width: 12),
                                Expanded(child: Text(item.label, style: TextStyle(color: module == item.key ? Colors.white : const Color(0xFFD8E6F4), fontSize: 13, fontWeight: module == item.key ? FontWeight.w800 : FontWeight.w600))),
                                if (module == item.key) Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF75B8FF), shape: BoxShape.circle)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: .08)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 13),
              child: Row(
                children: [
                  Icon(canManage ? Icons.admin_panel_settings_outlined : Icons.visibility_outlined, color: const Color(0xFF9DD5FF), size: 17),
                  const SizedBox(width: 8),
                  Expanded(child: Text(canManage ? 'Permisos de gestión activos' : 'Acceso de consulta', style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 10, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('Cargando ${currentModule.label.toLowerCase()}…', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    if (error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: VitiEmptyState(
            title: 'No se pudo cargar ${currentModule.label.toLowerCase()}',
            message: error!,
            icon: Icons.cloud_off,
            action: FilledButton.icon(onPressed: _initialize, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ),
        ),
      );
    }
    if (module == 'inicio') return _summary(_map(data));
    return _records(_list(data));
  }

  Widget _summary(Map<String, dynamic> summary) {
    final agenda = _list(summary['agenda_hoy']);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 38),
        children: [
          VitiPageHeader(
            eyebrow: 'VITI APP · ${widget.appName}',
            title: 'Centro de servicio',
            subtitle: isTechnical
                ? 'Clientes, computadoras, técnicos, órdenes, cobros y garantías conectados en una sola operación.'
                : 'Operación de ${widget.appName} integrada dentro de VITI.',
            actions: [
              if (canManage) FilledButton.icon(onPressed: () => _saveOrder(), icon: const Icon(Icons.add_task), label: const Text('Nueva orden')),
              if (canManage) OutlinedButton.icon(onPressed: () => _saveClient(), icon: const Icon(Icons.person_add_alt_1), label: const Text('Nuevo cliente')),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              VitiMetricTile(label: 'Clientes', value: '${summary['clientes'] ?? 0}', icon: Icons.people_outline, tone: VitiTone.info, onTap: () => _select('clientes')),
              VitiMetricTile(label: 'Computadoras', value: '${summary['equipos'] ?? 0}', icon: Icons.computer_outlined, tone: VitiTone.primary, onTap: () => _select('equipos')),
              if (isTechnical && enabledModuleKeys.contains('tecnicos')) VitiMetricTile(label: 'Técnicos', value: '${summary['tecnicos'] ?? 0}', icon: Icons.engineering_outlined, tone: VitiTone.info, onTap: () => _select('tecnicos')),
              VitiMetricTile(label: 'Órdenes abiertas', value: '${summary['ordenes_abiertas'] ?? 0}', icon: Icons.assignment_outlined, tone: VitiTone.warning, onTap: () => _select('ordenes')),
              if (summary.containsKey('esperando_aprobacion')) VitiMetricTile(label: 'Esperando aprobación', value: '${summary['esperando_aprobacion'] ?? 0}', icon: Icons.hourglass_bottom, tone: VitiTone.warning, onTap: () => _select('ordenes')),
              if (summary.containsKey('listos_entrega')) VitiMetricTile(label: 'Listos para entregar', value: '${summary['listos_entrega'] ?? 0}', icon: Icons.inventory_2_outlined, tone: VitiTone.success, onTap: () => _select('ordenes')),
              if (hasPayments && summary.containsKey('por_cobrar')) VitiMetricTile(label: 'Por cobrar', value: '${_money(summary['por_cobrar'])} Bs', icon: Icons.payments_outlined, tone: VitiTone.warning, onTap: () => _select('pagos')),
            ],
          ),
          const SizedBox(height: 20),
          VitiPanel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 17, 12, 14),
                  child: Row(
                    children: [
                      Container(width: 38, height: 38, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(11)), child: Icon(Icons.today_outlined, size: 19, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(width: 10),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Agenda de hoy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Text('Trabajos y servicios programados', style: TextStyle(fontSize: 11))])),
                      if (agenda.isNotEmpty) VitiStatusBadge('${agenda.length} programados', tone: VitiTone.info),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: agenda.isEmpty
                      ? const VitiEmptyState(title: 'Agenda despejada', message: 'No hay trabajos programados para hoy.', icon: Icons.event_available_outlined)
                      : Column(children: [for (final row in agenda) _orderTile(row)]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _records(List<Map<String, dynamic>> items) {
    final current = currentModule;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 38),
        children: [
          VitiPageHeader(
            eyebrow: 'VITI APP · ${widget.appName}',
            title: current.label,
            subtitle: '${items.length} registro${items.length == 1 ? '' : 's'} disponibles en este módulo.',
            actions: [
              if (canManage && module == 'clientes') FilledButton.icon(onPressed: () => _saveClient(), icon: const Icon(Icons.person_add_alt_1), label: const Text('Nuevo cliente')),
              if (canManage && module == 'equipos') FilledButton.icon(onPressed: () => _saveEquipment(), icon: const Icon(Icons.add_to_queue), label: const Text('Nueva computadora')),
              if (canManage && module == 'tecnicos') FilledButton.icon(onPressed: () => _saveTechnician(), icon: const Icon(Icons.person_add_alt), label: const Text('Nuevo técnico')),
              if (canManage && module == 'ordenes') FilledButton.icon(onPressed: () => _saveOrder(), icon: const Icon(Icons.add_task), label: const Text('Nueva orden')),
            ],
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            VitiEmptyState(title: 'Sin ${current.label.toLowerCase()}', message: 'Los registros aparecerán aquí cuando exista información disponible.', icon: current.icon)
          else
            VitiPanel(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  for (final row in items)
                    if (const {'ordenes', 'garantias', 'historial'}.contains(module)) _orderTile(row) else _recordTile(row),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _recordTile(Map<String, dynamic> row) {
    final title = switch (module) {
      'clientes' => _text(row['nombre'], 'Cliente'),
      'equipos' => '${_text(row['tipo'], 'Equipo')} ${_text(row['marca'], '')} ${_text(row['modelo'], '')}'.trim(),
      'tecnicos' => _text(row['nombre'], 'Técnico'),
      'pagos' => '${_money(row['monto'])} Bs · ${_pretty(row['metodo'])}',
      _ => _text(row['nombre'], _text(row['codigo'], 'Registro')),
    };
    final subtitle = switch (module) {
      'clientes' => '${_text(row['telefono'], 'Sin teléfono')} · ${row['activo'] == false ? 'Inactivo' : 'Activo'}',
      'equipos' => '${_text(row['cliente_nombre'], 'Sin cliente')} · Serie ${_text(row['serie'], 'N/D')} · ${row['activo'] == false ? 'Inactiva' : 'Activa'}',
      'tecnicos' => '${_text(row['especialidad'], 'Sin especialidad')} · ${row['activo'] == false ? 'Inactivo' : 'Activo'}',
      'pagos' => '${_text(row['orden_codigo'], _text(row['codigo'], 'Pago'))} · ${_text(row['cliente_nombre'], '')}',
      _ => _pretty(row['estado']),
    };
    final inactive = row['activo'] == false;
    final status = '${row['estado'] ?? ''}';
    return VitiEntityRow(
      title: title,
      subtitle: subtitle,
      icon: currentModule.icon,
      badges: [
        if (inactive) const VitiStatusBadge('Inactivo', tone: VitiTone.neutral),
        if (!inactive && const {'clientes', 'equipos', 'tecnicos'}.contains(module)) const VitiStatusBadge('Activo', tone: VitiTone.success),
        if (status.isNotEmpty && !const {'clientes', 'equipos', 'tecnicos', 'pagos'}.contains(module)) VitiStatusBadge(_pretty(status), tone: vitiToneForStatus(status)),
      ],
      onTap: () => _showRecord(row),
    );
  }

  Widget _orderTile(Map<String, dynamic> row) {
    final state = '${row['estado'] ?? 'recibido'}';
    final saldo = _number(row['saldo']);
    return VitiEntityRow(
      title: '${_text(row['codigo'], 'Orden')} · ${_text(row['cliente_nombre'], 'Cliente')}',
      subtitle: '${_stateLabel(state)} · ${_text(row['equipo_tipo'], 'Sin equipo')}${row['tecnico_nombre'] != null ? ' · ${row['tecnico_nombre']}' : ''}',
      icon: _stateIcon(state),
      badges: [
        VitiStatusBadge(_stateLabel(state), tone: _stateTone(state)),
        if (hasPayments && saldo > 0) VitiStatusBadge('Saldo ${_money(saldo)} Bs', tone: VitiTone.warning, icon: Icons.payments_outlined),
        if (hasPayments && saldo <= 0 && _number(row['total']) > 0) const VitiStatusBadge('Pagado', tone: VitiTone.success, icon: Icons.check_circle_outline),
      ],
      onTap: () => _showOrder(row),
    );
  }

  Future<void> _showRecord(Map<String, dynamic> row) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_text(row['nombre'], _text(row['codigo'], 'Detalle'))),
        content: SizedBox(width: 650, child: SingleChildScrollView(child: _detailFields(row))),
        actions: [
          if (canManage && const {'clientes', 'equipos', 'tecnicos'}.contains(module))
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteRecord(row);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
            ),
          if (canManage && const {'clientes', 'equipos', 'tecnicos'}.contains(module))
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                switch (module) {
                  case 'clientes':
                    _saveClient(initial: row);
                    break;
                  case 'equipos':
                    _saveEquipment(initial: row);
                    break;
                  case 'tecnicos':
                    _saveTechnician(initial: row);
                    break;
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _showOrder(Map<String, dynamic> row) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 1120,
          height: 800,
          child: TechnicalOrderWorkspace(
            repository: widget.repository,
            initialOrder: row,
            canManage: canManage,
            hasPayments: hasPayments,
            adminMode: widget.adminMode,
            companyId: widget.companyId,
            onEditReception: (current) {
              Navigator.of(dialogContext).pop();
              _saveOrder(initial: current);
            },
            onChanged: _load,
          ),
        ),
      ),
    );
  }

  Widget _detailFields(Map<String, dynamic> row) {
    const keys = [
      'codigo', 'estado', 'prioridad', 'fecha_recepcion', 'fecha_programada', 'hora_programada',
      'cliente_nombre', 'cliente_telefono', 'equipo_tipo', 'equipo_marca', 'equipo_modelo', 'equipo_serie', 'tecnico_nombre',
      'nombre', 'telefono', 'whatsapp', 'direccion', 'tipo', 'marca', 'modelo', 'serie', 'especificaciones', 'accesorios_recibidos', 'estado_recepcion',
      'especialidad', 'usuario', 'problema_reportado', 'diagnostico', 'propuesta', 'decision_cliente', 'trabajo_realizado', 'recomendaciones',
      'total', 'pagado', 'saldo', 'garantia_fin', 'observaciones',
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final key in keys)
        if (row[key] != null && '${row[key]}'.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_pretty(key), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              SelectableText('${row[key]}'),
            ]),
          ),
    ]);
  }

  Future<void> _saveClient({Map<String, dynamic>? initial}) async {
    final draft = await showTechnicalClientForm(context, initial: initial);
    if (draft == null) return;
    await _mutate(() async {
      if (initial == null) {
        await widget.repository.createTechnicalClient(
          name: '${draft['nombre']}', phone: '${draft['telefono']}', whatsapp: '${draft['whatsapp']}',
          address: '${draft['direccion']}', notes: '${draft['observaciones']}', active: draft['activo'] == true,
          admin: widget.adminMode, companyId: widget.companyId,
        );
      } else {
        await widget.repository.updateTechnicalClient(
          id: _int(initial['id']), name: '${draft['nombre']}', phone: '${draft['telefono']}', whatsapp: '${draft['whatsapp']}',
          address: '${draft['direccion']}', notes: '${draft['observaciones']}', active: draft['activo'] == true,
          admin: widget.adminMode, companyId: widget.companyId,
        );
      }
      module = 'clientes';
      await _load();
    }, initial == null ? 'Cliente registrado.' : 'Cliente actualizado.');
  }

  Future<void> _saveEquipment({Map<String, dynamic>? initial}) async {
    final clients = await _safeList('clientes');
    if (!mounted) return;
    if (clients.isEmpty) {
      _notice('Primero registra un cliente.');
      return;
    }
    final draft = await showTechnicalEquipmentForm(context, clients: clients, initial: initial);
    if (draft == null) return;
    await _mutate(() async {
      final args = (
        clientId: _int(draft['cliente_id']),
        type: '${draft['tipo']}',
        brand: '${draft['marca']}',
        model: '${draft['modelo']}',
        serial: '${draft['serie']}',
        specifications: '${draft['especificaciones']}',
        accessories: '${draft['accesorios_recibidos']}',
        receptionState: '${draft['estado_recepcion']}',
        notes: '${draft['observaciones']}',
        active: draft['activo'] == true,
      );
      if (initial == null) {
        await widget.repository.createTechnicalEquipment(
          clientId: args.clientId, type: args.type, brand: args.brand, model: args.model, serial: args.serial,
          specifications: args.specifications, accessories: args.accessories, receptionState: args.receptionState, notes: args.notes, active: args.active,
          admin: widget.adminMode, companyId: widget.companyId,
        );
      } else {
        await widget.repository.updateTechnicalEquipment(
          id: _int(initial['id']), clientId: args.clientId, type: args.type, brand: args.brand, model: args.model, serial: args.serial,
          specifications: args.specifications, accessories: args.accessories, receptionState: args.receptionState, notes: args.notes, active: args.active,
          admin: widget.adminMode, companyId: widget.companyId,
        );
      }
      module = 'equipos';
      await _load();
    }, initial == null ? 'Computadora registrada.' : 'Computadora actualizada.');
  }

  Future<void> _saveTechnician({Map<String, dynamic>? initial}) async {
    List<Map<String, dynamic>> users = const [];
    try {
      users = await widget.repository.technicalBusinessUsers(admin: widget.adminMode, companyId: widget.companyId);
    } on ApiException catch (exception) {
      if (mounted) _notice(exception.message);
      return;
    }
    if (!mounted) return;
    final draft = await showTechnicalTechnicianForm(context, businessUsers: users, initial: initial);
    if (draft == null) return;
    await _mutate(() async {
      if (initial == null) {
        await widget.repository.createTechnicalTechnician(
          userId: _nullableInt(draft['usuario_id']), name: '${draft['nombre']}', phone: '${draft['telefono']}',
          specialty: '${draft['especialidad']}', active: draft['activo'] == true,
          admin: widget.adminMode, companyId: widget.companyId,
        );
      } else {
        await widget.repository.updateTechnicalTechnician(
          id: _int(initial['id']), userId: _nullableInt(draft['usuario_id']), name: '${draft['nombre']}', phone: '${draft['telefono']}',
          specialty: '${draft['especialidad']}', active: draft['activo'] == true,
          admin: widget.adminMode, companyId: widget.companyId,
        );
      }
      module = 'tecnicos';
      await _load();
    }, initial == null ? 'Técnico registrado.' : 'Técnico actualizado.');
  }

  Future<void> _saveOrder({Map<String, dynamic>? initial}) async {
    final clients = await _safeList('clientes');
    final equipment = await _safeList('equipos');
    final technicians = enabledModuleKeys.contains('tecnicos') ? await _safeList('tecnicos') : const <Map<String, dynamic>>[];
    if (!mounted) return;
    if (clients.isEmpty) {
      _notice('Primero registra un cliente.');
      return;
    }
    final draft = await showTechnicalOrderForm(
      context,
      clients: clients,
      equipment: equipment,
      technicians: technicians,
      showFinancial: hasPayments,
      initial: initial,
    );
    if (draft == null) return;

    await _mutate(() async {
      final serviceCost = draft.containsKey('costo_servicio') ? _nullableDouble(draft['costo_servicio']) : _nullableDouble(initial?['costo_servicio']);
      final discount = draft.containsKey('descuento') ? _nullableDouble(draft['descuento']) : _nullableDouble(initial?['descuento']);
      if (initial == null) {
        await widget.repository.createTechnicalOrder(
          clientId: _int(draft['cliente_id']), equipmentId: _nullableInt(draft['equipo_id']), technicianId: _nullableInt(draft['tecnico_id']),
          receptionDate: '${draft['fecha_recepcion']}', scheduledDate: '${draft['fecha_programada']}', scheduledTime: '${draft['hora_programada']}',
          priority: '${draft['prioridad']}', reportedProblem: '${draft['problema_reportado']}', serviceCost: serviceCost,
          admin: widget.adminMode, companyId: widget.companyId,
        );
      } else {
        await widget.repository.updateTechnicalOrder(
          id: _int(initial['id']), clientId: _int(draft['cliente_id']), equipmentId: _nullableInt(draft['equipo_id']), technicianId: _nullableInt(draft['tecnico_id']),
          receptionDate: '${draft['fecha_recepcion']}', scheduledDate: '${draft['fecha_programada']}', scheduledTime: '${draft['hora_programada']}',
          priority: '${draft['prioridad']}', reportedProblem: '${draft['problema_reportado']}',
          diagnosis: initial['diagnostico']?.toString(), proposal: initial['propuesta']?.toString(), workDone: initial['trabajo_realizado']?.toString(),
          recommendations: initial['recomendaciones']?.toString(), serviceCost: serviceCost, discount: discount,
          admin: widget.adminMode, companyId: widget.companyId,
        );
      }
      module = 'ordenes';
      await _load();
    }, initial == null ? 'Orden creada.' : 'Datos de recepción actualizados.');
  }

  Future<List<Map<String, dynamic>>> _safeList(String resource) async {
    try {
      return await widget.repository.businessAppList('servicio-tecnico', resource, admin: widget.adminMode, companyId: widget.companyId);
    } on ApiException catch (exception) {
      if (mounted) _notice(exception.message);
      return const [];
    }
  }

  Future<void> _deleteRecord(Map<String, dynamic> row) async {
    final id = _int(row['id']);
    if (id <= 0) return;
    final label = switch (module) {
      'clientes' => 'cliente',
      'equipos' => 'computadora',
      'tecnicos' => 'técnico',
      _ => 'registro',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Eliminar $label'),
        content: Text('VITI solo permitirá eliminar este $label si no tiene historial asociado. Si ya forma parte de una orden, deberá conservarse o marcarse como inactivo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _mutate(() async {
      switch (module) {
        case 'clientes':
          await widget.repository.deleteTechnicalClient(id, admin: widget.adminMode, companyId: widget.companyId);
          break;
        case 'equipos':
          await widget.repository.deleteTechnicalEquipment(id, admin: widget.adminMode, companyId: widget.companyId);
          break;
        case 'tecnicos':
          await widget.repository.deleteTechnicalTechnician(id, admin: widget.adminMode, companyId: widget.companyId);
          break;
      }
      await _load();
    }, '${label[0].toUpperCase()}${label.substring(1)} eliminado.');
  }

  Future<void> _mutate(Future<void> Function() action, String success) async {
    try {
      await action();
      if (mounted) _notice(success);
    } on ApiException catch (exception) {
      if (mounted) _notice(exception.message);
    } catch (_) {
      if (mounted) _notice('No se pudo guardar el cambio.');
    }
  }

  void _notice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _Module {
  const _Module(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
List<Map<String, dynamic>> _list(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
int? _nullableInt(dynamic value) {
  final parsed = int.tryParse('${value ?? ''}');
  return parsed != null && parsed > 0 ? parsed : null;
}
double _number(dynamic value) => double.tryParse('${value ?? 0}') ?? 0;
double? _nullableDouble(dynamic value) {
  final text = '${value ?? ''}'.trim().replaceAll(',', '.');
  return text.isEmpty ? null : double.tryParse(text);
}
String _money(dynamic value) => _number(value).toStringAsFixed(2);
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
String _pretty(dynamic value) => _text(value, 'Sin estado').replaceAll('_', ' ');
String _stateLabel(String value) => switch (value) {
      'recibido' => 'Recibido',
      'diagnostico' => 'En diagnóstico',
      'esperando_aprobacion' => 'Esperando aprobación',
      'reparacion' => 'En reparación',
      'pruebas' => 'En pruebas',
      'listo_entrega' => 'Listo para entregar',
      'entregado' => 'Entregado',
      'sin_reparacion' => 'Sin reparación',
      _ => _pretty(value),
    };
IconData _stateIcon(String value) => switch (value) {
      'recibido' => Icons.inbox_outlined,
      'diagnostico' => Icons.search_outlined,
      'esperando_aprobacion' => Icons.hourglass_bottom,
      'reparacion' => Icons.build_outlined,
      'pruebas' => Icons.science_outlined,
      'listo_entrega' => Icons.inventory_2_outlined,
      'entregado' => Icons.task_alt,
      'sin_reparacion' => Icons.cancel_outlined,
      _ => Icons.assignment_outlined,
    };
VitiTone _stateTone(String value) => switch (value) {
      'recibido' => VitiTone.info,
      'diagnostico' => VitiTone.warning,
      'esperando_aprobacion' => VitiTone.warning,
      'reparacion' => VitiTone.primary,
      'pruebas' => VitiTone.primary,
      'listo_entrega' => VitiTone.success,
      'entregado' => VitiTone.success,
      'sin_reparacion' => VitiTone.danger,
      _ => VitiTone.neutral,
    };
