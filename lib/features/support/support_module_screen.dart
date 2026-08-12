import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/ui/viti_ui.dart';
import '../data/viti_repository.dart';
import '../messages/message_module_screen.dart';

class SupportModuleScreen extends StatefulWidget {
  const SupportModuleScreen({required this.repository, required this.module, super.key});

  final VitiRepository repository;
  final String module;

  @override
  State<SupportModuleScreen> createState() => _SupportModuleScreenState();
}

class _SupportModuleScreenState extends State<SupportModuleScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic> data = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    if (widget.module != 'mensajes') _load();
  }

  @override
  void didUpdateWidget(covariant SupportModuleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.module != widget.module && widget.module != 'mensajes') _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      data = await widget.repository.supportSummary();
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No se pudo cargar el espacio de soporte.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.module == 'mensajes') return MessageModuleScreen(repository: widget.repository, support: true);
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: VitiEmptyState(title: 'No se pudo cargar Soporte', message: error!, icon: Icons.cloud_off, action: FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))));

    final summary = _map(data['resumen']);
    final maintenance = _items(data['mantenimientos']);
    final projects = _items(data['proyectos']);
    final requests = _items(data['solicitudes']);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 38),
        children: [
          VitiPageHeader(title: 'Mi trabajo', subtitle: 'Solicitudes, proyectos y casos delegados a tu cuenta. El espacio permanece aislado del panel administrativo global.', actions: [IconButton.filledTonal(onPressed: _load, tooltip: 'Actualizar', icon: const Icon(Icons.refresh))]),
          const SizedBox(height: 18),
          Wrap(spacing: 12, runSpacing: 12, children: [
            VitiMetricTile(label: 'Solicitudes', value: '${summary['solicitudes'] ?? 0}', icon: Icons.assignment_outlined, tone: VitiTone.warning),
            VitiMetricTile(label: 'Proyectos', value: '${summary['proyectos'] ?? 0}', icon: Icons.account_tree_outlined, tone: VitiTone.primary),
            VitiMetricTile(label: 'Casos abiertos', value: '${summary['casos_abiertos'] ?? 0}', icon: Icons.build_circle_outlined, tone: VitiTone.info),
            VitiMetricTile(label: 'No leídos', value: '${summary['mensajes_no_leidos'] ?? 0}', icon: Icons.mark_chat_unread_outlined, tone: VitiTone.danger),
          ]),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1120;
              final blocks = <Widget>[
                _supportList(title: 'Casos asignados', subtitle: 'Atención y mantenimiento', icon: Icons.build_circle_outlined, items: maintenance, titleBuilder: (row) => '${_text(row['codigo'], '')} ${_text(row['titulo'], 'Caso')}', subtitleBuilder: (row) => _text(_map(row['empresa'])['nombre_comercial'], 'Sin empresa'), statusBuilder: (row) => '${row['estado'] ?? 'abierto'}'),
                _supportList(title: 'Proyectos asignados', subtitle: 'Desarrollo bajo tu responsabilidad', icon: Icons.account_tree_outlined, items: projects, titleBuilder: (row) => '${_text(row['codigo'], '')} ${_text(row['nombre'], 'Proyecto')}', subtitleBuilder: (row) => '${row['progreso'] ?? 0}% de progreso', statusBuilder: (row) => '${row['fase'] ?? 'desarrollo'}'),
                _supportList(title: 'Solicitudes asignadas', subtitle: 'Entrada y revisión', icon: Icons.assignment_outlined, items: requests, titleBuilder: (row) => '${_text(row['codigo'], '')} ${_text(row['titulo'], 'Solicitud')}', subtitleBuilder: (row) => 'Prioridad ${vitiPretty('${row['prioridad'] ?? 'normal'}')}', statusBuilder: (row) => '${row['estado'] ?? 'en_revision'}'),
              ];
              if (!wide) return Column(children: [for (var index = 0; index < blocks.length; index++) ...[blocks[index], if (index < blocks.length - 1) const SizedBox(height: 14)]]);
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var index = 0; index < blocks.length; index++) ...[Expanded(child: blocks[index]), if (index < blocks.length - 1) const SizedBox(width: 14)]]);
            },
          ),
        ],
      ),
    );
  }

  Widget _supportList({required String title, required String subtitle, required IconData icon, required List<Map<String, dynamic>> items, required String Function(Map<String, dynamic>) titleBuilder, required String Function(Map<String, dynamic>) subtitleBuilder, required String Function(Map<String, dynamic>) statusBuilder}) {
    return VitiPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant))]))]),
          const SizedBox(height: 12),
          if (items.isEmpty) const VitiEmptyState(title: 'Sin registros asignados', message: 'Cuando AGR Studio delegue trabajo, aparecerá aquí.'),
          for (final row in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .7))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titleBuilder(row), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitleBuilder(row), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 7), VitiStatusBadge(vitiPretty(statusBuilder(row)), tone: vitiToneForStatus(statusBuilder(row)))]),
              ),
            ),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _items(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
