import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/ui/viti_ui.dart';
import 'electrofrio_forms.dart';
import 'electrofrio_order_workspace.dart';
import 'electrofrio_repository.dart';

class ElectrofrioAppScreen extends StatefulWidget {
  const ElectrofrioAppScreen({
    required this.appName,
    this.adminMode = false,
    this.companyId,
    super.key,
  });

  final String appName;
  final bool adminMode;
  final int? companyId;

  @override
  State<ElectrofrioAppScreen> createState() => _ElectrofrioAppScreenState();
}

class _ElectrofrioAppScreenState extends State<ElectrofrioAppScreen> {
  static const modules = <String, ({String label, IconData icon})>{
    'inicio': (label: 'Inicio', icon: Icons.dashboard_outlined),
    'clientes': (label: 'Clientes', icon: Icons.people_outline),
    'equipos': (label: 'Equipos', icon: Icons.ac_unit),
    'tecnicos': (label: 'Técnicos', icon: Icons.engineering_outlined),
    'inventario': (label: 'Inventario', icon: Icons.inventory_2_outlined),
    'ordenes': (label: 'Órdenes', icon: Icons.assignment_outlined),
    'pagos': (label: 'Pagos', icon: Icons.payments_outlined),
    'garantias': (label: 'Garantías', icon: Icons.verified_outlined),
    'historial': (label: 'Historial', icon: Icons.history),
  };

  late final ElectrofrioRepository repo;

  String module = 'inicio';
  bool loading = true;
  String? error;
  dynamic data;
  Map<String, dynamic> state = <String, dynamic>{};
  Set<String>? allowed;

  bool get canManage =>
      widget.adminMode ||
      const {'superadmin', 'administrador_viti', 'propietario', 'administrador'}.contains('${state['rol']}');

  bool get hasInventory => allowed == null || allowed!.contains('inventario');
  bool get hasPayments => allowed == null || allowed!.contains('pagos');
  bool get hasWarranty => allowed == null || allowed!.contains('garantias');

  List<String> get visible => modules.keys
      .where((key) => key == 'inicio' || allowed == null || allowed!.contains(key))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    repo = ElectrofrioRepository(adminMode: widget.adminMode, companyId: widget.companyId);
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      state = await repo.state();
      final summary = await repo.summary();
      final plan = _map(widget.adminMode ? summary['plan'] : _map(state['plan']));
      final raw = plan['modulos'];
      if (raw is List && raw.isNotEmpty) {
        allowed = raw.map((item) => '$item').toSet();
      }
      data = summary;
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No se pudo abrir Electrofrío.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _resource(String key) => key == 'inventario' ? 'materiales' : key;

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      data = module == 'inicio' ? await repo.summary() : await repo.list(_resource(module));
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No se pudo cargar este módulo.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _select(String key) {
    if (module == key) return;
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
                  child: Icon(Icons.ac_unit, size: 18, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      Text(
                        'VITI App · operación técnica',
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
              if (desktop)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: VitiStatusBadge(
                    widget.adminMode ? 'Administración VITI' : canManage ? 'Administración' : 'Consulta',
                    tone: canManage ? VitiTone.primary : VitiTone.neutral,
                    icon: canManage ? Icons.edit_outlined : Icons.visibility_outlined,
                  ),
                ),
              IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Actualizar'),
              const SizedBox(width: 8),
            ],
          ),
          drawer: desktop ? null : Drawer(child: _menu(close: true)),
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

