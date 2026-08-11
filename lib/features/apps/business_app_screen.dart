import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../data/viti_repository.dart';

class BusinessAppScreen extends StatefulWidget {
  const BusinessAppScreen({
    required this.repository,
    required this.appKey,
    required this.appName,
    super.key,
  });

  final VitiRepository repository;
  final String appKey;
  final String appName;

  @override
  State<BusinessAppScreen> createState() => _BusinessAppScreenState();
}

class _BusinessAppScreenState extends State<BusinessAppScreen> {
  String module = 'inicio';
  bool loading = true;
  String? error;
  dynamic data;

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
      data = module == 'inicio'
          ? await widget.repository.businessAppSummary(widget.appKey)
          : await widget.repository.businessAppList(widget.appKey, module);
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No se pudo cargar este módulo.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(widget.appName),
        actions: [IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Center(child: Text('VITI App · $module')),
    );
  }
}
