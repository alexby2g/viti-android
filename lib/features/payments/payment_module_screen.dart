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
    if (!mounted) return;
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: widget.admin ? _adminContent() : _clientContent(),
      ),
    );
  }

  List<Widget> _clientContent() {
    final projects = _items(data['proyectos']);
    final config = _map(data['configuracion']);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return [
      const Text('Mis pagos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text('El desarrollo y la suscripción se controlan por separado. Un comprobante no modifica el saldo hasta que AGR Studio lo confirme.', style: TextStyle(color: muted)),
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
                Text('${_pretty(_map(project['suscripcion'])['estado'])} · ${_money(_map(project['suscripcion'])['importe_pendiente'])}', style: TextStyle(color: muted)),
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
    final subscriptions = _items(data['suscripciones']);
    final proofs = _collectProofs(projects, subscriptions);
    final pending = proofs.where((item) => _text(_map(item['pago'])['estado_revision'], '') == 'pendiente_revision').toList(growable: false);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Pagos VITI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('Control económico y revisión de comprobantes del cliente.', style: TextStyle(color: muted))])),
          IconButton.filledTonal(onPressed: _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh)),
        ],
      ),
      const SizedBox(height: 18),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _PaymentStat('Por cobrar', _money(summary['por_cobrar_proyectos']), Icons.account_balance_wallet_outlined),
        _PaymentStat('Comprobantes pendientes', '${summary['comprobantes_pendientes'] ?? 0}', Icons.receipt_long_outlined),
        _PaymentStat('Suscripciones activas', '${summary['suscripciones_activas'] ?? 0}', Icons.autorenew),
        _PaymentStat('Recurrente mensual', _money(summary['ingreso_recurrente_mensual']), Icons.trending_up),
      ]),
      const SizedBox(height: 22),
      Row(children: [const Expanded(child: Text('Comprobantes por revisar', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), Chip(label: Text('${pending.length} pendientes'))]),
      const SizedBox(height: 8),
      if (pending.isEmpty)
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [const Icon(Icons.task_alt), const SizedBox(width: 10), Expanded(child: Text('No hay comprobantes pendientes de revisión.', style: TextStyle(color: muted)))]))),
      for (final proof in pending) _proofCard(proof),
      const SizedBox(height: 22),
      const Text('Últimos comprobantes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      if (proofs.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(20), child: Text('Todavía no hay comprobantes registrados.', style: TextStyle(color: muted)))),
      for (final proof in proofs.take(20)) _proofCard(proof),
      const SizedBox(height: 22),
      const Text('Proyectos y saldos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      for (final project in projects)
        Card(child: ListTile(title: Text('${_text(project['codigo'], 'PRO')} · ${_text(project['nombre'], 'Proyecto')}'), subtitle: Text('${_text(_map(project['empresa'])['nombre_comercial'], 'Sin empresa')} · Pendiente ${_money(project['pendiente'])}'), trailing: Chip(label: Text(_pretty(project['estado_pago']))))),
    ];
  }

  Widget _proofCard(Map<String, dynamic> wrapper) {
    final payment = _map(wrapper['pago']);
    final parent = _map(wrapper['padre']);
    final company = _map(wrapper['empresa']);
    final payer = _map(payment['pagador']);
    final type = _text(wrapper['tipo'], 'proyecto');
    final pending = _text(payment['estado_revision'], '') == 'pendiente_revision';
    final colors = Theme.of(context).colorScheme;
    final status = _pretty(payment['estado_revision']);

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showProof(wrapper),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: pending ? colors.tertiaryContainer : colors.primaryContainer,
                foregroundColor: pending ? colors.onTertiaryContainer : colors.onPrimaryContainer,
                child: Icon(_fileIcon(_text(payment['comprobante_mime'], ''), _text(payment['comprobante_nombre'], ''))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_money(payment['monto'])} · ${type == 'suscripcion' ? 'Suscripción' : _text(parent['codigo'], 'Proyecto')}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('${_text(company['nombre_comercial'], 'Sin empresa')} · ${_text(payer['nombre'], _text(payer['usuario'], 'Pagador'))}', style: TextStyle(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text('${_pretty(payment['metodo'])} · ${_date(payment['fecha_pago'])} · ${_text(payment['comprobante_nombre'], 'Sin archivo identificado')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                ]),
              ),
              Chip(label: Text(status)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProof(Map<String, dynamic> wrapper) async {
    final payment = _map(wrapper['pago']);
    final parent = _map(wrapper['padre']);
    final company = _map(wrapper['empresa']);
    final payer = _map(payment['pagador']);
    final type = _text(wrapper['tipo'], 'proyecto');
    final pending = _text(payment['estado_revision'], '') == 'pendiente_revision';
    final colors = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(type == 'suscripcion' ? 'Comprobante de suscripción' : 'Comprobante · ${_text(parent['codigo'], 'Proyecto')}'),
        content: SizedBox(
          width: 660,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    CircleAvatar(radius: 28, child: Icon(_fileIcon(_text(payment['comprobante_mime'], ''), _text(payment['comprobante_nombre'], '')), size: 28)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_text(payment['comprobante_nombre'], 'Archivo de comprobante'), style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(_text(payment['comprobante_mime'], 'Formato no identificado'), style: TextStyle(color: colors.onSurfaceVariant))])),
                  ]),
                ),
                const SizedBox(height: 16),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  _ProofField('Monto', _money(payment['monto'])),
                  _ProofField('Método', _pretty(payment['metodo'])),
                  _ProofField('Fecha', _date(payment['fecha_pago'])),
                  _ProofField('Estado', _pretty(payment['estado_revision'])),
                  _ProofField('Empresa', _text(company['nombre_comercial'], 'Sin empresa')),
                  _ProofField('Pagador', _text(payer['nombre'], _text(payer['usuario'], 'No identificado'))),
                  _ProofField(type == 'suscripcion' ? 'Plan' : 'Proyecto', type == 'suscripcion' ? _text(parent['plan'], 'Suscripción VITI') : '${_text(parent['codigo'], 'PRO')} · ${_text(parent['nombre'], 'Proyecto')}'),
                  _ProofField('Origen', _pretty(payment['origen'])),
                ]),
                if (_text(payment['motivo_revision'], '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('Motivo de revisión', style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  SelectableText(_text(payment['motivo_revision'], '')),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (pending)
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _rejectProof(wrapper);
              },
              icon: const Icon(Icons.close),
              label: const Text('Rechazar'),
            ),
          if (pending)
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _confirmProof(wrapper);
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirmar pago'),
            ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _confirmProof(Map<String, dynamic> wrapper) async {
    final payment = _map(wrapper['pago']);
    final id = _int(payment['id']);
    if (id <= 0) return;
    try {
      if (_text(wrapper['tipo'], 'proyecto') == 'suscripcion') {
        await widget.repository.confirmSubscriptionProof(id);
      } else {
        await widget.repository.confirmProjectProof(id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comprobante confirmado. Los saldos fueron actualizados.')));
      await _load();
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  Future<void> _rejectProof(Map<String, dynamic> wrapper) async {
    final reason = TextEditingController();
    final motive = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rechazar comprobante'),
        content: SizedBox(width: 500, child: TextField(controller: reason, autofocus: true, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Motivo para el cliente *', border: OutlineInputBorder()))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            final text = reason.text.trim();
            if (text.length < 5) return;
            Navigator.pop(dialogContext, text);
          }, child: const Text('Rechazar')),
        ],
      ),
    );
    reason.dispose();
    if (motive == null) return;
    final id = _int(_map(wrapper['pago'])['id']);
    if (id <= 0) return;
    try {
      if (_text(wrapper['tipo'], 'proyecto') == 'suscripcion') {
        await widget.repository.rejectSubscriptionProof(id, motive);
      } else {
        await widget.repository.rejectProjectProof(id, motive);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comprobante rechazado. El cliente podrá enviar uno nuevo.')));
      await _load();
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  List<Map<String, dynamic>> _collectProofs(List<Map<String, dynamic>> projects, List<Map<String, dynamic>> subscriptions) {
    final items = <Map<String, dynamic>>[];
    for (final project in projects) {
      for (final payment in _items(project['pagos'])) {
        items.add(<String, dynamic>{'tipo': 'proyecto', 'padre': project, 'empresa': _map(project['empresa']), 'pago': payment});
      }
    }
    for (final subscription in subscriptions) {
      for (final payment in _items(subscription['pagos'])) {
        items.add(<String, dynamic>{'tipo': 'suscripcion', 'padre': subscription, 'empresa': _map(subscription['empresa']), 'pago': payment});
      }
    }
    items.sort((a, b) {
      final ad = DateTime.tryParse('${_map(a['pago'])['created_at'] ?? _map(a['pago'])['fecha_pago'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = DateTime.tryParse('${_map(b['pago'])['created_at'] ?? _map(b['pago'])['fecha_pago'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return items;
  }
}

class _Money extends StatelessWidget {
  const _Money({required this.label, required this.value});
  final String label;
  final dynamic value;
  @override
  Widget build(BuildContext context) => SizedBox(width: 150, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), Text(_money(value), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))]));
}

class _PaymentStat extends StatelessWidget {
  const _PaymentStat(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: 230, child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [CircleAvatar(child: Icon(icon)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))]))]))));
}

class _ProofField extends StatelessWidget {
  const _ProofField(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]),
      );
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
String _date(dynamic value) {
  final parsed = DateTime.tryParse('${value ?? ''}')?.toLocal();
  if (parsed == null) return 'No definida';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year}';
}
IconData _fileIcon(String mime, String name) {
  final lower = name.toLowerCase();
  if (mime.contains('pdf') || lower.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
  if (mime.startsWith('image/') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp')) return Icons.image_outlined;
  return Icons.insert_drive_file_outlined;
}
int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
