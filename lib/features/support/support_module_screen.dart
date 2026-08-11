import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
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
    if (widget.module == 'mensajes') {
      return MessageModuleScreen(repository: widget.repository, support: true);
    }
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))])));
    }

    final summary = _map(data['resumen']);
    final maintenance = _items(data['mantenimientos']);
    final projects = _items(data['proyectos']);
    final requests = _items(data['solicitudes']);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Mi trabajo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Solicitudes, proyectos y casos que AGR Studio te asignó.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 18),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _SupportStat('Solicitudes', summary['solicitudes'], Icons.assignment_outlined),
            _SupportStat('Proyectos', summary['proyectos'], Icons.account_tree_outlined),
            _SupportStat('Casos abiertos', summary['casos_abiertos'], Icons.build_circle_outlined),
            _SupportStat('No leídos', summary['mensajes_no_leidos'], Icons.mark_chat_unread_outlined),
          ]),
          const SizedBox(height: 20),
          _SupportList(title: 'Casos asignados', icon: Icons.build_circle_outlined, items: maintenance, titleBuilder: (row) => '${_text(row['codigo'], '')} ${_text(row['titulo'], 'Caso')}', subtitleBuilder: (row) => '${_text(_map(row['empresa'])['nombre_comercial'], 'Sin empresa')} · ${_pretty(row['estado'])}'),
          const SizedBox(height: 14),
          _SupportList(title: 'Proyectos asignados', icon: Icons.account_tree_outlined, items: projects, titleBuilder: (row) => '${_text(row['codigo'], '')} ${_text(row['nombre'], 'Proyecto')}', subtitleBuilder: (row) => '${_pretty(row['fase'])} · ${row['progreso'] ?? 0}%'),
          const SizedBox(height: 14),
          _SupportList(title: 'Solicitudes asignadas', icon: Icons.assignment_outlined, items: requests, titleBuilder: (row) => '${_text(row['codigo'], '')} ${_text(row['titulo'], 'Solicitud')}', subtitleBuilder: (row) => '${_pretty(row['estado'])} · ${_pretty(row['prioridad'])}'),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _items(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
String _pretty(dynamic value) => _text(value, 'Sin estado').replaceAll('_', ' ');

class _SupportStat extends StatelessWidget {
  const _SupportStat(this.label, this.value, this.icon);
  final String label;
  final dynamic value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: 210, child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [CircleAvatar(child: Icon(icon)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${value ?? 0}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: Colors.white60))]))]))));
}

class _SupportList extends StatelessWidget {
  const _SupportList({required this.title, required this.icon, required this.items, required this.titleBuilder, required this.subtitleBuilder});
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) titleBuilder;
  final String Function(Map<String, dynamic>) subtitleBuilder;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8), if (items.isEmpty) const Text('Sin registros asignados.', style: TextStyle(color: Colors.white60)), for (final row in items) ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon), title: Text(titleBuilder(row)), subtitle: Text(subtitleBuilder(row)))])));
}
