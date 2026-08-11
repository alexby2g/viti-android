import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../data/viti_repository.dart';

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
  static const _modules = <_Module>[
    _Module('inicio', 'Inicio', Icons.dashboard_outlined),
    _Module('clientes', 'Clientes', Icons.people_outline),
    _Module('equipos', 'Equipos', Icons.computer_outlined),
    _Module('ordenes', 'Órdenes', Icons.assignment_outlined),
    _Module('pagos', 'Pagos', Icons.payments_outlined),
    _Module('garantias', 'Garantías', Icons.verified_outlined),
    _Module('historial', 'Historial', Icons.history),
  ];

  String module = 'inicio';
  bool loading = true;
  String? error;
  dynamic data;

  bool get isTechnical => widget.appKey == 'servicio-tecnico';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
                Text(widget.appName, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  isTechnical ? 'Servicio Técnico VITI' : 'Electrofrío VITI',
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
            actions: [
              IconButton(onPressed: loading ? null : _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh)),
              const SizedBox(width: 6),
            ],
          ),
          drawer: desktop ? null : Drawer(child: _menu(closeDrawer: true)),
          body: desktop
              ? Row(
                  children: [
                    SizedBox(width: 225, child: _menu()),
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('VITI APP', style: TextStyle(fontSize: 11, letterSpacing: 1.7, color: Colors.white54, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(widget.appName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ]),
          ),
          for (final item in _modules)
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
          FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
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
            if (isTechnical) FilledButton.icon(onPressed: _newOrder, icon: const Icon(Icons.add), label: const Text('Nueva orden')),
            if (isTechnical) OutlinedButton.icon(onPressed: _newClient, icon: const Icon(Icons.person_add_alt_1), label: const Text('Nuevo cliente')),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _stat('Clientes', summary['clientes'], Icons.people_outline, () => _select('clientes')),
          _stat('Equipos', summary['equipos'], Icons.computer_outlined, () => _select('equipos')),
          if (summary.containsKey('tecnicos')) _stat('Técnicos', summary['tecnicos'], Icons.engineering_outlined, null),
          _stat('Órdenes abiertas', summary['ordenes_abiertas'], Icons.assignment_outlined, () => _select('ordenes')),
          _stat('Esperando aprobación', summary['esperando_aprobacion'], Icons.hourglass_bottom, () => _select('ordenes')),
          _stat('Listos para entregar', summary['listos_entrega'], Icons.inventory_2_outlined, () => _select('ordenes')),
          _stat('Por cobrar', '${summary['por_cobrar'] ?? 0} Bs', Icons.payments_outlined, () => _select('pagos')),
        ]),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Agenda de hoy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if (agenda.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Text('No hay trabajos programados para hoy.', style: TextStyle(color: Colors.white60))),
              for (final row in agenda) _orderTile(row),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _records(List<Map<String, dynamic>> items) {
    final current = _modules.firstWhere((item) => item.key == module);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _header(
          current.label,
          '${items.length} registro${items.length == 1 ? '' : 's'} cargados.',
          actions: [
            if (isTechnical && module == 'clientes') FilledButton.icon(onPressed: _newClient, icon: const Icon(Icons.person_add_alt_1), label: const Text('Nuevo cliente')),
            if (isTechnical && module == 'ordenes') FilledButton.icon(onPressed: _newOrder, icon: const Icon(Icons.add), label: const Text('Nueva orden')),
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
      'pagos' => '${row['monto'] ?? 0} Bs · ${_pretty(row['metodo'])}',
      _ => _text(row['nombre'], _text(row['codigo'], 'Registro')),
    };
    final subtitle = switch (module) {
      'clientes' => '${_text(row['telefono'], 'Sin teléfono')} · ${row['activo'] == false ? 'Inactivo' : 'Activo'}',
      'equipos' => '${_text(row['cliente_nombre'], 'Sin cliente')} · Serie ${_text(row['serie'], 'N/D')}',
      'pagos' => '${_text(row['codigo'], _text(row['orden_codigo'], 'Pago'))} · ${_text(row['cliente_nombre'], '')}',
      _ => _pretty(row['estado']),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        leading: CircleAvatar(child: Icon(_modules.firstWhere((item) => item.key == module).icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showDetails(row),
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        leading: const CircleAvatar(child: Icon(Icons.assignment_outlined)),
        title: Text('${_text(row['codigo'], 'Orden')} · ${_text(row['cliente_nombre'], 'Cliente')}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${_pretty(row['estado'])} · ${_text(row['equipo_tipo'], 'Sin equipo')}${row['saldo'] != null ? ' · Saldo ${row['saldo']} Bs' : ''}'),
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
            Text(subtitle, style: const TextStyle(color: Colors.white60)),
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
                  Text(label, style: const TextStyle(color: Colors.white60)),
                ])),
              ]),
            ),
          ),
        ),
      );

  Future<void> _showDetails(Map<String, dynamic> row) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_text(row['nombre'], _text(row['codigo'], 'Detalle'))),
        content: SizedBox(width: 560, child: SingleChildScrollView(child: _detailFields(row))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  Future<void> _showOrder(Map<String, dynamic> row) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_text(row['codigo'], 'Orden')} · ${_text(row['cliente_nombre'], 'Cliente')}'),
        content: SizedBox(width: 650, child: SingleChildScrollView(child: _detailFields(row))),
        actions: [
          if (isTechnical && _number(row['saldo']) > 0)
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
    const keys = ['estado', 'prioridad', 'cliente_nombre', 'cliente_telefono', 'equipo_tipo', 'equipo_marca', 'equipo_modelo', 'tecnico_nombre', 'problema_reportado', 'diagnostico', 'propuesta', 'trabajo_realizado', 'recomendaciones', 'total', 'pagado', 'saldo', 'garantia_fin', 'telefono', 'whatsapp', 'direccion', 'observaciones'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final key in keys)
        if (row[key] != null && '${row[key]}'.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_pretty(key), style: const TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              SelectableText('${row[key]}'),
            ]),
          ),
    ]);
  }

  Future<void> _newClient() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final whatsapp = TextEditingController();
    final address = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo cliente'),
        content: SizedBox(width: 520, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: phone, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: whatsapp, decoration: const InputDecoration(labelText: 'WhatsApp', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: address, decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder())),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              try {
                await widget.repository.createTechnicalClient(name: name.text, phone: phone.text, whatsapp: whatsapp.text, address: address.text);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                module = 'clientes';
                await _load();
              } on ApiException catch (exception) {
                if (dialogContext.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
    whatsapp.dispose();
    address.dispose();
  }

  Future<void> _newOrder() async {
    final clients = await widget.repository.businessAppList('servicio-tecnico', 'clientes');
    if (!mounted) return;
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero registra un cliente.')));
      return;
    }
    final equipment = await widget.repository.businessAppList('servicio-tecnico', 'equipos');
    final technicians = await widget.repository.businessAppList('servicio-tecnico', 'tecnicos');
    if (!mounted) return;
    var clientId = _int(clients.first['id']);
    int? equipmentId;
    int? technicianId;
    var priority = 'normal';
    final problem = TextEditingController();
    final cost = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final clientEquipment = equipment.where((item) => _int(item['cliente_id']) == clientId).toList();
          return AlertDialog(
            title: const Text('Nueva orden de servicio'),
            content: SizedBox(width: 600, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                initialValue: clientId,
                decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
                items: [for (final item in clients) DropdownMenuItem(value: _int(item['id']), child: Text(_text(item['nombre'], 'Cliente')))],
                onChanged: (value) => setDialogState(() {
                  clientId = value ?? clientId;
                  equipmentId = null;
                }),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                initialValue: equipmentId,
                decoration: const InputDecoration(labelText: 'Equipo', border: OutlineInputBorder()),
                items: [const DropdownMenuItem<int?>(value: null, child: Text('Sin equipo asociado')), for (final item in clientEquipment) DropdownMenuItem<int?>(value: _int(item['id']), child: Text('${_text(item['tipo'], 'Equipo')} ${_text(item['marca'], '')} ${_text(item['modelo'], '')}'))],
                onChanged: (value) => setDialogState(() => equipmentId = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                initialValue: technicianId,
                decoration: const InputDecoration(labelText: 'Técnico', border: OutlineInputBorder()),
                items: [const DropdownMenuItem<int?>(value: null, child: Text('Sin técnico')), for (final item in technicians) DropdownMenuItem<int?>(value: _int(item['id']), child: Text(_text(item['nombre'], 'Técnico')))],
                onChanged: (value) => setDialogState(() => technicianId = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Prioridad', border: OutlineInputBorder()),
                items: const [DropdownMenuItem(value: 'baja', child: Text('Baja')), DropdownMenuItem(value: 'normal', child: Text('Normal')), DropdownMenuItem(value: 'alta', child: Text('Alta')), DropdownMenuItem(value: 'urgente', child: Text('Urgente'))],
                onChanged: (value) => setDialogState(() => priority = value ?? priority),
              ),
              const SizedBox(height: 10),
              TextField(controller: problem, maxLines: 4, decoration: const InputDecoration(labelText: 'Problema reportado *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Costo inicial', suffixText: 'Bs', border: OutlineInputBorder())),
            ]))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              FilledButton.icon(
                onPressed: () async {
                  if (problem.text.trim().isEmpty) return;
                  final now = DateTime.now();
                  final date = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                  try {
                    await widget.repository.createTechnicalOrder(
                      clientId: clientId,
                      equipmentId: equipmentId,
                      technicianId: technicianId,
                      receptionDate: date,
                      priority: priority,
                      reportedProblem: problem.text,
                      serviceCost: double.tryParse(cost.text.replaceAll(',', '.')),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    module = 'ordenes';
                    await _load();
                  } on ApiException catch (exception) {
                    if (dialogContext.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
                  }
                },
                icon: const Icon(Icons.add_task),
                label: const Text('Crear orden'),
              ),
            ],
          );
        },
      ),
    );
    problem.dispose();
    cost.dispose();
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
              items: const [DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')), DropdownMenuItem(value: 'qr', child: Text('QR')), DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')), DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')), DropdownMenuItem(value: 'otro', child: Text('Otro'))],
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
                  if (dialogContext.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
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
double _number(dynamic value) => double.tryParse('${value ?? 0}') ?? 0;
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
String _pretty(dynamic value) => _text(value, 'Sin estado').replaceAll('_', ' ');
