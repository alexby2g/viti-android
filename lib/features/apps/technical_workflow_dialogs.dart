import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> showDiagnosisProposalForm(
  BuildContext context, {
  required Map<String, dynamic> order,
  required bool showFinancial,
}) async {
  final diagnosis = TextEditingController(
    text: '${order['diagnostico'] ?? ''}',
  );
  final proposal = TextEditingController(text: '${order['propuesta'] ?? ''}');
  final cost = TextEditingController(
    text: order['costo_servicio'] == null ? '' : '${order['costo_servicio']}',
  );
  final discount = TextEditingController(
    text: order['descuento'] == null ? '0' : '${order['descuento']}',
  );

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Diagnóstico y propuesta'),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: diagnosis,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Diagnóstico técnico *',
                  hintText:
                      'Describe la falla encontrada, pruebas realizadas y causa probable.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: proposal,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Propuesta al cliente *',
                  hintText:
                      'Explica la solución, alcance del trabajo y qué se realizará si autoriza.',
                  border: OutlineInputBorder(),
                ),
              ),
              if (showFinancial) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cost,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Costo del servicio',
                          suffixText: 'Bs',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: discount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Descuento',
                          suffixText: 'Bs',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (diagnosis.text.trim().isEmpty || proposal.text.trim().isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('Completa diagnóstico y propuesta.'),
                ),
              );
              return;
            }
            Navigator.pop(dialogContext, <String, dynamic>{
              'diagnostico': diagnosis.text.trim(),
              'propuesta': proposal.text.trim(),
              if (showFinancial) 'costo_servicio': _double(cost.text),
              if (showFinancial) 'descuento': _double(discount.text) ?? 0,
            });
          },
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Guardar propuesta'),
        ),
      ],
    ),
  );

  diagnosis.dispose();
  proposal.dispose();
  cost.dispose();
  discount.dispose();
  return result;
}

Future<Map<String, dynamic>?> showClientDecisionForm(
  BuildContext context, {
  required Map<String, dynamic> order,
}) async {
  var decision = '${order['decision_cliente'] ?? 'pendiente'}';
  if (!const {'aceptado', 'rechazado'}.contains(decision)) {
    decision = 'aceptado';
  }
  final reason = TextEditingController(
    text: '${order['motivo_rechazo'] ?? ''}',
  );

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Decisión del cliente'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'aceptado',
                    icon: Icon(Icons.check_circle_outline),
                    label: Text('Acepta'),
                  ),
                  ButtonSegment(
                    value: 'rechazado',
                    icon: Icon(Icons.cancel_outlined),
                    label: Text('Rechaza'),
                  ),
                ],
                selected: <String>{decision},
                onSelectionChanged: (value) =>
                    setDialogState(() => decision = value.first),
              ),
              if (decision == 'rechazado') ...[
                const SizedBox(height: 14),
                TextField(
                  controller: reason,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del rechazo *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (decision == 'rechazado' && reason.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Registra el motivo del rechazo.'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, <String, dynamic>{
                'decision': decision,
                'motivo_rechazo': reason.text.trim(),
              });
            },
            child: const Text('Registrar decisión'),
          ),
        ],
      ),
    ),
  );
  reason.dispose();
  return result;
}

Future<Map<String, dynamic>?> showRepairCompletionForm(
  BuildContext context, {
  required Map<String, dynamic> order,
}) async {
  final work = TextEditingController(
    text: '${order['trabajo_realizado'] ?? ''}',
  );
  final recommendations = TextEditingController(
    text: '${order['recomendaciones'] ?? ''}',
  );
  final warrantyDays = TextEditingController(
    text: '${order['garantia_dias'] ?? 0}',
  );
  final warrantyTerms = TextEditingController(
    text: '${order['condiciones_garantia'] ?? ''}',
  );

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Trabajo realizado y garantía'),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: work,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Trabajo realizado *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: recommendations,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Recomendaciones',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: warrantyDays,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Días de garantía',
                  suffixText: 'días',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: warrantyTerms,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Condiciones de garantía',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (work.text.trim().isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Describe el trabajo realizado.')),
              );
              return;
            }
            Navigator.pop(dialogContext, <String, dynamic>{
              'trabajo_realizado': work.text.trim(),
              'recomendaciones': recommendations.text.trim(),
              'garantia_dias': int.tryParse(warrantyDays.text.trim()) ?? 0,
              'condiciones_garantia': warrantyTerms.text.trim(),
            });
          },
          icon: const Icon(Icons.build_circle_outlined),
          label: const Text('Pasar a pruebas'),
        ),
      ],
    ),
  );
  work.dispose();
  recommendations.dispose();
  warrantyDays.dispose();
  warrantyTerms.dispose();
  return result;
}

Future<Map<String, dynamic>?> showEvidenceForm(
  BuildContext context, {
  required String defaultStage,
}) async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
  );
  if (!context.mounted) return null;
  if (file == null || file.path == null) return null;
  var stage =
      const {
        'recepcion',
        'diagnostico',
        'reparacion',
        'pruebas',
        'entrega',
      }.contains(defaultStage)
      ? defaultStage
      : 'recepcion';
  final description = TextEditingController();

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Agregar evidencia'),
        content: SizedBox(
          width: 540,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.image_outlined)),
                title: Text(file.name),
                subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} KB'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: stage,
                decoration: const InputDecoration(
                  labelText: 'Etapa',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'recepcion',
                    child: Text('Recepción'),
                  ),
                  DropdownMenuItem(
                    value: 'diagnostico',
                    child: Text('Diagnóstico'),
                  ),
                  DropdownMenuItem(
                    value: 'reparacion',
                    child: Text('Reparación'),
                  ),
                  DropdownMenuItem(value: 'pruebas', child: Text('Pruebas')),
                  DropdownMenuItem(value: 'entrega', child: Text('Entrega')),
                ],
                onChanged: (value) =>
                    setDialogState(() => stage = value ?? stage),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, <String, dynamic>{
              'ruta': file.path!,
              'nombre': file.name,
              'etapa': stage,
              'descripcion': description.text.trim(),
            }),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Subir evidencia'),
          ),
        ],
      ),
    ),
  );
  description.dispose();
  return result;
}

double? _double(String value) {
  final text = value.trim().replaceAll(',', '.');
  return text.isEmpty ? null : double.tryParse(text);
}
