import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../data/viti_repository.dart';
import 'technical_order_form.dart';
import 'technical_people_forms.dart';

class BusinessAppScreen extends StatefulWidget {
  const BusinessAppScreen({
    required this.repository,
    required this.appKey,
    required this.appName,
    super.key,
  });

  final VitiRepository repository;
  final String appKey;
  final String appName;

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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (isTechnical) {
      try {
        appState = await widget.repository.businessAppState(widget.appKey);
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
          ? await widget.repository.businessAppSummary(widget.appKey)
          : await widget.repository.businessAppList(widget.appKey, module);
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.appName, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  isTechnical ? 'Servicio Técnico VITI' : 'Electrofrío VITI',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              if (isTechnical)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Center(
                    child: Chip(
                      avatar: Icon(canManage ? Icons.edit_outlined : Icons.visibility_outlined, size: 17),
                      label: Text(canManage ? 'Administración' : 'Solo lectura'),
                    ),
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

  Widget _menu({bool closeDrawer = false}) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VITI APP', style: TextStyle(fontSize: 11, letterSpacing: 1.7, color: colors.onSurfaceVariant, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(widget.appName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              if (isTechnical && _map(appState['empresa']).isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(_text(_map(appState['empresa'])['nombre_comercial'], ''), style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
              ],
            ]),
          ),
          for (final item in visibleModules)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: ListTile(
                selected: module == item.key,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(item.icon),
                title: Text(item.label),
                onTap: () {
                  if (closeDrawer) Navigator.of(context).pop();
                  _select(item.key);
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 42),
          const SizedBox(height: 10),
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _initialize, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
        ]),
      );
    }
    if (module == 'inicio') return _summary(_map(data));
    return _records(_list(data));
  }

  Widget _summary(Map<String, dynamic> summary) {
    final agenda = _list(summary['agenda_hoy']);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _header(
          'Inicio',
          'Operación real de ${widget.appName}.',
          actions: [
            if (canManage) FilledButton.icon(onPressed: () => _saveOrder(), icon: const Icon(Icons.add), label: const Text('Nueva orden')),
            if (canManage) OutlinedButton.icon(onPressed: () => _saveClient(), icon: const Icon(Icons.person_add_alt_1), label: const Text('Nuevo cliente')),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _stat('Clientes', summary['clientes'], Icons.people_outline, () => _select('clientes')),
          _stat('Computadoras', summary['equipos'], Icons.computer_outlined, () => _select('equipos')),
          if (isTechnical && enabledModuleKeys.contains('tecnicos')) _stat('Técnicos', summary['tecnicos'], Icons.engineering_outlined, () => _select('tecnicos')),
          _stat('Órdenes abiertas', summary['ordenes_abiertas'], Icons.assignment_outlined, () => _select('ordenes')),
          if (summary.containsKey('esperando_aprobacion')) _stat('Esperando aprobación', summary['esperando_aprobacion'], Icons.hourglass_bottom, () => _select('ordenes')),
          if (summary.containsKey('listos_entrega')) _stat('Listos para entregar', summary['listos_entrega'], Icons.inventory_2_outlined, () => _select('ordenes')),
          if (hasPayments && summary.containsKey('por_cobrar')) _stat('Por cobrar', '${summary['por_cobrar'] ?? 0} Bs', Icons.payments_outlined, () => _select('pagos')),
        ]),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Agenda de hoy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if (agenda.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text('No hay trabajos programados para hoy.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
              for (final row in agenda) _orderTile(row),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _records(List<Map<String, dynamic>> items) {
    final current = visibleModules.firstWhere((item) => item.key == module, orElse: () => _allModules.first);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _header(
          current.label,
          '${items.length} registro${items.length == 1 ? '' : 's'} cargados.',
          actions: [
            if (canManage && module == 'clientes') FilledButton.icon(onPressed: () => _saveClient(), icon: const Icon(Icons.person_add_alt_1), label: const Text('Nuevo cliente')),
            if (canManage && module == 'equipos') FilledButton.icon(onPressed: () => _saveEquipment(), icon: const Icon(Icons.add_to_queue), label: const Text('Nueva computadora')),
            if (canManage && module == 'tecnicos') FilledButton.icon(onPressed: () => _saveTechnician(), icon: const Icon(Icons.person_add_alt), label: const Text('Nuevo técnico')),
            if (canManage && module == 'ordenes') FilledButton.icon(onPressed: () => _saveOrder(), icon: const Icon(Icons.add_task), label: const Text('Nueva orden')),
          ],
        ),
        const SizedBox(height: 18),
        if (items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No hay registros para mostrar.'))),
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
      'pagos' => '${row['monto'] ?? 0} Bs · ${_pretty(row['metodo'])}',
      _ => _text(row['nombre'], _text(row['codigo'], 'Registro')),
    };
    final subtitle = switch (module) {
      'clientes' => '${_text(row['telefono'], 'Sin teléfono')} · ${row['activo'] == false ? 'Inactivo' : 'Activo'}',
      'equipos' => '${_text(row['cliente_nombre'], 'Sin cliente')} · Serie ${_text(row['serie'], 'N/D')} · ${row['activo'] == false ? 'Inactiva' : 'Activa'}',
      'tecnicos' => '${_text(row['especialidad'], 'Sin especialidad')} · ${row['activo'] == false ? 'Inactivo' : 'Activo'}',
      'pagos' => '${_text(row['orden_codigo'], _text(row['codigo'], 'Pago'))} · ${_text(row['cliente_nombre'], '')}',
      _ => _pretty(row['estado']),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        leading: CircleAvatar(child: Icon(currentModuleIcon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showRecord(row),
      ),
    );
  }

  IconData get currentModuleIcon => _allModules.firstWhere((item) => item.key == module, orElse: () => _allModules.first).icon;

  Widget _orderTile(Map<String, dynamic> row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        leading: const CircleAvatar(child: Icon(Icons.assignment_outlined)),
        title: Text('${_text(row['codigo'], 'Orden')} · ${_text(row['cliente_nombre'], 'Cliente')}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${_pretty(row['estado'])} · ${_text(row['equipo_tipo'], 'Sin equipo')}${row['tecnico_nombre'] != null ? ' · ${row['tecnico_nombre']}' : ''}${row['saldo'] != null && hasPayments ? ' · Saldo ${row['saldo']} Bs' : ''}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showOrder(row),
      ),
    );
  }

  Widget _header(String title, String subtitle, {List<Widget> actions = const []}) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
          if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      );

  Widget _stat(String label, dynamic value, IconData icon, VoidCallback? onTap) => SizedBox(
        width: 220,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                CircleAvatar(child: Icon(icon)),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${value ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
              ]),
            ),
          ),
        ),
      );

  Future<void> _showRecord(Map<String, dynamic> row) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_text(row['nombre'], _text(row['codigo'], 'Detalle'))),
        content: SizedBox(width: 620, child: SingleChildScrollView(child: _detailFields(row))),
        actions: [
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
    final closed = const {'entregado', 'sin_reparacion'}.contains('${row['estado']}');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_text(row['codigo'], 'Orden')} · ${_text(row['cliente_nombre'], 'Cliente')}'),
        content: SizedBox(width: 700, child: SingleChildScrollView(child: _detailFields(row))),
        actions: [
          if (canManage && !closed)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _saveOrder(initial: row);
              },
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('Editar recepción'),
            ),
          if (isTechnical && hasPayments && _number(row['saldo']) > 0)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _registerPayment(row);
              },
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Registrar pago'),
            ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
        ],
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
        );
      } else {
        await widget.repository.updateTechnicalClient(
          id: _int(initial['id']), name: '${draft['nombre']}', phone: '${draft['telefono']}', whatsapp: '${draft['whatsapp']}',
          address: '${draft['direccion']}', notes: '${draft['observaciones']}', active: draft['activo'] == true,
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
        );
      } else {
        await widget.repository.updateTechnicalEquipment(
          id: _int(initial['id']), clientId: args.clientId, type: args.type, brand: args.brand, model: args.model, serial: args.serial,
          specifications: args.specifications, accessories: args.accessories, receptionState: args.receptionState, notes: args.notes, active: args.active,
        );
      }
      module = 'equipos';
      await _load();
    }, initial == null ? 'Computadora registrada.' : 'Computadora actualizada.');
  }

  Future<void> _saveTechnician({Map<String, dynamic>? initial}) async {
    List<Map<String, dynamic>> users = const [];
    try {
      users = await widget.repository.technicalBusinessUsers();
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
        );
      } else {
        await widget.repository.updateTechnicalTechnician(
          id: _int(initial['id']), userId: _nullableInt(draft['usuario_id']), name: '${draft['nombre']}', phone: '${draft['telefono']}',
          specialty: '${draft['especialidad']}', active: draft['activo'] == true,
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
        );
      } else {
        await widget.repository.updateTechnicalOrder(
          id: _int(initial['id']), clientId: _int(draft['cliente_id']), equipmentId: _nullableInt(draft['equipo_id']), technicianId: _nullableInt(draft['tecnico_id']),
          receptionDate: '${draft['fecha_recepcion']}', scheduledDate: '${draft['fecha_programada']}', scheduledTime: '${draft['hora_programada']}',
          priority: '${draft['prioridad']}', reportedProblem: '${draft['problema_reportado']}',
          diagnosis: initial['diagnostico']?.toString(), proposal: initial['propuesta']?.toString(), workDone: initial['trabajo_realizado']?.toString(),
          recommendations: initial['recomendaciones']?.toString(), serviceCost: serviceCost, discount: discount,
        );
      }
      module = 'ordenes';
      await _load();
    }, initial == null ? 'Orden creada.' : 'Datos de recepción actualizados.');
  }

  Future<List<Map<String, dynamic>>> _safeList(String resource) async {
    try {
      return await widget.repository.businessAppList('servicio-tecnico', resource);
    } on ApiException catch (exception) {
      if (mounted) _notice(exception.message);
      return const [];
    }
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

  Future<void> _registerPayment(Map<String, dynamic> order) async {
    final amount = TextEditingController();
    final reference = TextEditingController();
    var method = 'efectivo';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Registrar pago · ${_text(order['codigo'], 'Orden')}'),
          content: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Monto', suffixText: 'Bs', helperText: 'Saldo: ${order['saldo'] ?? 0} Bs', border: const OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: method,
              decoration: const InputDecoration(labelText: 'Método', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'qr', child: Text('QR')),
                DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                DropdownMenuItem(value: 'otro', child: Text('Otro')),
              ],
              onChanged: (value) => setDialogState(() => method = value ?? method),
            ),
            const SizedBox(height: 10),
            TextField(controller: reference, decoration: const InputDecoration(labelText: 'Referencia', border: OutlineInputBorder())),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final parsed = double.tryParse(amount.text.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) return;
                try {
                  await widget.repository.registerTechnicalPayment(orderId: _int(order['id']), amount: parsed, method: method, reference: reference.text);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  module = 'pagos';
                  await _load();
                } on ApiException catch (exception) {
                  if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(exception.message)));
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    reference.dispose();
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
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
String _pretty(dynamic value) => _text(value, 'Sin estado').replaceAll('_', ' ');
