import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> showElectroClientForm(BuildContext context, {Map<String, dynamic>? initial}) {
  final name = TextEditingController(text: '${initial?['nombre'] ?? ''}');
  final phone = TextEditingController(text: '${initial?['telefono'] ?? ''}');
  final address = TextEditingController(text: '${initial?['direccion'] ?? ''}');
  final reference = TextEditingController(text: '${initial?['referencia'] ?? ''}');
  final notes = TextEditingController(text: '${initial?['observaciones'] ?? ''}');
  var active = initial?['activo'] != false;
  return _formDialog(
    context,
    title: initial == null ? 'Nuevo cliente' : 'Editar cliente',
    builder: (dialogContext, setState) => [
      _field(name, 'Nombre *'),
      _field(phone, 'Teléfono'),
      _field(address, 'Dirección'),
      _field(reference, 'Referencia de ubicación'),
      _field(notes, 'Observaciones', lines: 3),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: active, onChanged: (value) => setState(() => active = value), title: const Text('Cliente activo')),
    ],
    validate: () => name.text.trim().isNotEmpty,
    result: () => <String, dynamic>{'nombre': name.text.trim(), 'telefono': phone.text.trim(), 'direccion': address.text.trim(), 'referencia': reference.text.trim(), 'observaciones': notes.text.trim(), 'activo': active},
  ).whenComplete(() { name.dispose(); phone.dispose(); address.dispose(); reference.dispose(); notes.dispose(); });
}

Future<Map<String, dynamic>?> showElectroEquipmentForm(BuildContext context, {required List<Map<String, dynamic>> clients, Map<String, dynamic>? initial}) {
  var clientId = _id(initial?['cliente_id']);
  if (!clients.any((row) => _id(row['id']) == clientId)) clientId = _id(clients.first['id']);
  final type = TextEditingController(text: '${initial?['tipo'] ?? ''}');
  final brand = TextEditingController(text: '${initial?['marca'] ?? ''}');
  final model = TextEditingController(text: '${initial?['modelo'] ?? ''}');
  final serial = TextEditingController(text: '${initial?['serie'] ?? ''}');
  final capacity = TextEditingController(text: '${initial?['capacidad'] ?? ''}');
  final location = TextEditingController(text: '${initial?['ubicacion'] ?? ''}');
  final notes = TextEditingController(text: '${initial?['observaciones'] ?? ''}');
  var active = initial?['activo'] != false;
  return _formDialog(
    context,
    title: initial == null ? 'Nuevo equipo' : 'Editar equipo',
    builder: (dialogContext, setState) => [
      DropdownButtonFormField<int>(initialValue: clientId, decoration: const InputDecoration(labelText: 'Cliente *', border: OutlineInputBorder()), items: [for (final row in clients) DropdownMenuItem(value: _id(row['id']), child: Text('${row['nombre']}'))], onChanged: (value) => setState(() => clientId = value ?? clientId)),
      _field(type, 'Tipo *', hint: 'Aire acondicionado, freezer, cámara...'),
      Row(children: [Expanded(child: _field(brand, 'Marca')), const SizedBox(width: 10), Expanded(child: _field(model, 'Modelo'))]),
      Row(children: [Expanded(child: _field(serial, 'Serie')), const SizedBox(width: 10), Expanded(child: _field(capacity, 'Capacidad'))]),
      _field(location, 'Ubicación del equipo'),
      _field(notes, 'Observaciones', lines: 3),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: active, onChanged: (value) => setState(() => active = value), title: const Text('Equipo activo')),
    ],
    validate: () => clientId > 0 && type.text.trim().isNotEmpty,
    result: () => <String, dynamic>{'cliente_id': clientId, 'tipo': type.text.trim(), 'marca': brand.text.trim(), 'modelo': model.text.trim(), 'serie': serial.text.trim(), 'capacidad': capacity.text.trim(), 'ubicacion': location.text.trim(), 'observaciones': notes.text.trim(), 'activo': active},
  ).whenComplete(() { type.dispose(); brand.dispose(); model.dispose(); serial.dispose(); capacity.dispose(); location.dispose(); notes.dispose(); });
}

