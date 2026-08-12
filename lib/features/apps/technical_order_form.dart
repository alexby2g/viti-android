import 'package:flutter/material.dart';

import '../../core/ui/viti_ui.dart';

Future<Map<String, dynamic>?> showTechnicalOrderForm(
  BuildContext context, {
  required List<Map<String, dynamic>> clients,
  required List<Map<String, dynamic>> equipment,
  required List<Map<String, dynamic>> technicians,
  required bool showFinancial,
  Map<String, dynamic>? initial,
}) async {
  if (clients.isEmpty) return null;

  final clientIds = clients.map((item) => _int(item['id'])).where((id) => id > 0).toSet();
  var clientId = _int(initial?['cliente_id']);
  if (!clientIds.contains(clientId)) clientId = _int(clients.first['id']);

  int? equipmentId = _nullableInt(initial?['equipo_id']);
  int? technicianId = _nullableInt(initial?['tecnico_id']);
  var priority = _text(initial?['prioridad'], fallback: 'normal');
  if (!const {'baja', 'normal', 'alta', 'urgente'}.contains(priority)) priority = 'normal';

  final now = DateTime.now();
  final defaultDate = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final receptionDate = TextEditingController(text: _text(initial?['fecha_recepcion'], fallback: defaultDate).split('T').first);
  final scheduledDate = TextEditingController(text: _text(initial?['fecha_programada']).split('T').first);
  final scheduledTime = TextEditingController(text: _timeText(initial?['hora_programada']));
  final problem = TextEditingController(text: _text(initial?['problema_reportado']));
  final cost = TextEditingController(text: showFinancial && initial?['costo_servicio'] != null ? '${initial!['costo_servicio']}' : '');
  final discount = TextEditingController(text: showFinancial && initial?['descuento'] != null ? '${initial!['descuento']}' : '');

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final clientEquipment = equipment.where((item) => _int(item['cliente_id']) == clientId).toList(growable: false);
        if (equipmentId != null && !clientEquipment.any((item) => _int(item['id']) == equipmentId)) equipmentId = null;
        if (technicianId != null && !technicians.any((item) => _int(item['id']) == technicianId)) technicianId = null;

        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
          title: _OrderFormHeader(
            editMode: initial != null,
            priority: priority,
          ),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VitiPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionCaption(icon: Icons.people_outline, title: 'Cliente y asignación', subtitle: 'Define quién solicita el servicio, el equipo y el responsable técnico.'),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          initialValue: clientId,
                          decoration: _decoration('Cliente *', Icons.person_outline),
                          items: [
                            for (final client in clients)
                              DropdownMenuItem(value: _int(client['id']), child: Text(_text(client['nombre'], fallback: 'Cliente'))),
                          ],
                          onChanged: (value) => setDialogState(() {
                            clientId = value ?? clientId;
                            equipmentId = null;
                          }),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 560;
                            final equipmentField = DropdownButtonFormField<int?>(
                              initialValue: equipmentId,
                              decoration: _decoration('Computadora / equipo', Icons.computer_outlined),
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text('Sin equipo asociado')),
                                for (final item in clientEquipment)
                                  DropdownMenuItem<int?>(
                                    value: _int(item['id']),
                                    child: Text('${_text(item['tipo'], fallback: 'Equipo')} ${_text(item['marca'])} ${_text(item['modelo'])}'.trim()),
                                  ),
                              ],
                              onChanged: (value) => setDialogState(() => equipmentId = value),
                            );
                            final technicianField = DropdownButtonFormField<int?>(
                              initialValue: technicianId,
                              decoration: _decoration('Técnico asignado', Icons.engineering_outlined),
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text('Sin técnico asignado')),
                                for (final item in technicians)
                                  DropdownMenuItem<int?>(value: _int(item['id']), child: Text(_text(item['nombre'], fallback: 'Técnico'))),
                              ],
                              onChanged: (value) => setDialogState(() => technicianId = value),
                            );
                            if (compact) return Column(children: [equipmentField, const SizedBox(height: 12), technicianField]);
                            return Row(children: [Expanded(child: equipmentField), const SizedBox(width: 12), Expanded(child: technicianField)]);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  VitiPanel(
                    tone: VitiTone.info,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionCaption(icon: Icons.event_outlined, title: 'Recepción y programación', subtitle: 'Fecha de ingreso, visita programada y prioridad operativa.'),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 600;
                            final reception = TextField(controller: receptionDate, decoration: _decoration('Fecha recepción *', Icons.event_available_outlined));
                            final scheduled = TextField(controller: scheduledDate, decoration: _decoration('Fecha programada', Icons.event_outlined));
                            final time = TextField(controller: scheduledTime, decoration: _decoration('Hora HH:mm', Icons.schedule_outlined));
                            if (compact) {
                              return Column(children: [reception, const SizedBox(height: 12), scheduled, const SizedBox(height: 12), time]);
                            }
                            return Row(children: [Expanded(child: reception), const SizedBox(width: 12), Expanded(child: scheduled), const SizedBox(width: 12), SizedBox(width: 170, child: time)]);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: priority,
                          decoration: _decoration('Prioridad *', Icons.flag_outlined),
                          items: const [
                            DropdownMenuItem(value: 'baja', child: Text('Baja')),
                            DropdownMenuItem(value: 'normal', child: Text('Normal')),
                            DropdownMenuItem(value: 'alta', child: Text('Alta')),
                            DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
                          ],
                          onChanged: (value) => setDialogState(() => priority = value ?? priority),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  VitiPanel(
                    tone: VitiTone.warning,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionCaption(icon: Icons.report_problem_outlined, title: 'Problema reportado', subtitle: 'Describe el síntoma inicial sin mezclarlo todavía con el diagnóstico técnico.'),
                        const SizedBox(height: 14),
                        TextField(
                          controller: problem,
                          minLines: 3,
                          maxLines: 5,
                          autofocus: initial == null,
                          decoration: _decoration('Problema reportado *', Icons.report_problem_outlined),
                        ),
                      ],
                    ),
                  ),
                  if (showFinancial) ...[
                    const SizedBox(height: 12),
                    VitiPanel(
                      tone: VitiTone.success,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SectionCaption(icon: Icons.payments_outlined, title: 'Datos financieros iniciales', subtitle: 'Estos importes pueden ajustarse después durante diagnóstico y propuesta.'),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 500;
                              final costField = TextField(
                                controller: cost,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _decoration('Costo del servicio', Icons.payments_outlined).copyWith(suffixText: 'Bs'),
                              );
                              final discountField = TextField(
                                controller: discount,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _decoration('Descuento', Icons.discount_outlined).copyWith(suffixText: 'Bs'),
                              );
                              if (compact) return Column(children: [costField, const SizedBox(height: 12), discountField]);
                              return Row(children: [Expanded(child: costField), const SizedBox(width: 12), Expanded(child: discountField)]);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  VitiPanel(
                    tone: VitiTone.info,
                    selected: true,
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 10),
                        Expanded(child: Text('Este formulario solo modifica recepción y asignación. Diagnóstico, propuesta, decisión, reparación, pruebas y entrega se trabajan dentro del workspace de la orden.', style: TextStyle(height: 1.4))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton.icon(
              onPressed: () {
                if (clientId <= 0 || receptionDate.text.trim().isEmpty || problem.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Completa cliente, fecha de recepción y problema reportado.')));
                  return;
                }
                Navigator.pop(dialogContext, <String, dynamic>{
                  'cliente_id': clientId,
                  'equipo_id': equipmentId,
                  'tecnico_id': technicianId,
                  'fecha_recepcion': receptionDate.text.trim(),
                  'fecha_programada': scheduledDate.text.trim(),
                  'hora_programada': scheduledTime.text.trim(),
                  'prioridad': priority,
                  'problema_reportado': problem.text.trim(),
                  if (showFinancial) 'costo_servicio': _nullableDouble(cost.text),
                  if (showFinancial) 'descuento': _nullableDouble(discount.text),
                });
              },
              icon: const Icon(Icons.save_outlined),
              label: Text(initial == null ? 'Crear orden' : 'Guardar cambios'),
            ),
          ],
        );
      },
    ),
  );

  receptionDate.dispose();
  scheduledDate.dispose();
  scheduledTime.dispose();
  problem.dispose();
  cost.dispose();
  discount.dispose();
  return result;
}

