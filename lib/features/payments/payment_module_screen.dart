import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/ui/viti_ui.dart';
import '../data/viti_repository.dart';

class PaymentModuleScreen extends StatefulWidget {
  const PaymentModuleScreen({required this.repository, required this.admin, super.key});

  final VitiRepository repository;
  final bool admin;

  @override
  State<PaymentModuleScreen> createState() => _PaymentModuleScreenState();
}

class _PaymentModuleScreenState extends State<PaymentModuleScreen> {
  final searchController = TextEditingController();
  bool loading = true;
  bool sending = false;
  String? error;
  String query = '';
  Map<String, dynamic> data = <String, dynamic>{};
  Map<String, dynamic>? selectedProof;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      data = widget.admin ? await widget.repository.adminBilling() : await widget.repository.clientBilling();
      if (widget.admin && selectedProof != null) {
        final proofs = _collectProofs(_items(data['proyectos']), _items(data['suscripciones']));
        final selectedId = _int(_map(selectedProof!['pago'])['id']);
        selectedProof = proofs.where((item) => _int(_map(item['pago'])['id']) == selectedId && _text(item['tipo'], '') == _text(selectedProof!['tipo'], '')).firstOrNull;
      }
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No se pudieron cargar los pagos.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<PlatformFile?> _pickProof() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowMultiple: false, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf']);
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
    if (file == null || !mounted) return;
    setState(() => sending = true);
    try {
      final company = _map(project['empresa']);
      await widget.repository.sendProjectProof(projectId: _int(project['id']), amount: amount, method: _text(company['metodo_pago_preferido'], 'qr'), date: DateTime.now().toIso8601String().split('T').first, filePath: file.path!, fileName: file.name);
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
    if (file == null || !mounted) return;
    setState(() => sending = true);
    try {
      final company = _map(project['empresa']);
      await widget.repository.sendSubscriptionProof(subscriptionId: _int(subscription['id']), amount: amount, method: _text(company['metodo_pago_preferido'], 'qr'), date: DateTime.now().toIso8601String().split('T').first, filePath: file.path!, fileName: file.name);
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
    if (error != null) return Center(child: VitiEmptyState(title: 'No se pudieron cargar los pagos', message: error!, icon: Icons.cloud_off, action: FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))));
    return widget.admin ? _adminExperience() : _clientExperience();
  }

  Widget _clientExperience() {
    final projects = _items(data['proyectos']);
    final config = _map(data['configuracion']);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 38),
        children: [
          VitiPageHeader(
            title: 'Mis pagos',
            subtitle: 'Desarrollo y suscripción permanecen separados. Tu comprobante conserva trazabilidad y el saldo cambia únicamente después de la revisión de AGR Studio.',
            actions: [IconButton.filledTonal(onPressed: _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh))],
          ),
          const SizedBox(height: 18),
          if (config.isNotEmpty) _collectionData(config),
          if (config.isNotEmpty) const SizedBox(height: 14),
          if (projects.isEmpty) const VitiEmptyState(title: 'Sin obligaciones de pago', message: 'Cuando exista un proyecto o suscripción con saldo, aparecerá aquí.', icon: Icons.payments_outlined),
          for (final project in projects) ...[_clientProjectPayment(project), const SizedBox(height: 14)],
        ],
      ),
    );
  }

  Widget _collectionData(Map<String, dynamic> config) {
    return VitiPanel(
      tone: VitiTone.info,
      child: Row(
        children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.qr_code_2)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Datos de cobro VITI', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('${_text(config['banco'], 'Medio de pago VITI')} · Titular ${_text(config['titular'], 'AGR Studio')}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12))])),
          const VitiStatusBadge('Verificado', tone: VitiTone.success, icon: Icons.verified_outlined),
        ],
      ),
    );
  }

  Widget _clientProjectPayment(Map<String, dynamic> project) {
    final next = _map(project['siguiente_pago']);
    final subscription = _map(project['suscripcion']);
    final state = '${project['estado_pago'] ?? 'pendiente'}';
    final agreed = _number(project['precio_acordado']);
    final paid = _number(project['pagado']);
    final ratio = agreed <= 0 ? 0.0 : (paid / agreed).clamp(0.0, 1.0).toDouble();
    return VitiPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.receipt_long_outlined)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_text(project['codigo'], 'PRO')} · ${_text(project['nombre'], 'Proyecto')}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 5), VitiStatusBadge(vitiPretty(state), tone: vitiToneForStatus(state))]))]),
          const SizedBox(height: 16),
          Wrap(spacing: 20, runSpacing: 10, children: [VitiKeyValue('Acordado', _money(project['precio_acordado']), icon: Icons.request_quote_outlined), VitiKeyValue('Pagado', _money(project['pagado']), icon: Icons.check_circle_outline), VitiKeyValue('Pendiente', _money(project['pendiente']), icon: Icons.account_balance_wallet_outlined)]),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: ratio, minHeight: 8)),
          const SizedBox(height: 15),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (next['puede_enviar'] == true) FilledButton.icon(onPressed: sending ? null : () => _sendProjectProof(project), icon: const Icon(Icons.upload_file), label: Text('Enviar comprobante · ${_money(next['monto'])}')),
            if (next['comprobante_pendiente_id'] != null) const VitiStatusBadge('Proyecto en revisión', tone: VitiTone.warning, icon: Icons.schedule),
          ]),
          if (subscription.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.autorenew, size: 20), const SizedBox(width: 8), Expanded(child: Text('Suscripción · ${_text(subscription['plan'], 'Plan VITI')}', style: const TextStyle(fontWeight: FontWeight.w900))), VitiStatusBadge(vitiPretty('${subscription['estado'] ?? ''}'), tone: vitiToneForStatus('${subscription['estado'] ?? ''}'))]),
            const SizedBox(height: 8),
            Text('Pendiente ${_money(subscription['importe_pendiente'])}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [if (subscription['puede_enviar_comprobante'] == true) OutlinedButton.icon(onPressed: sending ? null : () => _sendSubscriptionProof(project), icon: const Icon(Icons.upload_file), label: const Text('Enviar comprobante de suscripción')), if (subscription['comprobante_pendiente_id'] != null) const VitiStatusBadge('Suscripción en revisión', tone: VitiTone.warning, icon: Icons.schedule)]),
          ],
        ],
      ),
    );
  }

  Widget _adminExperience() {
    final summary = _map(data['resumen']);
    final projects = _items(data['proyectos']);
    final subscriptions = _items(data['suscripciones']);
    final allProofs = _collectProofs(projects, subscriptions);
    final visible = allProofs.where((wrapper) {
      if (query.trim().isEmpty) return true;
      final payment = _map(wrapper['pago']);
      final company = _map(wrapper['empresa']);
      final parent = _map(wrapper['padre']);
      final payer = _map(payment['pagador']);
      final haystack = '${company['nombre_comercial']} ${payer['nombre']} ${payer['usuario']} ${parent['codigo']} ${parent['nombre']} ${payment['comprobante_nombre']} ${payment['estado_revision']}'.toLowerCase();
      return haystack.contains(query.toLowerCase().trim());
    }).toList(growable: false);
    final pending = allProofs.where((item) => _text(_map(item['pago'])['estado_revision'], '') == 'pendiente_revision').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1080;
        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VitiPageHeader(title: 'Pagos VITI', subtitle: 'Control económico, comprobantes y saldos con revisión antes de afectar los importes.', actions: [IconButton.filledTonal(onPressed: _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh))]),
            const SizedBox(height: 18),
            Wrap(spacing: 12, runSpacing: 12, children: [VitiMetricTile(label: 'Por cobrar', value: _money(summary['por_cobrar_proyectos']), icon: Icons.account_balance_wallet_outlined, tone: VitiTone.warning), VitiMetricTile(label: 'Comprobantes pendientes', value: '$pending', icon: Icons.receipt_long_outlined, tone: VitiTone.warning), VitiMetricTile(label: 'Suscripciones activas', value: '${summary['suscripciones_activas'] ?? 0}', icon: Icons.autorenew, tone: VitiTone.success), VitiMetricTile(label: 'Recurrente mensual', value: _money(summary['ingreso_recurrente_mensual']), icon: Icons.trending_up, tone: VitiTone.info)]),
            const SizedBox(height: 16),
            VitiSearchField(controller: searchController, hint: 'Buscar comprobante, empresa, pagador o proyecto…', onChanged: (value) => setState(() => query = value), width: 430),
            const SizedBox(height: 14),
          ],
        );

        final list = VitiPanel(
          padding: const EdgeInsets.all(10),
          child: visible.isEmpty
              ? const VitiEmptyState(title: 'Sin comprobantes', message: 'No hay resultados para la búsqueda actual.', icon: Icons.receipt_long_outlined)
              : ListView.builder(
                  shrinkWrap: !desktop,
                  physics: desktop ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => _proofRow(visible[index], desktop: desktop),
                ),
        );

        final content = desktop
            ? SizedBox(height: constraints.maxHeight - 270, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: list), const SizedBox(width: 14), Expanded(flex: 4, child: selectedProof == null ? const VitiEmptyState(title: 'Selecciona un comprobante', message: 'Aquí aparecerán el pagador, archivo, estado y acciones de revisión.', icon: Icons.receipt_long_outlined) : SingleChildScrollView(child: _proofInspector(selectedProof!)))]))
            : list;

        return RefreshIndicator(
          onRefresh: _load,
          child: desktop
              ? Padding(padding: const EdgeInsets.fromLTRB(24, 22, 24, 30), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [header, Expanded(child: content)]))
              : ListView(padding: const EdgeInsets.fromLTRB(24, 22, 24, 30), children: [header, content, const SizedBox(height: 28), _projectBalances(projects)]),
        );
      },
    );
  }

  Widget _proofRow(Map<String, dynamic> wrapper, {required bool desktop}) {
    final payment = _map(wrapper['pago']);
    final parent = _map(wrapper['padre']);
    final company = _map(wrapper['empresa']);
    final payer = _map(payment['pagador']);
    final type = _text(wrapper['tipo'], 'proyecto');
    final status = '${payment['estado_revision'] ?? 'pendiente_revision'}';
    return VitiEntityRow(
      title: '${_money(payment['monto'])} · ${type == 'suscripcion' ? 'Suscripción' : _text(parent['codigo'], 'Proyecto')}',
      subtitle: '${_text(company['nombre_comercial'], 'Sin empresa')} · ${_text(payer['nombre'], _text(payer['usuario'], 'Pagador'))}\n${_pretty(payment['metodo'])} · ${_date(payment['fecha_pago'])}',
      icon: _fileIcon(_text(payment['comprobante_mime'], ''), _text(payment['comprobante_nombre'], '')),
      selected: selectedProof != null && _int(_map(selectedProof!['pago'])['id']) == _int(payment['id']) && _text(selectedProof!['tipo'], '') == type,
      badges: [VitiStatusBadge(vitiPretty(status), tone: vitiToneForStatus(status)), VitiStatusBadge(type == 'suscripcion' ? 'Suscripción' : 'Proyecto', tone: VitiTone.info)],
      onTap: () {
        if (desktop) {
          setState(() => selectedProof = wrapper);
        } else {
          _showProof(wrapper);
        }
      },
    );
  }

  Widget _proofInspector(Map<String, dynamic> wrapper) {
    final payment = _map(wrapper['pago']);
    final parent = _map(wrapper['padre']);
    final company = _map(wrapper['empresa']);
    final payer = _map(payment['pagador']);
    final type = _text(wrapper['tipo'], 'proyecto');
    final status = '${payment['estado_revision'] ?? 'pendiente_revision'}';
    final pending = status == 'pendiente_revision';
    return VitiInspector(
      title: _text(payment['comprobante_nombre'], 'Comprobante'),
      subtitle: '${_money(payment['monto'])} · ${type == 'suscripcion' ? 'Suscripción' : _text(parent['codigo'], 'Proyecto')}',
      icon: _fileIcon(_text(payment['comprobante_mime'], ''), _text(payment['comprobante_nombre'], '')),
      badges: [VitiStatusBadge(vitiPretty(status), tone: vitiToneForStatus(status))],
      actions: [
        OutlinedButton.icon(onPressed: () => _showProof(wrapper), icon: const Icon(Icons.open_in_new), label: const Text('Abrir ficha')),
        if (pending) TextButton.icon(onPressed: () => _rejectProof(wrapper), icon: const Icon(Icons.close), label: const Text('Rechazar')),
        if (pending) FilledButton.icon(onPressed: () => _confirmProof(wrapper), icon: const Icon(Icons.check), label: const Text('Confirmar pago')),
      ],
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_fileIcon(_text(payment['comprobante_mime'], ''), _text(payment['comprobante_nombre'], '')), size: 44, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 8), Text(_text(payment['comprobante_mime'], 'Archivo'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 4), const Text('Vista integrada del archivo: siguiente etapa', style: TextStyle(fontSize: 10))]),
        ),
        const SizedBox(height: 16),
        VitiKeyValue('Pagador', _text(payer['nombre'], _text(payer['usuario'], 'No identificado')), icon: Icons.person_outline),
        VitiKeyValue('Empresa', _text(company['nombre_comercial'], 'Sin empresa'), icon: Icons.business_outlined),
        VitiKeyValue(type == 'suscripcion' ? 'Plan' : 'Proyecto', type == 'suscripcion' ? _text(parent['plan'], 'Suscripción VITI') : '${_text(parent['codigo'], 'PRO')} · ${_text(parent['nombre'], 'Proyecto')}', icon: type == 'suscripcion' ? Icons.autorenew : Icons.account_tree_outlined),
        VitiKeyValue('Método y fecha', '${_pretty(payment['metodo'])} · ${_date(payment['fecha_pago'])}', icon: Icons.calendar_today_outlined),
        if (_text(payment['motivo_revision'], '').isNotEmpty) VitiKeyValue('Motivo de revisión', _text(payment['motivo_revision'], ''), icon: Icons.info_outline),
      ],
    );
  }

  Widget _projectBalances(List<Map<String, dynamic>> projects) {
    return VitiPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Proyectos y saldos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), const SizedBox(height: 10), for (final project in projects.take(12)) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.account_tree_outlined), title: Text('${_text(project['codigo'], 'PRO')} · ${_text(project['nombre'], 'Proyecto')}', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${_text(_map(project['empresa'])['nombre_comercial'], 'Sin empresa')} · Pendiente ${_money(project['pendiente'])}'), trailing: VitiStatusBadge(vitiPretty('${project['estado_pago'] ?? ''}'), tone: vitiToneForStatus('${project['estado_pago'] ?? ''}')))]));
  }

  Future<void> _showProof(Map<String, dynamic> wrapper) async {
    final payment = _map(wrapper['pago']);
    final parent = _map(wrapper['padre']);
    final company = _map(wrapper['empresa']);
    final payer = _map(payment['pagador']);
    final type = _text(wrapper['tipo'], 'proyecto');
    final status = '${payment['estado_revision'] ?? ''}';
    final pending = status == 'pendiente_revision';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(type == 'suscripcion' ? 'Comprobante de suscripción' : 'Comprobante · ${_text(parent['codigo'], 'Proyecto')}'),
        content: SizedBox(width: 700, child: VitiPanel(child: Wrap(spacing: 24, runSpacing: 8, children: [SizedBox(width: 210, child: VitiKeyValue('Monto', _money(payment['monto']), icon: Icons.payments_outlined)), SizedBox(width: 210, child: VitiKeyValue('Método', _pretty(payment['metodo']), icon: Icons.account_balance_outlined)), SizedBox(width: 210, child: VitiKeyValue('Fecha', _date(payment['fecha_pago']), icon: Icons.calendar_today_outlined)), SizedBox(width: 210, child: VitiKeyValue('Estado', vitiPretty(status), icon: Icons.fact_check_outlined)), SizedBox(width: 210, child: VitiKeyValue('Empresa', _text(company['nombre_comercial'], 'Sin empresa'), icon: Icons.business_outlined)), SizedBox(width: 210, child: VitiKeyValue('Pagador', _text(payer['nombre'], _text(payer['usuario'], 'No identificado')), icon: Icons.person_outline)), SizedBox(width: 440, child: VitiKeyValue('Archivo', _text(payment['comprobante_nombre'], 'Sin archivo identificado'), icon: _fileIcon(_text(payment['comprobante_mime'], ''), _text(payment['comprobante_nombre'], ''))))]))),
        actions: [if (pending) TextButton.icon(onPressed: () {Navigator.pop(dialogContext); _rejectProof(wrapper);}, icon: const Icon(Icons.close), label: const Text('Rechazar')), if (pending) FilledButton.icon(onPressed: () {Navigator.pop(dialogContext); _confirmProof(wrapper);}, icon: const Icon(Icons.check), label: const Text('Confirmar pago')), TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar'))],
      ),
    );
  }

  Future<void> _confirmProof(Map<String, dynamic> wrapper) async {
    final id = _int(_map(wrapper['pago'])['id']);
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
        content: SizedBox(width: 500, child: TextField(controller: reason, autofocus: true, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Motivo para el cliente *'))),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')), FilledButton(onPressed: () {final text = reason.text.trim(); if (text.length < 5) return; Navigator.pop(dialogContext, text);}, child: const Text('Rechazar'))],
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

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
List<Map<String, dynamic>> _items(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
String _pretty(dynamic value) => vitiPretty(_text(value, 'Sin estado'));
double _number(dynamic value) => double.tryParse('${value ?? 0}') ?? 0;
String _money(dynamic value) => '${_number(value).toStringAsFixed(2)} Bs';
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