Future<Map<String, dynamic>?> showElectroTechnicianForm(BuildContext context, {required List<Map<String, dynamic>> users, Map<String, dynamic>? initial}) {
  var userId = _nullableId(initial?['usuario_id']);
  final name = TextEditingController(text: '${initial?['nombre'] ?? ''}');
  final phone = TextEditingController(text: '${initial?['telefono'] ?? ''}');
  final specialty = TextEditingController(text: '${initial?['especialidad'] ?? ''}');
  var active = initial?['activo'] != false;
  return _formDialog(
    context,
    title: initial == null ? 'Nuevo técnico' : 'Editar técnico',
    builder: (dialogContext, setState) => [
      DropdownButtonFormField<int?>(initialValue: userId, decoration: const InputDecoration(labelText: 'Cuenta VITI vinculada', border: OutlineInputBorder()), items: [const DropdownMenuItem<int?>(value: null, child: Text('Sin cuenta vinculada')), for (final row in users) DropdownMenuItem<int?>(value: _id(row['id']), child: Text('${row['nombre'] ?? ''} ${row['apellido'] ?? ''} · ${row['usuario'] ?? ''}'))], onChanged: (value) => setState(() => userId = value)),
      _field(name, 'Nombre *'),
      _field(phone, 'Teléfono'),
      _field(specialty, 'Especialidad'),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: active, onChanged: (value) => setState(() => active = value), title: const Text('Técnico activo')),
    ],
    validate: () => name.text.trim().isNotEmpty,
    result: () => <String, dynamic>{'usuario_id': userId, 'nombre': name.text.trim(), 'telefono': phone.text.trim(), 'especialidad': specialty.text.trim(), 'activo': active},
  ).whenComplete(() { name.dispose(); phone.dispose(); specialty.dispose(); });
}

Future<Map<String, dynamic>?> showElectroMaterialForm(BuildContext context, {Map<String, dynamic>? initial}) {
  final name = TextEditingController(text: '${initial?['nombre'] ?? ''}');
  final unit = TextEditingController(text: '${initial?['unidad'] ?? 'unidad'}');
  final stock = TextEditingController(text: '${initial?['stock'] ?? 0}');
  final minStock = TextEditingController(text: '${initial?['stock_minimo'] ?? 0}');
  final cost = TextEditingController(text: '${initial?['costo_unitario'] ?? 0}');
  var active = initial?['activo'] != false;
  return _formDialog(
    context,
    title: initial == null ? 'Nuevo material' : 'Editar material',
    builder: (dialogContext, setState) => [
      _field(name, 'Nombre *'),
      _field(unit, 'Unidad *', hint: 'unidad, metro, kg, cilindro...'),
      Row(children: [Expanded(child: _field(stock, 'Stock', number: true)), const SizedBox(width: 10), Expanded(child: _field(minStock, 'Stock mínimo', number: true))]),
      _field(cost, 'Costo unitario', number: true),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: active, onChanged: (value) => setState(() => active = value), title: const Text('Material activo')),
    ],
    validate: () => name.text.trim().isNotEmpty && unit.text.trim().isNotEmpty && _num(stock.text) != null && _num(minStock.text) != null && _num(cost.text) != null,
    result: () => <String, dynamic>{'nombre': name.text.trim(), 'unidad': unit.text.trim(), 'stock': _num(stock.text) ?? 0, 'stock_minimo': _num(minStock.text) ?? 0, 'costo_unitario': _num(cost.text) ?? 0, 'activo': active},
  ).whenComplete(() { name.dispose(); unit.dispose(); stock.dispose(); minStock.dispose(); cost.dispose(); });
}

