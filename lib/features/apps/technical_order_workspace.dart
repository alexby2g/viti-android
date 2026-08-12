import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/ui/viti_ui.dart';
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
          padding: const EdgeInsets.fromLTRB(22, 16, 12, 14),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: colors.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)),
                child: Icon(_stateIcon(state), color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text('${_text(order['codigo'], 'Orden')} · ${_text(order['cliente_nombre'], 'Cliente')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
                        const SizedBox(width: 8),
                        VitiStatusBadge(_stateLabel(state), tone: _stateTone(state), icon: _stateIcon(state)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(_equipmentLabel(order), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              IconButton(onPressed: busy ? null : () => Navigator.of(context).pop(), tooltip: 'Cerrar', icon: const Icon(Icons.close)),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final details = Column(
                children: [
                  _section(
                    title: 'Recepción y asignación',
                    subtitle: 'Datos base de ingreso y responsable técnico',
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
                    subtitle: 'Conclusión técnica y decisión del cliente',
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
                    subtitle: 'Ejecución final, recomendaciones y cobertura',
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
              );

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _workflowCard(),
                  const SizedBox(height: 14),
                  _summaryCards(),
                  const SizedBox(height: 14),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: details),
                        const SizedBox(width: 14),
                        SizedBox(width: 300, child: _actionsCard()),
                      ],
                    )
                  else ...[
                    _actionsCard(),
                    const SizedBox(height: 14),
                    details,
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _workflowCard() {
    final colors = Theme.of(context).colorScheme;
    final currentIndex = state == 'sin_reparacion' ? -1 : _states.indexOf(state);
    return VitiPanel(
      padding: const EdgeInsets.all(16),
      selected: !closed,
      tone: _stateTone(state),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: vitiToneColor(context, _stateTone(state)).withValues(alpha: .10), borderRadius: BorderRadius.circular(11)), child: Icon(Icons.route_outlined, size: 19, color: vitiToneColor(context, _stateTone(state)))),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Flujo de la orden', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Text('Seguimiento del servicio de principio a fin', style: TextStyle(fontSize: 11))])),
              VitiStatusBadge(state == 'sin_reparacion' ? 'Sin reparación' : _stateLabel(state), tone: _stateTone(state), icon: closed ? Icons.check_circle_outline : Icons.timelapse),
            ],
          ),
          const SizedBox(height: 16),
          if (state == 'sin_reparacion')
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: colors.error.withValues(alpha: .08), borderRadius: BorderRadius.circular(13), border: Border.all(color: colors.error.withValues(alpha: .20))),
              child: Row(children: [Icon(Icons.cancel_outlined, color: colors.error), const SizedBox(width: 10), const Expanded(child: Text('El cliente rechazó la propuesta. La orden quedó cerrada sin reparación.', style: TextStyle(fontWeight: FontWeight.w700)))]),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < _states.length; index++) ...[
                    _stepChip(_states[index], index < currentIndex, index == currentIndex),
                    if (index < _states.length - 1)
                      Container(width: 24, height: 2, color: index < currentIndex ? colors.primary : colors.outlineVariant),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepChip(String value, bool complete, bool current) {
    final colors = Theme.of(context).colorScheme;
    final tone = _stateTone(value);
    final toneColor = vitiToneColor(context, tone);
    final background = current ? toneColor.withValues(alpha: .12) : complete ? colors.primary.withValues(alpha: .07) : colors.surfaceContainerLow;
    final foreground = current ? toneColor : complete ? colors.primary : colors.onSurfaceVariant;
    return Container(
      width: 128,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: current ? toneColor.withValues(alpha: .45) : colors.outlineVariant.withValues(alpha: .75)),
      ),
      child: Row(
        children: [
          Icon(complete ? Icons.check_circle : current ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 17, color: foreground),
          const SizedBox(width: 7),
          Expanded(child: Text(_stateLabel(value), maxLines: 2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: foreground, height: 1.15))),
        ],
      ),
    );
  }

  Widget _actionsCard() {
    if (!widget.canManage) {
      return VitiPanel(
        tone: VitiTone.info,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VitiStatusBadge('Modo consulta', tone: VitiTone.info, icon: Icons.visibility_outlined),
            const SizedBox(height: 12),
            Text('El flujo y los datos se actualizan desde VITI. Tu acceso actual no permite modificar esta orden.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
          ],
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

    return VitiPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.bolt_outlined, size: 18, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(width: 9),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Acciones', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)), Text('Siguiente movimiento de la orden', style: TextStyle(fontSize: 10))])),
            ],
          ),
          const SizedBox(height: 14),
          for (final action in actions) ...[
            SizedBox(width: double.infinity, child: action),
            const SizedBox(height: 8),
          ],
          if (actions.isEmpty)
            Text('No hay acciones disponibles para el estado actual.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _summaryCards() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _miniStat('Estado', _stateLabel(state), _stateIcon(state), _stateTone(state)),
        _miniStat('Técnico', _text(order['tecnico_nombre'], 'Sin asignar'), Icons.engineering_outlined, VitiTone.info),
        _miniStat('Decisión', _decisionLabel(order), Icons.how_to_reg_outlined, _decisionTone(order)),
        if (widget.hasPayments) _miniStat('Total', '${_money(order['total'])} Bs', Icons.receipt_long_outlined, VitiTone.neutral),
        if (widget.hasPayments) _miniStat('Pagado', '${_money(order['pagado'])} Bs', Icons.check_circle_outline, VitiTone.success),
        if (widget.hasPayments) _miniStat('Saldo', '${_money(order['saldo'])} Bs', Icons.payments_outlined, _number(order['saldo']) > 0 ? VitiTone.warning : VitiTone.success),
      ],
    );
  }

  Widget _miniStat(String label, String value, IconData icon, VitiTone tone) {
    final color = vitiToneColor(context, tone);
    return SizedBox(
      width: 205,
      child: VitiPanel(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))])),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required String subtitle, required IconData icon, required List<Widget> children}) {
    return VitiPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .09), borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant))])),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 18, runSpacing: 16, children: children),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9, letterSpacing: .75, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35)),
        ],
      ),
    );
  }

  Widget _paymentsSection() {
    final payments = _list(order['pagos']);
    return VitiPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: vitiToneColor(context, VitiTone.success).withValues(alpha: .10), borderRadius: BorderRadius.circular(11)), child: Icon(Icons.payments_outlined, size: 19, color: vitiToneColor(context, VitiTone.success))),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Pagos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Text('Movimientos registrados en la orden', style: TextStyle(fontSize: 10))])),
              if (widget.canManage && _number(order['saldo']) > 0) TextButton.icon(onPressed: busy ? null : _registerPayment, icon: const Icon(Icons.add), label: const Text('Registrar')),
            ],
          ),
          const SizedBox(height: 12),
          if (payments.isEmpty)
            const VitiEmptyState(title: 'Sin pagos registrados', message: 'Los pagos aparecerán aquí cuando se registren.', icon: Icons.payments_outlined)
          else
            for (final payment in payments)
              VitiEntityRow(
                title: '${_money(payment['monto'])} Bs · ${_pretty(payment['metodo'])}',
                subtitle: '${_date(payment['pagado_at'])}${_text(payment['referencia'], '').isNotEmpty ? ' · ${payment['referencia']}' : ''}',
                icon: Icons.attach_money,
                badges: const [VitiStatusBadge('Registrado', tone: VitiTone.success)],
                onTap: () {},
                trailing: const Icon(Icons.check_circle_outline, size: 19),
              ),
        ],
      ),
    );
  }

  Widget _evidenceSection() {
    final evidence = _list(order['evidencias']);
    return VitiPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: vitiToneColor(context, VitiTone.info).withValues(alpha: .10), borderRadius: BorderRadius.circular(11)), child: Icon(Icons.photo_library_outlined, size: 19, color: vitiToneColor(context, VitiTone.info))),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Evidencias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Text('Fotografías y archivos del servicio', style: TextStyle(fontSize: 10))])),
              if (widget.canManage && !closed) TextButton.icon(onPressed: busy ? null : _addEvidence, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Agregar')),
            ],
          ),
          const SizedBox(height: 12),
          if (evidence.isEmpty)
            const VitiEmptyState(title: 'Sin evidencias', message: 'No hay fotografías asociadas a esta orden.', icon: Icons.photo_library_outlined)
          else
            for (final item in evidence)
              VitiEntityRow(
                title: _text(item['nombre_original'], 'Evidencia'),
                subtitle: '${_pretty(item['etapa'])}${_text(item['descripcion'], '').isNotEmpty ? ' · ${item['descripcion']}' : ''}',
                icon: Icons.image_outlined,
                badges: [VitiStatusBadge(_pretty(item['etapa']), tone: VitiTone.info)],
                onTap: () {},
                trailing: widget.canManage && !closed
                    ? IconButton(
                        tooltip: 'Eliminar evidencia',
                        onPressed: busy ? null : () => _deleteEvidence(_int(item['id'])),
                        icon: const Icon(Icons.delete_outline),
                      )
                    : const Icon(Icons.chevron_right, size: 19),
              ),
        ],
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

VitiTone _decisionTone(Map<String, dynamic> order) => switch ('${order['decision_cliente'] ?? 'pendiente'}') {
      'aceptado' => VitiTone.success,
      'rechazado' => VitiTone.danger,
      _ => VitiTone.warning,
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
