import 'package:flutter/material.dart';

import '../../core/ui/viti_ui.dart';

Future<Map<String, dynamic>?> showTechnicalClientForm(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) async {
  final name = TextEditingController(text: _text(initial?['nombre']));
  final phone = TextEditingController(text: _text(initial?['telefono']));
  final whatsapp = TextEditingController(text: _text(initial?['whatsapp']));
  final address = TextEditingController(text: _text(initial?['direccion']));
  final notes = TextEditingController(text: _text(initial?['observaciones']));
  var active = initial?['activo'] != false;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
        title: _FormHeader(
          icon: Icons.person_outline,
          title: initial == null ? 'Nuevo cliente' : 'Editar cliente',
          subtitle: 'Datos de contacto y referencia para el historial técnico.',
          tone: VitiTone.info,
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VitiPanel(
                  child: Column(
                    children: [
                      TextField(controller: name, autofocus: initial == null, decoration: _decoration('Nombre *', Icons.person_outline)),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 500;
                          final left = TextField(controller: phone, keyboardType: TextInputType.phone, decoration: _decoration('Teléfono', Icons.phone_outlined));
                          final right = TextField(controller: whatsapp, keyboardType: TextInputType.phone, decoration: _decoration('WhatsApp', Icons.chat_outlined));
                          if (compact) return Column(children: [left, const SizedBox(height: 12), right]);
                          return Row(children: [Expanded(child: left), const SizedBox(width: 12), Expanded(child: right)]);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: address, decoration: _decoration('Dirección', Icons.location_on_outlined)),
                      const SizedBox(height: 12),
                      TextField(controller: notes, minLines: 2, maxLines: 4, decoration: _decoration('Observaciones', Icons.notes_outlined)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                VitiPanel(
                  tone: active ? VitiTone.success : VitiTone.neutral,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: active,
                    onChanged: (value) => setDialogState(() => active = value),
                    secondary: Icon(active ? Icons.check_circle_outline : Icons.pause_circle_outline),
                    title: Text(active ? 'Cliente activo' : 'Cliente inactivo', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('Los clientes inactivos conservan todo su historial.'),
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
              if (name.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Registra el nombre del cliente.')));
                return;
              }
              Navigator.pop(dialogContext, <String, dynamic>{
                'nombre': name.text.trim(),
                'telefono': phone.text.trim(),
                'whatsapp': whatsapp.text.trim(),
                'direccion': address.text.trim(),
                'observaciones': notes.text.trim(),
                'activo': active,
              });
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar cliente'),
          ),
        ],
      ),
    ),
  );

  name.dispose();
  phone.dispose();
  whatsapp.dispose();
  address.dispose();
  notes.dispose();
  return result;
}

Future<Map<String, dynamic>?> showTechnicalEquipmentForm(
  BuildContext context, {
  required List<Map<String, dynamic>> clients,
  Map<String, dynamic>? initial,
}) async {
  if (clients.isEmpty) return null;

  final clientIds = clients.map((item) => _int(item['id'])).where((id) => id > 0).toSet();
  var clientId = _int(initial?['cliente_id']);
  if (!clientIds.contains(clientId)) clientId = _int(clients.first['id']);

  final type = TextEditingController(text: _text(initial?['tipo']));
  final brand = TextEditingController(text: _text(initial?['marca']));
  final model = TextEditingController(text: _text(initial?['modelo']));
  final serial = TextEditingController(text: _text(initial?['serie']));
  final specs = TextEditingController(text: _text(initial?['especificaciones']));
  final accessories = TextEditingController(text: _text(initial?['accesorios_recibidos']));
  final reception = TextEditingController(text: _text(initial?['estado_recepcion']));
  final notes = TextEditingController(text: _text(initial?['observaciones']));
  var active = initial?['activo'] != false;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
        title: _FormHeader(
          icon: Icons.computer_outlined,
          title: initial == null ? 'Nueva computadora / equipo' : 'Editar computadora / equipo',
          subtitle: 'Identificación, estado de recepción y accesorios asociados al cliente.',
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
                      DropdownButtonFormField<int>(
                        initialValue: clientId,
                        decoration: _decoration('Cliente *', Icons.person_outline),
                        items: [
                          for (final client in clients)
                            DropdownMenuItem(value: _int(client['id']), child: Text(_text(client['nombre'], fallback: 'Cliente'))),
                        ],
                        onChanged: (value) => setDialogState(() => clientId = value ?? clientId),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: type, autofocus: initial == null, decoration: _decoration('Tipo de equipo *', Icons.computer_outlined)),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 520;
                          final left = TextField(controller: brand, decoration: _decoration('Marca', Icons.sell_outlined));
                          final right = TextField(controller: model, decoration: _decoration('Modelo', Icons.memory_outlined));
                          if (compact) return Column(children: [left, const SizedBox(height: 12), right]);
                          return Row(children: [Expanded(child: left), const SizedBox(width: 12), Expanded(child: right)]);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: serial, decoration: _decoration('Serie / identificador', Icons.qr_code_outlined)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                VitiPanel(
                  tone: VitiTone.info,
                  child: Column(
                    children: [
                      TextField(controller: specs, minLines: 2, maxLines: 4, decoration: _decoration('Especificaciones', Icons.tune_outlined)),
                      const SizedBox(height: 12),
                      TextField(controller: accessories, minLines: 2, maxLines: 3, decoration: _decoration('Accesorios recibidos', Icons.inventory_2_outlined)),
                      const SizedBox(height: 12),
                      TextField(controller: reception, minLines: 2, maxLines: 3, decoration: _decoration('Estado al recibir', Icons.fact_check_outlined)),
                      const SizedBox(height: 12),
                      TextField(controller: notes, minLines: 2, maxLines: 4, decoration: _decoration('Observaciones', Icons.notes_outlined)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                VitiPanel(
                  tone: active ? VitiTone.success : VitiTone.neutral,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: active,
                    onChanged: (value) => setDialogState(() => active = value),
                    secondary: Icon(active ? Icons.check_circle_outline : Icons.pause_circle_outline),
                    title: Text(active ? 'Equipo activo' : 'Equipo inactivo', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('El historial técnico permanece aunque el equipo quede inactivo.'),
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
              if (clientId <= 0 || type.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Selecciona el cliente y registra el tipo de equipo.')));
                return;
              }
              Navigator.pop(dialogContext, <String, dynamic>{
                'cliente_id': clientId,
                'tipo': type.text.trim(),
                'marca': brand.text.trim(),
                'modelo': model.text.trim(),
                'serie': serial.text.trim(),
                'especificaciones': specs.text.trim(),
                'accesorios_recibidos': accessories.text.trim(),
                'estado_recepcion': reception.text.trim(),
                'observaciones': notes.text.trim(),
                'activo': active,
              });
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar equipo'),
          ),
        ],
      ),
    ),
  );

  type.dispose();
  brand.dispose();
  model.dispose();
  serial.dispose();
  specs.dispose();
  accessories.dispose();
  reception.dispose();
  notes.dispose();
  return result;
}

Future<Map<String, dynamic>?> showTechnicalTechnicianForm(
  BuildContext context, {
  required List<Map<String, dynamic>> businessUsers,
  Map<String, dynamic>? initial,
}) async {
  final availableUserIds = businessUsers.map((item) => _int(item['id'])).where((id) => id > 0).toSet();
  int? userId = _nullableInt(initial?['usuario_id']);
  if (userId != null && !availableUserIds.contains(userId)) userId = null;

  final name = TextEditingController(text: _text(initial?['nombre']));
  final phone = TextEditingController(text: _text(initial?['telefono']));
  final specialty = TextEditingController(text: _text(initial?['especialidad']));
  var active = initial?['activo'] != false;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
        title: _FormHeader(
          icon: Icons.engineering_outlined,
          title: initial == null ? 'Nuevo técnico' : 'Editar técnico',
          subtitle: 'Perfil operativo y vínculo opcional con una cuenta VITI del negocio.',
          tone: VitiTone.info,
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VitiPanel(
                  child: Column(
                    children: [
                      DropdownButtonFormField<int?>(
                        initialValue: userId,
                        decoration: _decoration('Cuenta VITI vinculada', Icons.badge_outlined),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Sin cuenta vinculada')),
                          for (final user in businessUsers)
                            DropdownMenuItem<int?>(
                              value: _int(user['id']),
                              child: Text('${_text(user['nombre'], fallback: 'Usuario')} ${_text(user['apellido'])}'.trim()),
                            ),
                        ],
                        onChanged: (value) => setDialogState(() => userId = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: name, autofocus: initial == null, decoration: _decoration('Nombre del técnico *', Icons.engineering_outlined)),
                      const SizedBox(height: 12),
                      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: _decoration('Teléfono', Icons.phone_outlined)),
                      const SizedBox(height: 12),
                      TextField(controller: specialty, decoration: _decoration('Especialidad', Icons.build_outlined)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                VitiPanel(
                  tone: active ? VitiTone.success : VitiTone.neutral,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: active,
                    onChanged: (value) => setDialogState(() => active = value),
                    secondary: Icon(active ? Icons.check_circle_outline : Icons.pause_circle_outline),
                    title: Text(active ? 'Técnico activo' : 'Técnico inactivo', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('El técnico inactivo conserva las órdenes y trabajos históricos.'),
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
              if (name.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Registra el nombre del técnico.')));
                return;
              }
              Navigator.pop(dialogContext, <String, dynamic>{
                'usuario_id': userId,
                'nombre': name.text.trim(),
                'telefono': phone.text.trim(),
                'especialidad': specialty.text.trim(),
                'activo': active,
              });
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar técnico'),
          ),
        ],
      ),
    ),
  );

  name.dispose();
  phone.dispose();
  specialty.dispose();
  return result;
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.icon, required this.title, required this.subtitle, required this.tone});

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

InputDecoration _decoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
    );

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;

int? _nullableInt(dynamic value) {
  final parsed = int.tryParse('${value ?? ''}');
  return parsed != null && parsed > 0 ? parsed : null;
}