  Widget _menu({bool close = false}) {
    final selected = modules[module];
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
                        child: const Text('VT', style: TextStyle(color: Color(0xFF092B55), fontSize: 11, fontWeight: FontWeight.w900)),
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
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .07), borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white.withValues(alpha: .08))),
                    child: Row(
                      children: [
                        Icon(selected?.icon ?? Icons.dashboard_outlined, size: 16, color: const Color(0xFF9DD5FF)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(selected?.label ?? 'Inicio', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                        VitiStatusBadge(canManage ? 'Gestión' : 'Consulta', tone: canManage ? VitiTone.success : VitiTone.neutral),
                      ],
                    ),
                  ),
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
                  for (final key in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: module == key ? Colors.white.withValues(alpha: .13) : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          hoverColor: Colors.white.withValues(alpha: .06),
                          onTap: () {
                            if (close) Navigator.pop(context);
                            _select(key);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            child: Row(
                              children: [
                                Icon(modules[key]!.icon, size: 20, color: module == key ? Colors.white : const Color(0xFFB8CEE5)),
                                const SizedBox(width: 12),
                                Expanded(child: Text(modules[key]!.label, style: TextStyle(color: module == key ? Colors.white : const Color(0xFFD8E6F4), fontSize: 13, fontWeight: module == key ? FontWeight.w800 : FontWeight.w600))),
                                if (module == key) Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF75B8FF), shape: BoxShape.circle)),
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
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF9DD5FF), size: 17),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Datos aislados por empresa', style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 10, fontWeight: FontWeight.w700))),
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
            Text('Cargando ${modules[module]?.label.toLowerCase() ?? 'VITI App'}…', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    if (error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: VitiEmptyState(
            title: 'No se pudo cargar ${modules[module]?.label.toLowerCase() ?? 'este módulo'}',
            message: error!,
            icon: Icons.cloud_off,
            action: FilledButton.icon(onPressed: _initialize, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ),
        ),
      );
    }
    return module == 'inicio' ? _summary(_map(data)) : _records(_items(data));
  }

  Widget _summary(Map<String, dynamic> summary) {
    final agenda = _items(summary['agenda_hoy']);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 38),
        children: [
          VitiPageHeader(
            eyebrow: 'VITI APP · ${widget.appName}',
            title: 'Centro de operación',
            subtitle: 'Citas, órdenes, cobros, garantías e inventario conectados en una sola vista operativa.',
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
              VitiMetricTile(label: 'Equipos', value: '${summary['equipos'] ?? 0}', icon: Icons.ac_unit, tone: VitiTone.primary, onTap: () => _select('equipos')),
              VitiMetricTile(label: 'Citas hoy', value: '${summary['citas_hoy'] ?? 0}', icon: Icons.event_outlined, tone: VitiTone.info, onTap: () => _select('ordenes')),
              VitiMetricTile(label: 'Órdenes abiertas', value: '${summary['ordenes_abiertas'] ?? 0}', icon: Icons.assignment_outlined, tone: VitiTone.warning, onTap: () => _select('ordenes')),
              if (hasPayments) VitiMetricTile(label: 'Por cobrar', value: '${_money(summary['por_cobrar'])} Bs', icon: Icons.payments_outlined, tone: VitiTone.warning, onTap: () => _select('pagos')),
              if (hasWarranty) VitiMetricTile(label: 'Garantías vigentes', value: '${summary['garantias_vigentes'] ?? 0}', icon: Icons.verified_outlined, tone: VitiTone.success, onTap: () => _select('garantias')),
              if (hasInventory) VitiMetricTile(label: 'Stock bajo', value: '${summary['stock_bajo'] ?? 0}', icon: Icons.warning_amber_outlined, tone: VitiTone.danger, onTap: () => _select('inventario')),
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
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Agenda de hoy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Text('Próximas visitas y trabajos programados', style: TextStyle(fontSize: 11))])),
                      if (agenda.isNotEmpty) VitiStatusBadge('${agenda.length} programadas', tone: VitiTone.info),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: agenda.isEmpty
                      ? const VitiEmptyState(title: 'Agenda despejada', message: 'No hay visitas programadas para hoy.', icon: Icons.event_available_outlined)
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
    final meta = modules[module]!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 38),
        children: [
          VitiPageHeader(
            eyebrow: 'VITI APP · ${widget.appName}',
            title: meta.label,
            subtitle: '${items.length} registro${items.length == 1 ? '' : 's'} disponibles en este módulo.',
            actions: [
              if (canManage && module == 'clientes') FilledButton.icon(onPressed: () => _saveClient(), icon: const Icon(Icons.person_add_alt), label: const Text('Nuevo cliente')),
              if (canManage && module == 'equipos') FilledButton.icon(onPressed: () => _saveEquipment(), icon: const Icon(Icons.add), label: const Text('Nuevo equipo')),
              if (canManage && module == 'tecnicos') FilledButton.icon(onPressed: () => _saveTechnician(), icon: const Icon(Icons.person_add), label: const Text('Nuevo técnico')),
              if (canManage && module == 'inventario') FilledButton.icon(onPressed: () => _saveMaterial(), icon: const Icon(Icons.add_box_outlined), label: const Text('Nuevo material')),
              if (canManage && module == 'ordenes') FilledButton.icon(onPressed: () => _saveOrder(), icon: const Icon(Icons.add_task), label: const Text('Nueva orden')),
            ],
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            VitiEmptyState(title: 'Sin ${meta.label.toLowerCase()}', message: 'Los registros aparecerán aquí cuando exista información disponible.', icon: meta.icon)
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
      'inventario' => _text(row['nombre'], 'Material'),
      'pagos' => '${_money(row['monto'])} Bs · ${_pretty(row['metodo'])}',
      _ => _text(row['nombre'], 'Registro'),
    };
    final subtitle = switch (module) {
      'clientes' => '${_text(row['telefono'], 'Sin teléfono')} · ${row['activo'] == false ? 'Inactivo' : 'Activo'}',
      'equipos' => '${_text(row['cliente_nombre'], 'Sin cliente')} · ${_text(row['capacidad'], 'Sin capacidad')} · ${row['activo'] == false ? 'Inactivo' : 'Activo'}',
      'tecnicos' => '${_text(row['especialidad'], 'Sin especialidad')} · ${row['activo'] == false ? 'Inactivo' : 'Activo'}',
      'inventario' => 'Stock ${row['stock'] ?? 0} ${row['unidad'] ?? ''} · mínimo ${row['stock_minimo'] ?? 0} · ${_money(row['costo_unitario'])} Bs',
      'pagos' => '${_text(row['orden_codigo'], 'Orden')} · ${_text(row['cliente_nombre'], 'Cliente')}',
      _ => '',
    };
    final inactive = row['activo'] == false;
    final lowStock = module == 'inventario' && _num(row['stock']) <= _num(row['stock_minimo']);
    return VitiEntityRow(
      title: title,
      subtitle: subtitle,
      icon: modules[module]!.icon,
      badges: [
        if (inactive) const VitiStatusBadge('Inactivo', tone: VitiTone.neutral),
        if (!inactive && const {'clientes', 'equipos', 'tecnicos'}.contains(module)) const VitiStatusBadge('Activo', tone: VitiTone.success),
        if (lowStock) const VitiStatusBadge('Stock bajo', tone: VitiTone.danger, icon: Icons.warning_amber_outlined),
      ],
      onTap: () => _showRecord(row),
    );
  }

  Widget _orderTile(Map<String, dynamic> row) {
    final stage = '${row['etapa'] ?? 'cita'}';
    final saldo = _num(row['saldo']);
    return VitiEntityRow(
      title: '${_text(row['codigo'], 'Orden')} · ${_text(row['cliente_nombre'], 'Cliente')}',
      subtitle: '${_stage(stage)} · ${_text(row['equipo_tipo'], 'Sin equipo')} · ${_text(row['tecnico_nombre'], 'Sin técnico')}',
      icon: _stageIcon(stage),
      badges: [
        VitiStatusBadge(_stage(stage), tone: _stageTone(stage)),
        if (hasPayments && saldo > 0) VitiStatusBadge('Saldo ${_money(saldo)} Bs', tone: VitiTone.warning, icon: Icons.payments_outlined),
        if (hasPayments && saldo <= 0 && _num(row['total']) > 0) const VitiStatusBadge('Pagado', tone: VitiTone.success, icon: Icons.check_circle_outline),
      ],
      onTap: () => _openOrder(row),
    );
  }

  Future<void> _showRecord(Map<String, dynamic> row) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_text(row['nombre'], 'Detalle')),
        content: SizedBox(width: 620, child: SingleChildScrollView(child: _details(row))),
        actions: [
          if (canManage && const {'clientes', 'equipos', 'tecnicos', 'inventario'}.contains(module))
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteRecord(row);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
            ),
          if (canManage && const {'clientes', 'equipos', 'tecnicos', 'inventario'}.contains(module))
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
                  case 'inventario':
                    _saveMaterial(initial: row);
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

  Widget _details(Map<String, dynamic> row) {
    const keys = [
      'nombre',
      'telefono',
      'direccion',
      'referencia',
      'observaciones',
      'tipo',
      'marca',
      'modelo',
      'serie',
      'capacidad',
      'ubicacion',
      'especialidad',
      'usuario',
      'unidad',
      'stock',
      'stock_minimo',
      'costo_unitario',
      'estado',
      'pagado_at',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in keys)
          if (row[key] != null && '${row[key]}'.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_pretty(key), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  SelectableText('${row[key]}'),
                ],
              ),
            ),
      ],
    );
  }

  Future<void> _openOrder(Map<String, dynamic> row) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 1120,
          height: 800,
          child: ElectrofrioOrderWorkspace(
            repository: repo,
            initialOrder: row,
            canManage: canManage,
            hasInventory: hasInventory,
            hasPayments: hasPayments,
            hasWarranty: hasWarranty,
            onEditAppointment: (current) {
              Navigator.pop(dialogContext);
              _saveOrder(initial: current);
            },
            onChanged: _load,
          ),
        ),
      ),
    );
  }

  Future<void> _saveClient({Map<String, dynamic>? initial}) async {
    final draft = await showElectroClientForm(context, initial: initial);
    if (draft == null) return;
    await _mutate(() async {
      if (initial == null) {
        await repo.create('clientes', draft);
      } else {
        await repo.update('clientes', _id(initial['id']), draft);
      }
      module = 'clientes';
      await _load();
    }, initial == null ? 'Cliente registrado.' : 'Cliente actualizado.');
  }

  Future<void> _saveEquipment({Map<String, dynamic>? initial}) async {
    final clients = await _safe('clientes');
    if (!mounted) return;
    if (clients.isEmpty) {
      _notice('Primero registra un cliente.');
      return;
    }
    final draft = await showElectroEquipmentForm(context, clients: clients, initial: initial);
    if (draft == null) return;
    await _mutate(() async {
      if (initial == null) {
        await repo.create('equipos', draft);
      } else {
        await repo.update('equipos', _id(initial['id']), draft);
      }
      module = 'equipos';
      await _load();
    }, initial == null ? 'Equipo registrado.' : 'Equipo actualizado.');
  }

  Future<void> _saveTechnician({Map<String, dynamic>? initial}) async {
    final users = await _safe('usuarios-negocio');
    if (!mounted) return;
    final draft = await showElectroTechnicianForm(context, users: users, initial: initial);
    if (draft == null) return;
    await _mutate(() async {
      if (initial == null) {
        await repo.create('tecnicos', draft);
      } else {
        await repo.update('tecnicos', _id(initial['id']), draft);
      }
      module = 'tecnicos';
      await _load();
    }, initial == null ? 'Técnico registrado.' : 'Técnico actualizado.');
  }

  Future<void> _saveMaterial({Map<String, dynamic>? initial}) async {
    final draft = await showElectroMaterialForm(context, initial: initial);
    if (draft == null) return;
    await _mutate(() async {
      if (initial == null) {
        await repo.create('materiales', draft);
      } else {
        await repo.update('materiales', _id(initial['id']), draft);
      }
      module = 'inventario';
      await _load();
    }, initial == null ? 'Material registrado.' : 'Material actualizado.');
  }

  Future<void> _saveOrder({Map<String, dynamic>? initial}) async {
    final clients = await _safe('clientes');
    final equipment = await _safe('equipos');
    final technicians = await _safe('tecnicos');
    if (!mounted) return;
    if (clients.isEmpty) {
      _notice('Primero registra un cliente.');
      return;
    }
    final draft = await showElectroOrderForm(
      context,
      clients: clients,
      equipment: equipment,
      technicians: technicians,
      initial: initial,
    );
    if (draft == null) return;
    if (initial != null) {
      draft.addAll(<String, dynamic>{
        'diagnostico': initial['diagnostico'],
        'propuesta': initial['propuesta'],
        'trabajo_realizado': initial['trabajo_realizado'],
        'recomendaciones': initial['recomendaciones'],
      });
    }
    await _mutate(() async {
      if (initial == null) {
        await repo.create('ordenes', draft);
      } else {
        await repo.update('ordenes', _id(initial['id']), draft);
      }
      module = 'ordenes';
      await _load();
    }, initial == null ? 'Orden creada.' : 'Cita actualizada.');
  }

  Future<List<Map<String, dynamic>>> _safe(String resource) async {
    try {
      return await repo.list(resource);
    } on ApiException catch (exception) {
      if (mounted) _notice(exception.message);
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> _deleteRecord(Map<String, dynamic> row) async {
    final resource = module == 'inventario' ? 'materiales' : module;
    final id = _id(row['id']);
    if (id <= 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('VITI permitirá eliminarlo solo si no forma parte del historial. Cuando exista trazabilidad, debe conservarse o marcarse como inactivo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _mutate(() async {
      await repo.delete(resource, id);
      await _load();
    }, 'Registro eliminado.');
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

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
List<Map<String, dynamic>> _items(dynamic value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
int _id(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
double _num(dynamic value) => double.tryParse('${value ?? 0}') ?? 0;
String _money(dynamic value) => _num(value).toStringAsFixed(2);
String _text(dynamic value, String fallback) =>
    value == null || value.toString().trim().isEmpty ? fallback : value.toString();
String _pretty(dynamic value) => _text(value, 'Sin estado').replaceAll('_', ' ');
String _stage(String value) => switch (value) {
      'cita' => 'Cita',
      'diagnostico' => 'Diagnóstico',
      'propuesta' => 'Propuesta',
      'servicio' => 'Servicio',
      'cerrada' => 'Cerrada',
      _ => _pretty(value),
    };
IconData _stageIcon(String value) => switch (value) {
      'cita' => Icons.event_outlined,
      'diagnostico' => Icons.search_outlined,
      'propuesta' => Icons.handshake_outlined,
      'servicio' => Icons.home_repair_service_outlined,
      'cerrada' => Icons.task_alt,
      _ => Icons.assignment_outlined,
    };
VitiTone _stageTone(String value) => switch (value) {
      'cita' => VitiTone.info,
      'diagnostico' => VitiTone.warning,
      'propuesta' => VitiTone.primary,
      'servicio' => VitiTone.primary,
      'cerrada' => VitiTone.success,
      _ => VitiTone.neutral,
    };
