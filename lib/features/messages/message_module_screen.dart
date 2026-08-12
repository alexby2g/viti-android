import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/ui/viti_ui.dart';
import '../data/viti_repository.dart';

class MessageModuleScreen extends StatefulWidget {
  const MessageModuleScreen({required this.repository, this.admin = false, this.support = false, super.key});

  final VitiRepository repository;
  final bool admin;
  final bool support;

  @override
  State<MessageModuleScreen> createState() => _MessageModuleScreenState();
}

class _MessageModuleScreenState extends State<MessageModuleScreen> {
  final TextEditingController reply = TextEditingController();
  final TextEditingController search = TextEditingController();
  bool loading = true;
  bool loadingConversation = false;
  bool sending = false;
  String? error;
  String query = '';
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
    search.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchInbox() {
    if (widget.support) return widget.repository.supportInbox();
    return widget.admin ? widget.repository.adminInbox() : widget.repository.clientInbox();
  }

  Future<Map<String, dynamic>> _fetchConversation(int id) {
    if (widget.support) return widget.repository.supportConversation(id);
    return widget.admin ? widget.repository.adminConversation(id) : widget.repository.clientConversation(id);
  }

  Future<void> _loadInbox() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      rows = await _fetchInbox();
      rows = [...rows]..sort((a, b) => _latestDate(b).compareTo(_latestDate(a)));
      if (selectedId != null && !rows.any((row) => _int(row['id']) == selectedId)) {
        selectedId = null;
        current = null;
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
      current = await _fetchConversation(id);
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
      if (widget.support) {
        await widget.repository.sendSupportMessage(selectedId!, message);
      } else if (widget.admin) {
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
    final result = await FilePicker.pickFiles(type: FileType.custom, allowMultiple: false, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt']);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.path == null || file.path!.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo acceder al archivo seleccionado.')));
      return;
    }
    final extension = (file.extension ?? '').toLowerCase();
    final image = const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension);
    final maxBytes = widget.support ? 10 * 1024 * 1024 : image ? 5 * 1024 * 1024 : 10 * 1024 * 1024;
    if (file.size > maxBytes) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(maxBytes == 5 * 1024 * 1024 ? 'La imagen no puede superar 5 MB.' : 'El archivo no puede superar 10 MB.')));
      return;
    }

    setState(() => sending = true);
    try {
      final message = reply.text.trim();
      if (widget.support) {
        await widget.repository.sendSupportFile(selectedId!, filePath: file.path!, fileName: file.name, message: message);
      } else if (widget.admin) {
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
      rows = await _fetchInbox();
      rows = [...rows]..sort((a, b) => _latestDate(b).compareTo(_latestDate(a)));
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (loading && rows.isEmpty) return const Center(child: CircularProgressIndicator());
    if (error != null && rows.isEmpty) return Center(child: VitiEmptyState(title: 'No se pudo cargar el buzón', message: error!, icon: Icons.cloud_off, action: FilledButton.icon(onPressed: _loadInbox, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))));

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 940;
        if (desktop) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Row(
              children: [
                SizedBox(width: 350, child: VitiPanel(padding: EdgeInsets.zero, child: _inbox())),
                const SizedBox(width: 12),
                Expanded(child: VitiPanel(padding: EdgeInsets.zero, child: _conversation())),
              ],
            ),
          );
        }
        return selectedId == null ? _inbox() : _conversation(mobile: true);
      },
    );
  }

  String get _title => widget.support ? 'Mensajes asignados' : widget.admin ? 'Atención VITI' : 'Mi buzón';
  String get _subtitle => widget.support ? 'Solo conversaciones delegadas a tu cuenta.' : widget.admin ? 'Conversaciones privadas autorizadas.' : 'Mensajes y documentos con AGR Studio.';

  Widget _inbox() {
    final visible = rows.where((row) {
      if (query.trim().isEmpty) return true;
      final haystack = '${_contactName(row)} ${row['asunto']} ${_preview(row)}'.toLowerCase();
      return haystack.contains(query.toLowerCase().trim());
    }).toList(growable: false);
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _loadInbox,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(_title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(_subtitle, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 14),
          VitiSearchField(controller: search, hint: 'Buscar conversación…', onChanged: (value) => setState(() => query = value), width: double.infinity),
          const SizedBox(height: 12),
          if (visible.isEmpty) const VitiEmptyState(title: 'Sin conversaciones', message: 'Las conversaciones disponibles aparecerán aquí.', icon: Icons.forum_outlined),
          for (final row in visible) _conversationRow(row),
        ],
      ),
    );
  }

  Widget _conversationRow(Map<String, dynamic> row) {
    final colors = Theme.of(context).colorScheme;
    final selected = _int(row['id']) == selectedId;
    final unread = _int(row['no_leidos']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: selected ? colors.primaryContainer.withValues(alpha: .45) : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => _select(_int(row['id'])),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: selected ? colors.primary.withValues(alpha: .5) : colors.outlineVariant.withValues(alpha: .6))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 19, backgroundColor: selected ? colors.primary : colors.surfaceContainerHighest, foregroundColor: selected ? colors.onPrimary : colors.onSurfaceVariant, child: Text(_initial(_contactName(row)), style: const TextStyle(fontWeight: FontWeight.w900))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(_contactName(row), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: unread > 0 ? FontWeight.w900 : FontWeight.w750))), if (unread > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(99)), child: Text('$unread', style: TextStyle(fontSize: 10, color: colors.onPrimary, fontWeight: FontWeight.w900)))]), const SizedBox(height: 3), Text(_preview(row), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant, height: 1.25)), const SizedBox(height: 5), Text(_time(_latestDate(row)), style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant))])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _conversation({bool mobile = false}) {
    final colors = Theme.of(context).colorScheme;
    if (selectedId == null) return const VitiEmptyState(title: 'Selecciona una conversación', message: 'Los mensajes aparecerán aquí sin cubrir tu bandeja.', icon: Icons.chat_bubble_outline);
    if (loadingConversation && current == null) return const Center(child: CircularProgressIndicator());
    final conversation = current ?? <String, dynamic>{};
    final messages = [..._items(conversation['mensajes'])]..sort((a, b) => _messageDate(a).compareTo(_messageDate(b)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (mobile) IconButton(onPressed: () => setState(() {selectedId = null; current = null;}), icon: const Icon(Icons.arrow_back)),
              CircleAvatar(radius: 20, backgroundColor: colors.primaryContainer, child: const Icon(Icons.support_agent)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_contactName(conversation), style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(_text(conversation['asunto'], 'Conversación VITI'), style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant))])),
              VitiStatusBadge(widget.support ? 'Asignada' : 'Privada', tone: VitiTone.success),
              const SizedBox(width: 6),
              IconButton(onPressed: loadingConversation ? null : () => _select(selectedId!), tooltip: 'Actualizar', icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: messages.isEmpty
              ? const VitiEmptyState(title: 'Todavía no hay mensajes', message: 'Escribe el primer mensaje para iniciar la conversación.', icon: Icons.chat_outlined)
              : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 18, 16, 12), itemCount: messages.length, itemBuilder: (context, index) => _messageBubble(messages[index])),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton.filledTonal(onPressed: sending ? null : _attach, tooltip: 'Adjuntar imagen o documento', icon: const Icon(Icons.attach_file)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: reply, minLines: 1, maxLines: 5, textInputAction: TextInputAction.newline, decoration: const InputDecoration(hintText: 'Responder al cliente…'))),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: sending ? null : _sendText, tooltip: 'Enviar', icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _messageBubble(Map<String, dynamic> message) {
    final colors = Theme.of(context).colorScheme;
    final user = _map(message['usuario']);
    final role = _text(user['rol'], '');
    final mine = message['es_mio'] == true || (widget.admin ? role != 'cliente' : widget.support ? role == 'soporte' : role == 'cliente');
    final fileName = _text(message['archivo_nombre'], '');
    final text = _text(message['mensaje'], '');
    final bubbleColor = mine ? colors.primaryContainer : colors.surfaceContainerHighest;
    final borderColor = mine ? colors.primary.withValues(alpha: .20) : colors.outlineVariant.withValues(alpha: .72);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(mine ? 16 : 5), bottomRight: Radius.circular(mine ? 5 : 16)), border: Border.all(color: borderColor)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fileName.isNotEmpty) Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: colors.surface.withValues(alpha: .55), borderRadius: BorderRadius.circular(10)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.description_outlined, size: 18), const SizedBox(width: 7), Flexible(child: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w800)))])),
            if (fileName.isNotEmpty && text.isNotEmpty) const SizedBox(height: 7),
            if (text.isNotEmpty) Text(text, style: const TextStyle(height: 1.35)),
            if (text.isEmpty && fileName.isEmpty) Text('Adjunto', style: TextStyle(color: colors.onSurfaceVariant)),
            const SizedBox(height: 5),
            Text(_time(message['created_at']), style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
List<Map<String, dynamic>> _items(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
String _text(dynamic value, String fallback) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
String _initial(String text) => text.trim().isEmpty ? 'V' : text.trim().characters.first.toUpperCase();
String _contactName(Map<String, dynamic> row) {
  final contact = _map(row['contacto']);
  final client = _map(row['cliente']);
  final company = _map(row['empresa']);
  return _text(contact['nombre'], _text(client['nombre'], _text(company['nombre_comercial'], 'Equipo VITI')));
}
String _preview(Map<String, dynamic> row) {
  final messages = [..._items(row['mensajes'])]..sort((a, b) => _messageDate(a).compareTo(_messageDate(b)));
  if (messages.isEmpty) return 'Sin mensajes todavía';
  final latest = messages.last;
  return _text(latest['mensaje'], _text(latest['archivo_nombre'], 'Adjunto'));
}
DateTime _messageDate(Map<String, dynamic> message) => DateTime.tryParse('${message['created_at'] ?? message['enviado_at'] ?? ''}')?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
DateTime _latestDate(Map<String, dynamic> row) {
  final messages = _items(row['mensajes']);
  if (messages.isNotEmpty) return messages.map(_messageDate).fold<DateTime>(DateTime.fromMillisecondsSinceEpoch(0), (latest, value) => value.isAfter(latest) ? value : latest);
  return DateTime.tryParse('${row['ultimo_mensaje_at'] ?? row['updated_at'] ?? ''}')?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
}
String _time(dynamic value) {
  final DateTime? parsed = value is DateTime ? value : DateTime.tryParse('${value ?? ''}')?.toLocal();
  if (parsed == null || parsed.millisecondsSinceEpoch == 0) return '';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)} · ${two(parsed.hour)}:${two(parsed.minute)}';
}
