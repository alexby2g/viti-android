import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.appName, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  'Electrofrío · operación técnica',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              Chip(
                avatar: Icon(canManage ? Icons.edit_outlined : Icons.visibility_outlined, size: 17),
                label: Text(widget.adminMode ? 'Administración VITI' : canManage ? 'Administración' : 'Consulta'),
              ),
              const SizedBox(width: 6),
              IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Actualizar'),
              const SizedBox(width: 8),
            ],
          ),
          drawer: desktop ? null : Drawer(child: _menu(close: true)),
          body: desktop
              ? Row(
                  children: [
                    SizedBox(width: 245, child: _menu()),
                    const VerticalDivider(width: 1),
                    Expanded(child: _content()),
                  ],
                )
              : _content(),
        );
      },
    );
  }

  Widget _menu({bool close = false}) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VITI APP',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(widget.appName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          for (final key in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: ListTile(
                selected: module == key,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(modules[key]!.icon),
                title: Text(modules[key]!.label),
                onTap: () {
                  if (close) Navigator.pop(context);
                  _select(key);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _content() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 42),
            const SizedBox(height: 10),
            Text(error!),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _initialize, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      );
    }
    return module == 'inicio' ? _summary(_map(data)) : _records(_items(data));
  }

  Widget _summary(Map<String, dynamic> summary) {
    final agenda = _items(summary['agenda_hoy']);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _header(
          'Inicio',
          'Citas, órdenes, cobros e inventario en una sola operación.',
          actions: [
            if (canManage)
              FilledButton.icon(onPressed: () => _saveOrder(), icon: const Icon(Icons.add), label: const Text('Nueva orden')),
            if (canManage)
              OutlinedButton.icon(onPressed: () => _saveClient(), icon: const Icon(Icons.person_add_alt_1), label: const Text('Nuevo cliente')),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _stat('Clientes', summary['clientes'], Icons.people_outline, () => _select('clientes')),
            _stat('Equipos', summary['equipos'], Icons.ac_unit, () => _select('equipos')),
            _stat('Citas hoy', summary['citas_hoy'], Icons.event_outlined, () => _select('ordenes')),
            _stat('Órdenes abiertas', summary['ordenes_abiertas'], Icons.assignment_outlined, () => _select('ordenes')),
            if (hasPayments)
              _stat('Por cobrar', '${_money(summary['por_cobrar'])} Bs', Icons.payments_outlined, () => _select('pagos')),
            if (hasWarranty)
              _stat('Garantías vigentes', summary['garantias_vigentes'], Icons.verified_outlined, () => _select('garantias')),
            if (hasInventory)
              _stat('Stock bajo', summary['stock_bajo'], Icons.warning_amber_outlined, () => _select('inventario')),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Agenda de hoy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                if (agenda.isEmpty)
                  Text('No hay visitas programadas para hoy.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                for (final row in agenda) _orderTile(row),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _records(List<Map<String, dynamic>> items) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _header(
          modules[module]!.label,
          '${items.length} registros cargados.',
          actions: [
            if (canManage && module == 'clientes')
              FilledButton.icon(onPressed: () => _saveClient(), icon: const Icon(Icons.person_add_alt), label: const Text('Nuevo cliente')),
            if (canManage && module == 'equipos')
              FilledButton.icon(onPressed: () => _saveEquipment(), icon: const Icon(Icons.add), label: const Text('Nuevo equipo')),
            if (canManage && module == 'tecnicos')
              FilledButton.icon(onPressed: () => _saveTechnician(), icon: const Icon(Icons.person_add), label: const Text('Nuevo técnico')),
            if (canManage && module == 'inventario')
              FilledButton.icon(onPressed: () => _saveMaterial(), icon: const Icon(Icons.add_box_outlined), label: const Text('Nuevo material')),
            if (canManage && module == 'ordenes')
              FilledButton.icon(onPressed: () => _saveOrder(), icon: const Icon(Icons.add_task), label: const Text('Nueva orden')),
          ],
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No hay registros para mostrar.'))),
        for (final row in items)
          if (const {'ordenes', 'garantias', 'historial'}.contains(module)) _orderTile(row) else _recordTile(row),
      ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        leading: CircleAvatar(child: Icon(modules[module]!.icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showRecord(row),
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> row) {
    final colors = Theme.of(context).colorScheme;
    final stage = '${row['etapa'] ?? 'cita'}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openOrder(row),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            children: [
              CircleAvatar(child: Icon(_stageIcon(stage))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_text(row['codigo'], 'Orden')} · ${_text(row['cliente_nombre'], 'Cliente')}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${_stage(stage)} · ${_text(row['equipo_tipo'], 'Sin equipo')} · ${_text(row['tecnico_nombre'], 'Sin técnico')}', style: TextStyle(color: colors.onSurfaceVariant)),
                    if (hasPayments)
                      Text('Total ${_money(row['total'])} Bs · Saldo ${_money(row['saldo'])} Bs', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
              Chip(label: Text(_stage(stage))),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String title, String subtitle, {List<Widget> actions = const []}) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }

  Widget _stat(String label, dynamic value, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(child: Icon(icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${value ?? 0}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                      Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