class _OrderFormHeader extends StatelessWidget {
  const _OrderFormHeader({required this.editMode, required this.priority});

  final bool editMode;
  final String priority;

  @override
  Widget build(BuildContext context) {
    final tone = _priorityTone(priority);
    final color = vitiToneColor(context, tone);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)), child: Icon(editMode ? Icons.edit_calendar_outlined : Icons.add_task, color: color, size: 21)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(editMode ? 'Editar datos de la orden' : 'Nueva orden de servicio', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(editMode ? 'Actualiza recepción, programación y asignación sin alterar el historial técnico.' : 'Registra el ingreso inicial y prepara la orden para su flujo técnico.', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.3)),
          const SizedBox(height: 8),
          VitiStatusBadge('Prioridad ${_priorityLabel(priority)}', tone: tone, icon: Icons.flag_outlined),
        ])),
      ],
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.3))])),
      ],
    );
  }
}

InputDecoration _decoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
    );

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _timeText(dynamic value) {
  final text = _text(value);
  if (text.length >= 5) return text.substring(0, 5);
  return text;
}

String _priorityLabel(String value) => switch (value) {
      'baja' => 'baja',
      'alta' => 'alta',
      'urgente' => 'urgente',
      _ => 'normal',
    };

VitiTone _priorityTone(String value) => switch (value) {
      'baja' => VitiTone.neutral,
      'alta' => VitiTone.warning,
      'urgente' => VitiTone.danger,
      _ => VitiTone.info,
    };

int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;

int? _nullableInt(dynamic value) {
  final parsed = int.tryParse('${value ?? ''}');
  return parsed != null && parsed > 0 ? parsed : null;
}

double? _nullableDouble(String value) {
  final text = value.trim().replaceAll(',', '.');
  return text.isEmpty ? null : double.tryParse(text);
}
