import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/ui/viti_ui.dart';

Future<Map<String, dynamic>?> showDiagnosisProposalForm(
  BuildContext context, {
  required Map<String, dynamic> order,
  required bool showFinancial,
}) async {
  final diagnosis = TextEditingController(text: '${order['diagnostico'] ?? ''}');
  final proposal = TextEditingController(text: '${order['propuesta'] ?? ''}');
  final cost = TextEditingController(text: order['costo_servicio'] == null ? '' : '${order['costo_servicio']}');
  final discount = TextEditingController(text: order['descuento'] == null ? '0' : '${order['descuento']}');

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      title: _DialogHeader(
        icon: Icons.fact_check_outlined,
        title: 'Diagnóstico y propuesta',
        subtitle: 'Documenta la falla encontrada y la solución que se presentará al cliente.',
        tone: VitiTone.primary,
      ),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VitiPanel(
                child: Column(
                  children: [
                    TextField(
                      controller: diagnosis,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Diagnóstico técnico *',
                        hintText: 'Falla encontrada, pruebas realizadas y causa probable.',
                        prefixIcon: Icon(Icons.search_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: proposal,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Propuesta al cliente *',
                        hintText: 'Solución, alcance del trabajo y qué se realizará si autoriza.',
                        prefixIcon: Icon(Icons.handshake_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              if (showFinancial) ...[
                const SizedBox(height: 12),
                VitiPanel(
                  tone: VitiTone.info,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 520;
                      final fields = [
                        Expanded(
                          child: TextField(
                            controller: cost,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Costo del servicio', suffixText: 'Bs', prefixIcon: Icon(Icons.request_quote_outlined)),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: discount,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Descuento', suffixText: 'Bs', prefixIcon: Icon(Icons.percent_outlined)),
                          ),
                        ),
                      ];
                      if (compact) {
                        return Column(children: [fields[0], const SizedBox(height: 12), fields[1]]);
                      }
                      return Row(children: [fields[0], const SizedBox(width: 12), fields[1]]);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: () {
            if (diagnosis.text.trim().isEmpty || proposal.text.trim().isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Completa diagnóstico y propuesta.')));
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

Future<Map<String, dynamic>?> showClientDecisionForm(BuildContext context, {required Map<String, dynamic> order}) async {
  var decision = '${order['decision_cliente'] ?? 'pendiente'}';
  if (!const {'aceptado', 'rechazado'}.contains(decision)) decision = 'aceptado';
  final reason = TextEditingController(text: '${order['motivo_rechazo'] ?? ''}');

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
        title: const _DialogHeader(
          icon: Icons.how_to_reg_outlined,
          title: 'Decisión del cliente',
          subtitle: 'Registra la autorización o el rechazo de la propuesta técnica.',
          tone: VitiTone.warning,
        ),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VitiPanel(
                selected: true,
                tone: decision == 'aceptado' ? VitiTone.success : VitiTone.danger,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'aceptado', icon: Icon(Icons.check_circle_outline), label: Text('Acepta propuesta')),
                        ButtonSegment(value: 'rechazado', icon: Icon(Icons.cancel_outlined), label: Text('Rechaza propuesta')),
                      ],
                      selected: <String>{decision},
                      onSelectionChanged: (value) => setDialogState(() => decision = value.first),
                    ),
                    const SizedBox(height: 12),
                    VitiStatusBadge(
                      decision == 'aceptado' ? 'La orden pasará a reparación' : 'La orden se cerrará sin reparación',
                      tone: decision == 'aceptado' ? VitiTone.success : VitiTone.danger,
                      icon: decision == 'aceptado' ? Icons.build_outlined : Icons.block_outlined,
                    ),
                    if (decision == 'rechazado') ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: reason,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(labelText: 'Motivo del rechazo *', prefixIcon: Icon(Icons.notes_outlined)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () {
              if (decision == 'rechazado' && reason.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Registra el motivo del rechazo.')));
                return;
              }
              Navigator.pop(dialogContext, <String, dynamic>{'decision': decision, 'motivo_rechazo': reason.text.trim()});
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Registrar decisión'),
          ),
        ],
      ),
    ),
  );
  reason.dispose();
  return result;
}

Future<Map<String, dynamic>?> showRepairCompletionForm(BuildContext context, {required Map<String, dynamic> order}) async {
  final work = TextEditingController(text: '${order['trabajo_realizado'] ?? ''}');
  final recommendations = TextEditingController(text: '${order['recomendaciones'] ?? ''}');
  final warrantyDays = TextEditingController(text: '${order['garantia_dias'] ?? 0}');
  final warrantyTerms = TextEditingController(text: '${order['condiciones_garantia'] ?? ''}');

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      title: const _DialogHeader(
        icon: Icons.build_circle_outlined,
        title: 'Trabajo realizado y garantía',
        subtitle: 'Cierra la reparación técnica y deja documentada la cobertura ofrecida.',
        tone: VitiTone.success,
      ),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VitiPanel(
                child: Column(
                  children: [
                    TextField(
                      controller: work,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(labelText: 'Trabajo realizado *', prefixIcon: Icon(Icons.home_repair_service_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: recommendations,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Recomendaciones', prefixIcon: Icon(Icons.tips_and_updates_outlined)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              VitiPanel(
                tone: VitiTone.success,
                child: Column(
                  children: [
                    TextField(
                      controller: warrantyDays,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Días de garantía', suffixText: 'días', prefixIcon: Icon(Icons.verified_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: warrantyTerms,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Condiciones de garantía', prefixIcon: Icon(Icons.description_outlined)),
                    ),
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
            if (work.text.trim().isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Describe el trabajo realizado.')));
              return;
            }
            Navigator.pop(dialogContext, <String, dynamic>{
              'trabajo_realizado': work.text.trim(),
              'recomendaciones': recommendations.text.trim(),
              'garantia_dias': int.tryParse(warrantyDays.text.trim()) ?? 0,
              'condiciones_garantia': warrantyTerms.text.trim(),
            });
          },
          icon: const Icon(Icons.science_outlined),
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

Future<Map<String, dynamic>?> showEvidenceForm(BuildContext context, {required String defaultStage}) async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    allowMultiple: false,
    withData: false,
  );
  if (!context.mounted || picked == null || picked.files.isEmpty || picked.files.first.path == null) return null;

  final file = picked.files.first;
  var stage = const {'recepcion', 'diagnostico', 'reparacion', 'pruebas', 'entrega'}.contains(defaultStage) ? defaultStage : 'recepcion';
  final description = TextEditingController();

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
        title: const _DialogHeader(
          icon: Icons.add_a_photo_outlined,
          title: 'Agregar evidencia',
          subtitle: 'Relaciona la fotografía con la etapa correcta de la orden.',
          tone: VitiTone.info,
        ),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VitiPanel(
                tone: VitiTone.info,
                child: Row(
                  children: [
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: vitiToneColor(context, VitiTone.info).withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.image_outlined, color: vitiToneColor(context, VitiTone.info))),
                    const SizedBox(width: 11),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('${(file.size / 1024).toStringAsFixed(1)} KB', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant))])),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: stage,
                decoration: const InputDecoration(labelText: 'Etapa', prefixIcon: Icon(Icons.route_outlined)),
                items: const [
                  DropdownMenuItem(value: 'recepcion', child: Text('Recepción')),
                  DropdownMenuItem(value: 'diagnostico', child: Text('Diagnóstico')),
                  DropdownMenuItem(value: 'reparacion', child: Text('Reparación')),
                  DropdownMenuItem(value: 'pruebas', child: Text('Pruebas')),
                  DropdownMenuItem(value: 'entrega', child: Text('Entrega')),
                ],
                onChanged: (value) => setDialogState(() => stage = value ?? stage),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descripción', prefixIcon: Icon(Icons.notes_outlined)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
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

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.icon, required this.title, required this.subtitle, required this.tone});

  final IconData icon;
  final String title;
  final String subtitle;
  final VitiTone tone;

  @override
  Widget build(BuildContext context) {
    final color = vitiToneColor(context, tone);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 21)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.3))])),
      ],
    );
  }
}

double? _double(String value) {
  final text = value.trim().replaceAll(',', '.');
  return text.isEmpty ? null : double.tryParse(text);
}
