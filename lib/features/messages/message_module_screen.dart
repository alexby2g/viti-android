import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../data/viti_repository.dart';

class MessageModuleScreen extends StatefulWidget {
  const MessageModuleScreen({required this.repository, required this.admin, super.key});

  final VitiRepository repository;
  final bool admin;

  @override
  State<MessageModuleScreen> createState() => _MessageModuleScreenState();
}

class _MessageModuleScreenState extends State<MessageModuleScreen> {
  final TextEditingController reply = TextEditingController();
  bool loading = true;
  bool loadingConversation = false;
  bool sending = false;
  String? error;
  List<Map<String, dynamic>> rows = const [];
  Map<String, dynamic>? current;
  int? selectedId;

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  @override
  void dispose() {
    reply.dispose();
    super.dispose();
  }

  Future<void> _loadInbox({bool selectFirst = false}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      rows = widget.admin ? await widget.repository.adminInbox() : await widget.repository.clientInbox();
      if (selectedId != null && !rows.any((row) => _int(row['id']) == selectedId)) {
        selectedId = null;
        current = null;
      }
      if (selectFirst && selectedId == null && rows.isNotEmpty) {
        await _select(_int(rows.first['id']));
      }
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No se pudo cargar el buzón.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _select(int id) async {
    if (id <= 0) return;
    setState(() {
      selectedId = id;
      loadingConversation = true;
      error = null;
    });
    try {
      current = widget.admin ? await widget.repository.adminConversation(id) : await widget.repository.clientConversation(id);
    } on ApiException catch (exception) {
      error = exception.message;
    } finally {
      if (mounted) setState(() => loadingConversation = false);
    }
  }

  Future<void> _sendText() async {
    final message = reply.text.trim();
    if (message.isEmpty || selectedId == null || sending) return;
    setState(() => sending = true);
    try {
      if (widget.admin) {
        await widget.repository.sendAdminMessage(selectedId!, message);
      } else {
        await widget.repository.sendClientMessage(selectedId!, message);
      }
      reply.clear();
      await _select(selectedId!);
      await _refreshInboxSilently();
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _attach() async {
    if (selectedId == null || sending) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.path == null || file.path!.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo acceder al archivo seleccionado.')));
      return;
    }
    final extension = (file.extension ?? '').toLowerCase();
    final image = const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension);
    final maxBytes = image ? 5 * 1024 * 1024 : 10 * 1024 * 1024;
    if (file.size > maxBytes) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(image ? 'La imagen no puede superar 5 MB.' : 'El documento no puede superar 10 MB.')));
      return;
    }

    setState(() => sending = true);
    try {
      final message = reply.text.trim();
      if (widget.admin) {
        if (image) {
          await widget.repository.sendAdminImage(selectedId!, filePath: file.path!, fileName: file.name, message: message);
        } else {
          await widget.repository.sendAdminDocument(selectedId!, filePath: file.path!, fileName: file.name, message: message);
        }
      } else {
        if (image) {
          await widget.repository.sendClientImage(selectedId!, filePath: file.path!, fileName: file.name, message: message);
        } else {
          await widget.repository.sendClientDocument(selectedId!, filePath: file.path!, fileName: file.name, message: message);
        }
      }
      reply.clear();
      await _select(selectedId!);
      await _refreshInboxSilently();
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _refreshInboxSilently() async {
    try {
      rows = widget.admin ? await widget.repository.adminInbox() : await widget.repository.clientInbox();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (loading && rows.isEmpty) return const Center(child: CircularProgressIndicator());
    if (error != null && rows.isEmpty) return _ChatError(message: error!, retry: _loadInbox);

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        if (desktop) {
          return Row(children: [SizedBox(width: 330, child: _inbox()), const VerticalDivider(width: 1), Expanded(child: _conversation())]);
        }
        return selectedId == null ? _inbox() : _conversation(mobile: true);
      },
    );
  }

  Widget _inbox() {
    return RefreshIndicator(
      onRefresh: _loadInbox,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.admin ? 'Atención VITI' : 'Mi buzón', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(widget.admin ? 'Conversaciones privadas autorizadas.' : 'Mensajes y documentos con AGR Studio.', style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 16),
          if (rows.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Aún no hay conversaciones.'))),
          for (final row in rows)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                selected: _int(row['id']) == selectedId,
                leading: const CircleAvatar(child: Icon(Icons.forum_outlined)),
                title: Text(_contactName(row)),
                subtitle: Text('${_text(row['asunto'], 'Conversación VITI')}\n${_preview(row)}', maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: _int(row['no_leidos']) > 0 ? Badge(label: Text('${row['no_leidos']}')) : const Icon(Icons.chevron_right),
                onTap: () => _select(_int(row['id'])),
              ),
            ),
        ],
      ),
    );
  }

  Widget _conversation({bool mobile = false}) {
    if (selectedId == null) return const Center(child: Text('Selecciona una conversación.'));
    if (loadingConversation && current == null) return const Center(child: CircularProgressIndicator());
    final conversation = current ?? <String, dynamic>{};
    final messages = _items(conversation['mensajes']);

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              if (mobile) IconButton(onPressed: () => setState(() { selectedId = null; current = null; }), icon: const Icon(Icons.arrow_back)),
              const CircleAvatar(child: Icon(Icons.support_agent)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_contactName(conversation), style: const TextStyle(fontWeight: FontWeight.w800)), Text(_text(conversation['asunto'], 'Conversación VITI'), style: const TextStyle(color: Colors.white60))])),
              IconButton(onPressed: loadingConversation ? null : () => _select(selectedId!), icon: const Icon(Icons.refresh)),
            ]),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('Todavía no hay mensajes en esta conversación.'))
              : ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _messageBubble(messages[index]),
                ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              IconButton(onPressed: sending ? null : _attach, tooltip: 'Adjuntar archivo', icon: const Icon(Icons.attach_file)),
              Expanded(child: TextField(controller: reply, minLines: 1, maxLines: 4, textInputAction: TextInputAction.newline, decoration: const InputDecoration(hintText: 'Escribe un mensaje…', border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: sending ? null : _sendText, icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _messageBubble(Map<String, dynamic> message) {
    final user = _map(message['usuario']);
    final role = _text(user['rol'], '');
    final mine = widget.admin ? role != 'cliente' : role == 'cliente';
    final fileName = _text(message['archivo_nombre'], '');
    final text = _text(message['mensaje'], '');
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (fileName.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.description_outlined, size: 18), const SizedBox(width: 7), Flexible(child: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w700)))]),
          if (fileName.isNotEmpty && text.isNotEmpty) const SizedBox(height: 6),
          if (text.isNotEmpty) Text(text),
          if (text.isEmpty && fileName.isEmpty) const Text('Adjunto', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 4),
          Text(_time(message['created_at']), style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ]),
      ),
    );
  }
}

class _ChatError extends StatelessWidget {
  const _ChatError({required this.message, required this.retry});
  final String message;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message), const SizedBox(height: 12), FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))]));
}

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
List<Map<String, dynamic>> _items(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
String _contactName(Map<String, dynamic> row) {
  final contact = _map(row['contacto']);
  final client = _map(row['cliente']);
  final company = _map(row['empresa']);
  return _text(contact['nombre'], _text(client['nombre'], _text(company['nombre_comercial'], 'Equipo VITI')));
}
String _preview(Map<String, dynamic> row) {
  final messages = _items(row['mensajes']);
  if (messages.isEmpty) return 'Sin mensajes todavía';
  final latest = messages.last;
  return _text(latest['mensaje'], _text(latest['archivo_nombre'], 'Adjunto'));
}
String _time(dynamic value) {
  final parsed = DateTime.tryParse('${value ?? ''}')?.toLocal();
  if (parsed == null) return '';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} · ${two(parsed.hour)}:${two(parsed.minute)}';
}
