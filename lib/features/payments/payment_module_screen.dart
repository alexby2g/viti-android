import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../data/viti_repository.dart';

class PaymentModuleScreen extends StatefulWidget {
  const PaymentModuleScreen({required this.repository, required this.admin, super.key});

  final VitiRepository repository;
  final bool admin;

  @override
  State<PaymentModuleScreen> createState() => _PaymentModuleScreenState();
}

class _PaymentModuleScreenState extends State<PaymentModuleScreen> {
  bool loading = true;
  bool sending = false;
  String? error;
  Map<String, dynamic> data = <String, dynamic>{};

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
      data = widget.admin ? await widget.repository.adminBilling() : await widget.repository.clientBilling();
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No se pudieron cargar los pagos.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<PlatformFile?> _pickProof() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    if (file.size > 5 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El comprobante no puede superar 5 MB.')));
      return null;
    }
    if (file.path == null || file.path!.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo acceder al archivo seleccionado.')));
      return null;
    }
    return file;
  }

  Future<void> _sendProjectProof(Map<String, dynamic> project) async {
    final next = _map(project['siguiente_pago']);
    final amount = '${next['monto'] ?? 0}';
    if ((double.tryParse(amount) ?? 0) <= 0) return;
    final file = await _pickProof();
    if (file == null) return;
    setState(() => sending = true);
    try {
      final company = _map(project['empresa']);
      await widget.repository.sendProjectProof(
        projectId: _int(project['id']),
        amount: amount,
        method: _text(company['metodo_pago_preferido'], 'qr'),
        date: DateTime.now().toIso8601String().split('T').first,
        filePath: file.path!,
        fileName: file.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comprobante enviado para revisión.')));
      await _load();
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _sendSubscriptionProof(Map<String, dynamic> project) async {
    final subscription = _map(project['suscripcion']);
    final amount = '${subscription['importe_pendiente'] ?? 0}';
    if ((double.tryParse(amount) ?? 0) <= 0 || _int(subscription['id']) <= 0) return;
    final file = await _pickProof();
    if (file == null) return;
    setState(() => sending = true);
    try {
      final company = _map(project['empresa']);
      await widget.repository.sendSubscriptionProof(
        subscriptionId: _int(subscription['id']),
        amount: amount,
        method: _text(company['metodo_pago_preferido'], 'qr'),
        date: DateTime.now().toIso8601String().split('T').first,
        filePath: file.path!,
        fileName: file.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comprobante de suscripción enviado.')));
      await _load();
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return _PaymentError(message: error!, retry: _load);
    return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(24), children: widget.admin ? _adminContent() : _clientContent()));
  }

  List<Widget> _clientContent() {
    final projects = _items(data['proyectos']);
    final config = _map(data['configuracion']);
    return [
      const Text('Mis pagos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      const Text('El desarrollo y la suscripción se controlan por separado. Un comprobante no modifica el saldo hasta que AGR Studio lo confirme.', style: TextStyle(color: Colors.white60)),
      const SizedBox(height: 18),
      if (config.isNotEmpty)
        Card(child: ListTile(leading: const Icon(Icons.qr_code_2), title: Text(_text(config['banco'], 'Medio de pago VITI')), subtitle: Text('Titular: ${_text(config['titular'], 'AGR Studio')}'))),
      const SizedBox(height: 10),
      if (projects.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Todavía no hay obligaciones de pago.'))),
      for (final project in projects) ...[
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text('${_text(project['codigo'], 'PRO')} · ${_text(project['nombre'], 'Proyecto')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), Chip(label: Text(_pretty(project['estado_pago'])))]),
              const SizedBox(height: 12),
              Wrap(spacing: 22, runSpacing: 10, children: [
                _Money(label: 'Acordado', value: project['precio_acordado']),
                _Money(label: 'Pagado', value: project['pagado']),
                _Money(label: 'Pendiente', value: project['pendiente']),
              ]),
              const SizedBox(height: 14),
              if (_map(project['siguiente_pago'])['puede_enviar'] == true)
                FilledButton.icon(onPressed: sending ? null : () => _sendProjectProof(project), icon: const Icon(Icons.upload_file), label: Text('Enviar comprobante · ${_money(_map(project['siguiente_pago'])['monto'])}')),
              if (_map(project['siguiente_pago'])['comprobante_pendiente_id'] != null)
                const Chip(avatar: Icon(Icons.schedule, size: 18), label: Text('Comprobante del proyecto en revisión')),
              if (_map(project['suscripcion']).isNotEmpty) ...[
                const Divider(height: 30),
                Text('Suscripción · ${_text(_map(project['suscripcion'])['plan'], 'Plan VITI')}', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('${_pretty(_map(project['suscripcion'])['estado'])} · ${_money(_map(project['suscripcion'])['importe_pendiente'])}', style: const TextStyle(color: Colors.white60)),
                if (_map(project['suscripcion'])['puede_enviar_comprobante'] == true) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(onPressed: sending ? null : () => _sendSubscriptionProof(project), icon: const Icon(Icons.upload_file), label: const Text('Enviar comprobante de suscripción')),
                ],
                if (_map(project['suscripcion'])['comprobante_pendiente_id'] != null)
                  const Chip(avatar: Icon(Icons.schedule, size: 18), label: Text('Comprobante de suscripción en revisión')),
              ],
            ]),
          ),
        ),
      ],
    ];
  }

  List<Widget> _adminContent() {
    final summary = _map(data['resumen']);
    final projects = _items(data['proyectos']);
    return [
      const Text('Pagos VITI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      const Text('Resumen económico sincronizado con el panel web.', style: TextStyle(color: Colors.white60)),
      const SizedBox(height: 18),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _PaymentStat('Por cobrar', _money(summary['por_cobrar_proyectos']), Icons.account_balance_wallet_outlined),
        _PaymentStat('Comprobantes pendientes', '${summary['comprobantes_pendientes'] ?? 0}', Icons.receipt_long_outlined),
        _PaymentStat('Suscripciones activas', '${summary['suscripciones_activas'] ?? 0}', Icons.autorenew),
        _PaymentStat('Recurrente mensual', _money(summary['ingreso_recurrente_mensual']), Icons.trending_up),
      ]),
      const SizedBox(height: 20),
      const Text('Proyectos y saldos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      for (final project in projects)
        Card(child: ListTile(title: Text('${_text(project['codigo'], 'PRO')} · ${_text(project['nombre'], 'Proyecto')}'), subtitle: Text('${_text(_map(project['empresa'])['nombre_comercial'], 'Sin empresa')} · Pendiente ${_money(project['pendiente'])}'), trailing: Chip(label: Text(_pretty(project['estado_pago']))))),
      const SizedBox(height: 10),
      const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('La revisión/confirmación de comprobantes se conectará en el siguiente bloque para conservar la misma ficha detallada que ya tiene VITI Web.'))),
    ];
  }
}

class _Money extends StatelessWidget {
  const _Money({required this.label, required this.value});
  final String label;
  final dynamic value;
  @override
  Widget build(BuildContext context) => SizedBox(width: 150, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white60)), Text(_money(value), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))]));
}

class _PaymentStat extends StatelessWidget {
  const _PaymentStat(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: 230, child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [CircleAvatar(child: Icon(icon)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: Colors.white60))]))]))));
}

class _PaymentError extends StatelessWidget {
  const _PaymentError({required this.message, required this.retry});
  final String message;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message), const SizedBox(height: 12), FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))]));
}

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
List<Map<String, dynamic>> _items(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
String _pretty(dynamic value) => _text(value, 'Sin estado').replaceAll('_', ' ');
String _money(dynamic value) => '${(double.tryParse('${value ?? 0}') ?? 0).toStringAsFixed(2)} Bs';
int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
