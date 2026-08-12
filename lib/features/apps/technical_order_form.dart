import 'package:flutter/material.dart';

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
          title: Text(initial == null ? 'Nueva orden de servicio' : 'Editar datos de la orden'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: technicianId,
                        decoration: _decoration('Técnico asignado', Icons.engineering_outlined),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Sin técnico asignado')),
                          for (final item in technicians)
                            DropdownMenuItem<int?>(value: _int(item['id']), child: Text(_text(item['nombre'], fallback: 'Técnico'))),
                        ],
                        onChanged: (value) => setDialogState(() => technicianId = value),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: receptionDate, decoration: _decoration('Fecha recepción *', Icons.event_available_outlined))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: scheduledDate, decoration: _decoration('Fecha programada', Icons.event_outlined))),
                    const SizedBox(width: 12),
                    SizedBox(width: 170, child: TextField(controller: scheduledTime, decoration: _decoration('Hora HH:mm', Icons.schedule_outlined))),
                  ]),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: problem,
                    minLines: 3,
                    maxLines: 5,
                    autofocus: initial == null,
                    decoration: _decoration('Problema reportado *', Icons.report_problem_outlined),
                  ),
                  if (showFinancial) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: cost,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _decoration('Costo del servicio', Icons.payments_outlined).copyWith(suffixText: 'Bs'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: discount,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _decoration('Descuento', Icons.discount_outlined).copyWith(suffixText: 'Bs'),
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Este formulario modifica únicamente datos básicos de recepción y asignación. Diagnóstico, propuesta y reparación se trabajarán en el siguiente bloque.'),
                        ),
                      ]),
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
                if (clientId <= 0 || receptionDate.text.trim().isEmpty || problem.text.trim().isEmpty) return;
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

InputDecoration _decoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
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

int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;

int? _nullableInt(dynamic value) {
  final parsed = int.tryParse('${value ?? ''}');
  return parsed != null && parsed > 0 ? parsed : null;
}

double? _nullableDouble(String value) {
  final text = value.trim().replaceAll(',', '.');
  return text.isEmpty ? null : double.tryParse(text);
}
