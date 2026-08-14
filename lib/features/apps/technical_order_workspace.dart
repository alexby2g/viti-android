import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../data/viti_repository.dart';
import 'technical_workflow_dialogs.dart';

class TechnicalOrderWorkspace extends StatefulWidget {
  const TechnicalOrderWorkspace({
    required this.repository,
    required this.initialOrder,
    required this.canManage,
    required this.hasPayments,
    required this.onEditReception,
    required this.onChanged,
    this.adminMode = false,
    this.companyId,
    super.key,
  });

  final VitiRepository repository;
  final Map<String, dynamic> initialOrder;
  final bool canManage;
  final bool hasPayments;
  final bool adminMode;
  final int? companyId;
  final ValueChanged<Map<String, dynamic>> onEditReception;
  final VoidCallback onChanged;

  @override
  State<TechnicalOrderWorkspace> createState() => _TechnicalOrderWorkspaceState();
}

class _TechnicalOrderWorkspaceState extends State<TechnicalOrderWorkspace> {
  static const _states = <String>[
    'recibido',
    'diagnostico',
    'esperando_aprobacion',
    'reparacion',
    'pruebas',
    'listo_entrega',
    'entregado',
  ];

  late Map<String, dynamic> order;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    order = Map<String, dynamic>.from(widget.initialOrder);
  }

  String get state => '${order['estado'] ?? 'recibido'}';
  bool get closed => const {'entregado', 'sin_reparacion'}.contains(state);
  bool get accepted => '${order['decision_cliente']}' == 'aceptado';
  bool get decisionPending => !const {'aceptado', 'rechazado'}.contains('${order['decision_cliente']}');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 12, 16),
          decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: colors.primaryContainer, foregroundColor: colors.onPrimaryContainer, child: const Icon(Icons.assignment_outlined)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_text(order['codigo'], 'Orden')} · ${_text(order['cliente_nombre'], 'Cliente')}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('${_stateLabel(state)} · ${_equipmentLabel(order)}', style: TextStyle(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
              if (busy) const Padding(padding: EdgeInsets.only(right: 10), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              IconButton(onPressed: busy ? null : () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              _workflowCard(),
              const SizedBox(height: 16),
              _actionsCard(),
              const SizedBox(height: 16),
              _summaryCards(),
              const SizedBox(height: 16),
              _section(
                title: 'Recepción y asignación',
                icon: Icons.inbox_outlined,
                children: [
                  _field('Cliente', _text(order['cliente_nombre'], 'Sin cliente')),
                  _field('Teléfono', _text(order['cliente_telefono'], 'No registrado')),
                  _field('Computadora', _equipmentLabel(order)),
                  _field('Técnico', _text(order['tecnico_nombre'], 'Sin asignar')),
                  _field('Prioridad', _pretty(order['prioridad'])),
                  _field('Recepción', _date(order['fecha_recepcion'])),
                  _field('Visita programada', _scheduleLabel(order)),
                  _field('Problema reportado', _text(order['problema_reportado'], 'Sin detalle')),
                ],
              ),
              const SizedBox(height: 12),
              _section(
                title: 'Diagnóstico y propuesta',
                icon: Icons.fact_check_outlined,
                children: [
                  _field('Diagnóstico', _text(order['diagnostico'], 'Pendiente')),
                  _field('Propuesta', _text(order['propuesta'], 'Pendiente')),
                  _field('Decisión del cliente', _decisionLabel(order)),
                  if (_text(order['motivo_rechazo'], '').isNotEmpty) _field('Motivo de rechazo', _text(order['motivo_rechazo'], '')),
                ],
              ),
              const SizedBox(height: 12),
              _section(
                title: 'Trabajo, pruebas y garantía',
                icon: Icons.build_circle_outlined,
                children: [
                  _field('Trabajo realizado', _text(order['trabajo_realizado'], 'Pendiente')),
                  _field('Recomendaciones', _text(order['recomendaciones'], 'Sin recomendaciones')),
                  _field('Garantía', _warrantyLabel(order)),
                  if (_text(order['condiciones_garantia'], '').isNotEmpty) _field('Condiciones', _text(order['condiciones_garantia'], '')),
                ],
              ),
              if (widget.hasPayments) ...[
                const SizedBox(height: 12),
                _paymentsSection(),
              ],
              const SizedBox(height: 12),
              _evidenceSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _workflowCard() {
    final colors = Theme.of(context).colorScheme;
    final currentIndex = state == 'sin_reparacion' ? -1 : _states.indexOf(state);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Flujo de la orden', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                Chip(
                  avatar: Icon(closed ? Icons.check_circle_outline : Icons.timelapse, size: 17),
                  label: Text(state == 'sin_reparacion' ? 'Sin reparación' : _stateLabel(state)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (state == 'sin_reparacion')
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: colors.errorContainer, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [Icon(Icons.cancel_outlined, color: colors.onErrorContainer), const SizedBox(width: 10), Expanded(child: Text('El cliente rechazó la propuesta. La orden quedó cerrada sin reparación.', style: TextStyle(color: colors.onErrorContainer, fontWeight: FontWeight.w700)))]),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0; index < _states.length; index++) ...[
                      _stepChip(_states[index], index < currentIndex, index == currentIndex),
                      if (index < _states.length - 1) Container(width: 28, height: 2, color: index < currentIndex ? colors.primary : colors.outlineVariant),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stepChip(String value, bool complete, bool current) {
    final colors = Theme.of(context).colorScheme;
    final background = current ? colors.primaryContainer : complete ? colors.secondaryContainer : colors.surfaceContainer;
    final foreground = current ? colors.onPrimaryContainer : complete ? colors.onSecondaryContainer : colors.onSurfaceVariant;
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12), border: current ? Border.all(color: colors.primary) : null),
      child: Row(
        children: [
          Icon(complete ? Icons.check_circle : current ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18, color: foreground),
          const SizedBox(width: 7),
          Expanded(child: Text(_stateLabel(value), maxLines: 2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: foreground))),
        ],
      ),
    );
  }

  Widget _actionsCard() {
    if (!widget.canManage) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [const Icon(Icons.visibility_outlined), const SizedBox(width: 10), Expanded(child: Text('Tu acceso es de consulta. El flujo y los datos se actualizan en tiempo real desde VITI.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))]),
        ),
      );
    }

    final actions = <Widget>[
      OutlinedButton.icon(
        onPressed: busy || closed ? null : () => widget.onEditReception(order),
        icon: const Icon(Icons.edit_calendar_outlined),
        label: const Text('Editar recepción'),
      ),
      if (!closed)
        OutlinedButton.icon(
          onPressed: busy ? null : _addEvidence,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Agregar evidencia'),
        ),
      if (!closed && const {'recibido', 'diagnostico', 'esperando_aprobacion'}.contains(state))
        FilledButton.icon(
          onPressed: busy ? null : _diagnose,
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(_text(order['propuesta'], '').isEmpty ? 'Diagnosticar y proponer' : 'Editar diagnóstico'),
        ),
      if (!closed && _text(order['diagnostico'], '').isNotEmpty && _text(order['propuesta'], '').isNotEmpty && decisionPending)
        FilledButton.icon(
          onPressed: busy ? null : _recordDecision,
          icon: const Icon(Icons.how_to_reg_outlined),
          label: const Text('Registrar decisión'),
        ),
      if (!closed && accepted && state == 'reparacion')
        FilledButton.icon(
          onPressed: busy ? null : _finishRepair,
          icon: const Icon(Icons.build_circle_outlined),
          label: const Text('Registrar reparación'),
        ),
      if (!closed && accepted && state == 'pruebas')
        FilledButton.icon(
          onPressed: busy ? null : () => _advance('listo_entrega', 'Equipo marcado como listo para entregar.'),
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Marcar listo para entregar'),
        ),
      if (!closed && accepted && state == 'listo_entrega')
        FilledButton.icon(
          onPressed: busy ? null : () => _advance('entregado', 'Orden entregada y cerrada.'),
          icon: const Icon(Icons.task_alt),
          label: const Text('Confirmar entrega'),
        ),
      if (widget.hasPayments && _number(order['saldo']) > 0)
        OutlinedButton.icon(
          onPressed: busy ? null : _registerPayment,
          icon: const Icon(Icons.payments_outlined),
          label: Text('Registrar pago · ${_money(order['saldo'])} Bs'),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Acciones disponibles', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }

  Widget _summaryCards() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _miniStat('Estado', _stateLabel(state), Icons.flag_outlined),
        _miniStat('Técnico', _text(order['tecnico_nombre'], 'Sin asignar'), Icons.engineering_outlined),
        _miniStat('Decisión', _decisionLabel(order), Icons.how_to_reg_outlined),
        if (widget.hasPayments) _miniStat('Total', '${_money(order['total'])} Bs', Icons.receipt_long_outlined),
        if (widget.hasPayments) _miniStat('Pagado', '${_money(order['pagado'])} Bs', Icons.check_circle_outline),
        if (widget.hasPayments) _miniStat('Saldo', '${_money(order['saldo'])} Bs', Icons.payments_outlined),
      ],
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Container(
      width: 205,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(radius: 18, child: Icon(icon, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 3), Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))])),
        ],
      ),
    );
  }

  Widget _section({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon), const SizedBox(width: 9), Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))]),
            const SizedBox(height: 14),
            Wrap(spacing: 18, runSpacing: 14, children: children),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _paymentsSection() {
    final payments = _list(order['pagos']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.payments_outlined), const SizedBox(width: 9), const Expanded(child: Text('Pagos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))), if (widget.canManage && _number(order['saldo']) > 0) TextButton.icon(onPressed: busy ? null : _registerPayment, icon: const Icon(Icons.add), label: const Text('Registrar'))]),
            const SizedBox(height: 10),
            if (payments.isEmpty) Text('Aún no hay pagos registrados.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            for (final payment in payments)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.attach_money)),
                title: Text('${_money(payment['monto'])} Bs · ${_pretty(payment['metodo'])}'),
                subtitle: Text('${_date(payment['pagado_at'])}${_text(payment['referencia'], '').isNotEmpty ? ' · ${payment['referencia']}' : ''}'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _evidenceSection() {
    final evidence = _list(order['evidencias']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.photo_library_outlined), const SizedBox(width: 9), const Expanded(child: Text('Evidencias', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))), if (widget.canManage && !closed) TextButton.icon(onPressed: busy ? null : _addEvidence, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Agregar'))]),
            const SizedBox(height: 10),
            if (evidence.isEmpty) Text('No hay fotografías asociadas a esta orden.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            for (final item in evidence)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.image_outlined)),
                title: Text(_text(item['nombre_original'], 'Evidencia')),
                subtitle: Text('${_pretty(item['etapa'])}${_text(item['descripcion'], '').isNotEmpty ? ' · ${item['descripcion']}' : ''}'),
                trailing: widget.canManage && !closed
                    ? IconButton(
                        tooltip: 'Eliminar evidencia',
                        onPressed: busy ? null : () => _deleteEvidence(_int(item['id'])),
                        icon: const Icon(Icons.delete_outline),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _diagnose() async {
    final draft = await showDiagnosisProposalForm(context, order: order, showFinancial: widget.hasPayments);
    if (draft == null) return;
    await _run(() async {
      final updated = await widget.repository.updateTechnicalOrder(
        id: _int(order['id']),
        clientId: _int(order['cliente_id']),
        equipmentId: _nullableInt(order['equipo_id']),
        technicianId: _nullableInt(order['tecnico_id']),
        receptionDate: _isoDate(order['fecha_recepcion']),
        scheduledDate: _nullableText(order['fecha_programada']),
        scheduledTime: _time(order['hora_programada']),
        priority: _text(order['prioridad'], 'normal'),
        reportedProblem: _text(order['problema_reportado'], 'Sin detalle'),
        diagnosis: '${draft['diagnostico']}',
        proposal: '${draft['propuesta']}',
        workDone: _nullableText(order['trabajo_realizado']),
        recommendations: _nullableText(order['recomendaciones']),
        serviceCost: draft.containsKey('costo_servicio') ? _nullableDouble(draft['costo_servicio']) : _nullableDouble(order['costo_servicio']),
        discount: draft.containsKey('descuento') ? _nullableDouble(draft['descuento']) : _nullableDouble(order['descuento']),
        admin: widget.adminMode,
        companyId: widget.companyId,
      );
      order = updated;
    }, 'Diagnóstico y propuesta guardados.');
  }

  Future<void> _recordDecision() async {
    final draft = await showClientDecisionForm(context, order: order);
    if (draft == null) return;
    await _run(() async {
      order = await widget.repository.decideTechnicalOrder(
        orderId: _int(order['id']),
        decision: '${draft['decision']}',
        rejectionReason: '${draft['motivo_rechazo'] ?? ''}',
        admin: widget.adminMode,
        companyId: widget.companyId,
      );
    }, draft['decision'] == 'aceptado' ? 'Propuesta aceptada. La orden pasó a reparación.' : 'Propuesta rechazada. La orden quedó cerrada.');
  }

  Future<void> _finishRepair() async {
    final draft = await showRepairCompletionForm(context, order: order);
    if (draft == null) return;
    await _run(() async {
      order = await widget.repository.finishTechnicalWork(
        orderId: _int(order['id']),
        workDone: '${draft['trabajo_realizado']}',
        recommendations: '${draft['recomendaciones'] ?? ''}',
        warrantyDays: _int(draft['garantia_dias']),
        warrantyTerms: '${draft['condiciones_garantia'] ?? ''}',
        admin: widget.adminMode,
        companyId: widget.companyId,
      );
    }, 'Trabajo registrado. La orden pasó a pruebas.');
  }

  Future<void> _advance(String target, String success) async {
    await _run(() async {
      order = await widget.repository.changeTechnicalOrderState(
        orderId: _int(order['id']),
        state: target,
        admin: widget.adminMode,
        companyId: widget.companyId,
      );
    }, success);
  }

  Future<void> _registerPayment() async {
    final amount = TextEditingController();
    final reference = TextEditingController();
    var method = 'efectivo';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Registrar pago · ${_text(order['codigo'], 'Orden')}'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: amount, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Monto', suffixText: 'Bs', helperText: 'Saldo: ${_money(order['saldo'])} Bs', border: const OutlineInputBorder())),
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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(onPressed: () {
              final parsed = double.tryParse(amount.text.trim().replaceAll(',', '.'));
              if (parsed == null || parsed <= 0) return;
              Navigator.pop(dialogContext, <String, dynamic>{'monto': parsed, 'metodo': method, 'referencia': reference.text.trim()});
            }, child: const Text('Registrar')),
          ],
        ),
      ),
    );
    amount.dispose();
    reference.dispose();
    if (result == null) return;

    await _run(() async {
      await widget.repository.registerTechnicalPayment(
        orderId: _int(order['id']),
        amount: result['monto'] as double,
        method: '${result['metodo']}',
        reference: '${result['referencia']}',
        admin: widget.adminMode,
        companyId: widget.companyId,
      );
      await _reloadOrder();
    }, 'Pago registrado.');
  }

  Future<void> _addEvidence() async {
    final draft = await showEvidenceForm(context, defaultStage: _evidenceStage(state));
    if (draft == null) return;
    await _run(() async {
      await widget.repository.uploadTechnicalEvidence(
        orderId: _int(order['id']),
        stage: '${draft['etapa']}',
        filePath: '${draft['ruta']}',
        fileName: '${draft['nombre']}',
        description: '${draft['descripcion'] ?? ''}',
        admin: widget.adminMode,
        companyId: widget.companyId,
      );
      await _reloadOrder();
    }, 'Evidencia agregada.');
  }

  Future<void> _deleteEvidence(int evidenceId) async {
    if (evidenceId <= 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar evidencia'),
        content: const Text('Esta fotografía se quitará de la orden. Las evidencias de órdenes cerradas no se pueden eliminar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await widget.repository.deleteTechnicalEvidence(evidenceId, admin: widget.adminMode, companyId: widget.companyId);
      await _reloadOrder();
    }, 'Evidencia eliminada.');
  }

  Future<void> _reloadOrder() async {
    final orders = await widget.repository.businessAppList('servicio-tecnico', 'ordenes', admin: widget.adminMode, companyId: widget.companyId);
    final id = _int(order['id']);
    for (final item in orders) {
      if (_int(item['id']) == id) {
        order = Map<String, dynamic>.from(item);
        return;
      }
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      widget.onChanged();
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo completar la operación.')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

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

String _decisionLabel(Map<String, dynamic> order) => switch ('${order['decision_cliente'] ?? 'pendiente'}') {
      'aceptado' => 'Aceptada',
      'rechazado' => 'Rechazada',
      _ => 'Pendiente',
    };

String _equipmentLabel(Map<String, dynamic> order) {
  final parts = <String>[
    _text(order['equipo_tipo'], ''),
    _text(order['equipo_marca'], ''),
    _text(order['equipo_modelo'], ''),
  ].where((value) => value.isNotEmpty).toList();
  if (parts.isEmpty) return 'Sin computadora asociada';
  final serial = _text(order['equipo_serie'], '');
  return '${parts.join(' ')}${serial.isNotEmpty ? ' · S/N $serial' : ''}';
}

String _scheduleLabel(Map<String, dynamic> order) {
  final date = _nullableText(order['fecha_programada']);
  final time = _time(order['hora_programada']);
  if (date == null && time == null) return 'Sin programación';
  return '${date == null ? '' : _date(date)}${time == null ? '' : ' · $time'}';
}

String _warrantyLabel(Map<String, dynamic> order) {
  final days = _int(order['garantia_dias']);
  if (days <= 0) return 'Sin garantía registrada';
  return '$days días · ${_date(order['garantia_inicio'])} a ${_date(order['garantia_fin'])}';
}

String _evidenceStage(String state) => switch (state) {
      'diagnostico' || 'esperando_aprobacion' => 'diagnostico',
      'reparacion' => 'reparacion',
      'pruebas' || 'listo_entrega' => 'pruebas',
      'entregado' => 'entrega',
      _ => 'recepcion',
    };

List<Map<String, dynamic>> _list(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const [];
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
String? _nullableText(dynamic value) {
  final text = '${value ?? ''}'.trim();
  return text.isEmpty ? null : text;
}
String _isoDate(dynamic value) {
  final parsed = DateTime.tryParse('${value ?? ''}');
  if (parsed == null) return DateTime.now().toIso8601String().split('T').first;
  return parsed.toIso8601String().split('T').first;
}
String? _time(dynamic value) {
  final text = '${value ?? ''}'.trim();
  if (text.isEmpty) return null;
  return text.length >= 5 ? text.substring(0, 5) : text;
}
String _date(dynamic value) {
  final parsed = DateTime.tryParse('${value ?? ''}')?.toLocal();
  if (parsed == null) return 'No definida';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year}';
}
