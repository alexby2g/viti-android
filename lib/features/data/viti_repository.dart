import '../../core/api/api_client.dart';

class VitiRepository {
  VitiRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> clientProfile() async {
    final response = await _api.getJson('/mi/perfil');
    return _map(response['data']);
  }

  Future<List<Map<String, dynamic>>> clientRequests() async {
    final response = await _api.getJson('/mi/solicitudes');
    return _list(response['data']);
  }

  Future<Map<String, dynamic>> createClientRequest() async {
    final response = await _api.postJson('/mi/solicitud', const <String, dynamic>{});
    return _map(response['data']);
  }

  Future<Map<String, dynamic>?> clientProject() async {
    final response = await _api.getJson('/mi/proyecto');
    final value = response['data'];
    return value is Map<String, dynamic> ? value : null;
  }

  Future<List<Map<String, dynamic>>> clientApps() async {
    final response = await _api.getJson('/mi/aplicaciones');
    return _list(response['data']);
  }

  Future<Map<String, dynamic>> clientBilling() async {
    final response = await _api.getJson('/mi/pagos');
    return _map(response['data']);
  }

  Future<void> sendProjectProof({required int projectId, required String amount, required String method, required String date, required String filePath, required String fileName}) async {
    await _api.postMultipart(
      '/mi/pagos/proyectos/$projectId/comprobante',
      fields: <String, String>{'monto': amount, 'metodo': method, 'fecha_pago': date},
      fileField: 'comprobante',
      filePath: filePath,
      fileName: fileName,
    );
  }

  Future<void> sendSubscriptionProof({required int subscriptionId, required String amount, required String method, required String date, required String filePath, required String fileName}) async {
    await _api.postMultipart(
      '/mi/pagos/suscripciones/$subscriptionId/comprobante',
      fields: <String, String>{'monto': amount, 'metodo': method, 'fecha_pago': date},
      fileField: 'comprobante',
      filePath: filePath,
      fileName: fileName,
    );
  }

  Future<List<Map<String, dynamic>>> clientInbox() async {
    final response = await _api.getJson('/mi/buzon');
    return _list(response['data']);
  }

  Future<Map<String, dynamic>> clientConversation(int id) async {
    final response = await _api.getJson('/mi/buzon/$id');
    return _map(response['data']);
  }

  Future<void> sendClientMessage(int id, String message) async {
    await _api.postJson('/mi/buzon/$id/mensajes', <String, dynamic>{'mensaje': message});
  }

  Future<void> sendClientDocument(int id, {required String filePath, required String fileName, String message = ''}) async {
    await _api.postMultipart(
      '/mi/buzon/$id/documentos',
      fields: message.trim().isEmpty ? const <String, String>{} : <String, String>{'mensaje': message.trim()},
      fileField: 'archivo',
      filePath: filePath,
      fileName: fileName,
    );
  }

  Future<Map<String, dynamic>> adminDashboard() => _api.getJson('/dashboard');

  Future<List<Map<String, dynamic>>> adminCompanies() async {
    final response = await _api.getJson('/empresas?per_page=100');
    return _list(response['data']);
  }

  Future<List<Map<String, dynamic>>> adminRequests() async {
    final response = await _api.getJson('/solicitudes?per_page=100');
    return _list(response['data']);
  }

  Future<List<Map<String, dynamic>>> adminProjects() async {
    final response = await _api.getJson('/proyectos?per_page=100');
    return _list(response['data']);
  }

  Future<List<Map<String, dynamic>>> adminApps() async {
    final response = await _api.getJson('/aplicaciones?per_page=100');
    return _list(response['data']);
  }

  Future<Map<String, dynamic>> adminBilling() async {
    final response = await _api.getJson('/pagos');
    return _map(response['data']);
  }

  Future<List<Map<String, dynamic>>> adminInbox() async {
    final response = await _api.getJson('/buzon?per_page=100');
    return _list(response['data']);
  }

  Future<Map<String, dynamic>> adminConversation(int id) async {
    final response = await _api.getJson('/buzon/$id');
    return _map(response['data']);
  }

  Future<void> sendAdminMessage(int id, String message) async {
    await _api.postJson('/buzon/$id/mensajes', <String, dynamic>{'mensaje': message});
  }

  Future<void> sendAdminDocument(int id, {required String filePath, required String fileName, String message = ''}) async {
    await _api.postMultipart(
      '/buzon/$id/documentos',
      fields: message.trim().isEmpty ? const <String, String>{} : <String, String>{'mensaje': message.trim()},
      fileField: 'archivo',
      filePath: filePath,
      fileName: fileName,
    );
  }

  Future<Map<String, dynamic>> supportSummary() async {
    final response = await _api.getJson('/soporte/resumen');
    return _map(response['data']);
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}