Future<Map<String, dynamic>?> showElectroOrderForm(BuildContext context, {required List<Map<String, dynamic>> clients, required List<Map<String, dynamic>> equipment, required List<Map<String, dynamic>> technicians, Map<String, dynamic>? initial}) {
  var clientId = _id(initial?['cliente_id']);
  if (!clients.any((row) => _id(row['id']) == clientId)) clientId = _id(clients.first['id']);
  var equipmentId = _nullableId(initial?['equipo_id']);
  var technicianId = _nullableId(initial?['tecnico_id']);
  var priority = '${initial?['prioridad'] ?? 'normal'}';
  final date = TextEditingController(text: _isoDate(initial?['fecha_cita']));
  final time = TextEditingController(text: _time(initial?['hora_cita']));
  final address = TextEditingController(text: '${initial?['direccion_servicio'] ?? ''}');
  final reference = TextEditingController(text: '${initial?['referencia_ubicacion'] ?? ''}');
  final problem = TextEditingController(text: '${initial?['problema_reportado'] ?? ''}');
  final labor = TextEditingController(text: '${initial?['costo_mano_obra'] ?? 0}');
  final discount = TextEditingController(text: '${initial?['descuento'] ?? 0}');

  List<Map<String, dynamic>> availableEquipment() => equipment.where((row) => _id(row['cliente_id']) == clientId).toList(growable: false);

  return _formDialog(
    context,
    title: initial == null ? 'Nueva orden Electrofrío' : 'Editar cita y recepción',
    width: 700,
    builder: (dialogContext, setState) => [
      DropdownButtonFormField<int>(initialValue: clientId, decoration: const InputDecoration(labelText: 'Cliente *', border: OutlineInputBorder()), items: [for (final row in clients) DropdownMenuItem(value: _id(row['id']), child: Text('${row['nombre']}'))], onChanged: (value) => setState(() { clientId = value ?? clientId; if (!availableEquipment().any((row) => _id(row['id']) == equipmentId)) equipmentId = null; })),
      DropdownButtonFormField<int?>(initialValue: availableEquipment().any((row) => _id(row['id']) == equipmentId) ? equipmentId : null, decoration: const InputDecoration(labelText: 'Equipo', border: OutlineInputBorder()), items: [const DropdownMenuItem<int?>(value: null, child: Text('Sin equipo seleccionado')), for (final row in availableEquipment()) DropdownMenuItem<int?>(value: _id(row['id']), child: Text('${row['tipo'] ?? ''} ${row['marca'] ?? ''} ${row['modelo'] ?? ''}'))], onChanged: (value) => setState(() => equipmentId = value)),
      DropdownButtonFormField<int?>(initialValue: technicians.any((row) => _id(row['id']) == technicianId) ? technicianId : null, decoration: const InputDecoration(labelText: 'Técnico', border: OutlineInputBorder()), items: [const DropdownMenuItem<int?>(value: null, child: Text('Sin técnico asignado')), for (final row in technicians) DropdownMenuItem<int?>(value: _id(row['id']), child: Text('${row['nombre']}'))], onChanged: (value) => setState(() => technicianId = value)),
      Row(children: [Expanded(child: _field(date, 'Fecha de cita *', hint: 'AAAA-MM-DD')), const SizedBox(width: 10), Expanded(child: _field(time, 'Hora', hint: 'HH:MM'))]),
      _field(address, 'Dirección del servicio *'),
      _field(reference, 'Referencia de ubicación'),
      _field(problem, 'Problema reportado *', lines: 4),
      DropdownButtonFormField<String>(initialValue: priority, decoration: const InputDecoration(labelText: 'Prioridad', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'baja', child: Text('Baja')), DropdownMenuItem(value: 'normal', child: Text('Normal')), DropdownMenuItem(value: 'alta', child: Text('Alta')), DropdownMenuItem(value: 'urgente', child: Text('Urgente'))], onChanged: (value) => setState(() => priority = value ?? priority)),
      Row(children: [Expanded(child: _field(labor, 'Mano de obra', number: true)), const SizedBox(width: 10), Expanded(child: _field(discount, 'Descuento', number: true))]),
    ],
    validate: () => clientId > 0 && date.text.trim().isNotEmpty && address.text.trim().isNotEmpty && problem.text.trim().isNotEmpty,
    result: () => <String, dynamic>{'cliente_id': clientId, 'equipo_id': equipmentId, 'tecnico_id': technicianId, 'fecha_cita': date.text.trim(), 'hora_cita': time.text.trim(), 'direccion_servicio': address.text.trim(), 'referencia_ubicacion': reference.text.trim(), 'problema_reportado': problem.text.trim(), 'prioridad': priority, 'costo_mano_obra': _num(labor.text), 'descuento': _num(discount.text) ?? 0},
  ).whenComplete(() { date.dispose(); time.dispose(); address.dispose(); reference.dispose(); problem.dispose(); labor.dispose(); discount.dispose(); });
}

Future<Map<String, dynamic>?> _formDialog(BuildContext context, {required String title, required List<Widget> Function(BuildContext, StateSetter) builder, required bool Function() validate, required Map<String, dynamic> Function() result, double width = 620}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: SizedBox(width: width, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [for (final widget in builder(dialogContext, setState)) ...[widget, const SizedBox(height: 10)]]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () { if (!validate()) { ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Revisa los campos obligatorios.'))); return; } Navigator.pop(dialogContext, result()); }, child: const Text('Guardar')),
        ],
      ),
    ),
  );
}

Widget _field(TextEditingController controller, String label, {String? hint, int lines = 1, bool number = false}) => TextField(controller: controller, minLines: lines, maxLines: lines == 1 ? 1 : lines + 2, keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()));
int _id(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
int? _nullableId(dynamic value) { final id = _id(value); return id > 0 ? id : null; }
double? _num(String value) { final text = value.trim().replaceAll(',', '.'); return text.isEmpty ? null : double.tryParse(text); }
String _isoDate(dynamic value) { final date = DateTime.tryParse('${value ?? ''}'); return date?.toIso8601String().split('T').first ?? DateTime.now().toIso8601String().split('T').first; }
String _time(dynamic value) { final text = '${value ?? ''}'.trim(); return text.length >= 5 ? text.substring(0, 5) : text; }
