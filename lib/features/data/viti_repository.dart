import '../../core/api/api_client.dart';

class VitiRepository {
  VitiRepository(this._api);

  final ApiClient _api;
  Map<String, dynamic>? _cachedClientProfile;

  Future<Map<String, dynamic>> clientProfile({bool refresh = false}) async {
    if (!refresh && _cachedClientProfile != null) return _cachedClientProfile!;
    final response = await _api.getJson('/mi/perfil');
    final profile = _map(response['data']);
    _cachedClientProfile = profile;
    await _syncClientCompany(profile);
    return profile;
  }

  Future<List<Map<String, dynamic>>> clientCompanies() async => _list((await clientProfile())['empresas']);
  Future<int?> activeCompanyId() => _api.selectedCompanyId();

  Future<void> selectCompany(int companyId) async {
    final companies = await clientCompanies();
    if (!companies.any((company) => _int(company['id']) == companyId)) throw const ApiException('No tienes acceso a esa empresa.');
    await _api.selectCompany(companyId);
  }

  Future<void> _ensureClientCompany() async {
    if (await _api.selectedCompanyId() != null) return;
    await clientProfile();
  }

  Future<void> _syncClientCompany(Map<String, dynamic> profile) async {
    final companies = _list(profile['empresas']);
    if (companies.isEmpty) {
      await _api.selectCompany(null);
      return;
    }
    final current = await _api.selectedCompanyId();
    if (current != null && companies.any((company) => _int(company['id']) == current)) return;
    await _api.selectCompany(_int(companies.first['id']));
  }

  Future<List<Map<String, dynamic>>> clientRequests() async => _list((await _api.getJson('/mi/solicitudes'))['data']);

  Future<Map<String, dynamic>> createClientRequest() async {
    final response = await _api.postJson('/mi/solicitud', const <String, dynamic>{});
    _cachedClientProfile = null;
    return _map(response['data']);
  }

  Future<Map<String, dynamic>?> clientProject() async {
    await _ensureClientCompany();
    final value = (await _api.getJson('/mi/proyecto'))['data'];
    return value is Map<String, dynamic> ? value : null;
  }

  Future<List<Map<String, dynamic>>> clientApps() async {
    await _ensureClientCompany();
    return _list((await _api.getJson('/mi/aplicaciones'))['data']);
  }

  Future<Map<String, dynamic>> clientBilling() async {
    await _ensureClientCompany();
    return _map((await _api.getJson('/mi/pagos'))['data']);
  }

  Future<void> sendProjectProof({required int projectId, required String amount, required String method, required String date, required String filePath, required String fileName}) async {
    await _ensureClientCompany();
    await _api.postMultipart('/mi/pagos/proyectos/$projectId/comprobante', fields: <String, String>{'monto': amount, 'metodo': method, 'fecha_pago': date}, fileField: 'comprobante', filePath: filePath, fileName: fileName);
  }

  Future<void> sendSubscriptionProof({required int subscriptionId, required String amount, required String method, required String date, required String filePath, required String fileName}) async {
    await _ensureClientCompany();
    await _api.postMultipart('/mi/pagos/suscripciones/$subscriptionId/comprobante', fields: <String, String>{'monto': amount, 'metodo': method, 'fecha_pago': date}, fileField: 'comprobante', filePath: filePath, fileName: fileName);
  }

  Future<List<Map<String, dynamic>>> clientInbox() async => _list((await _api.getJson('/mi/buzon'))['data']);
  Future<Map<String, dynamic>> clientConversation(int id) async => _map((await _api.getJson('/mi/buzon/$id'))['data']);
  Future<void> sendClientMessage(int id, String message) async => _api.postJson('/mi/buzon/$id/mensajes', <String, dynamic>{'mensaje': message});
  Future<void> sendClientImage(int id, {required String filePath, required String fileName, String message = ''}) async => _api.postMultipart('/mi/buzon/$id/mensajes', fields: message.trim().isEmpty ? const <String, String>{} : <String, String>{'mensaje': message.trim()}, fileField: 'archivo', filePath: filePath, fileName: fileName);
  Future<void> sendClientDocument(int id, {required String filePath, required String fileName, String message = ''}) async => _api.postMultipart('/mi/buzon/$id/documentos', fields: message.trim().isEmpty ? const <String, String>{} : <String, String>{'mensaje': message.trim()}, fileField: 'archivo', filePath: filePath, fileName: fileName);

  Future<Map<String, dynamic>> adminDashboard() => _api.getJson('/dashboard');
  Future<List<Map<String, dynamic>>> adminCompanies() async => _list((await _api.getJson('/empresas?per_page=100'))['data']);
  Future<List<Map<String, dynamic>>> adminRequests() async => _list((await _api.getJson('/solicitudes?per_page=100'))['data']);
  Future<List<Map<String, dynamic>>> adminProjects() async => _list((await _api.getJson('/proyectos?per_page=100'))['data']);
  Future<List<Map<String, dynamic>>> adminApps() async => _list((await _api.getJson('/aplicaciones?per_page=100'))['data']);
  Future<Map<String, dynamic>> adminCompany(int id) async => _map((await _api.getJson('/empresas/$id'))['data']);
  Future<Map<String, dynamic>> adminRequest(int id) async => _map((await _api.getJson('/solicitudes/$id'))['data']);
  Future<Map<String, dynamic>> adminProject(int id) async => _map((await _api.getJson('/proyectos/$id'))['data']);
  Future<Map<String, dynamic>> adminApp(int id) async => _map((await _api.getJson('/aplicaciones/$id'))['data']);

  Future<Map<String, dynamic>> addProjectProgress({
    required int projectId,
    required String phase,
    required String title,
    required num progress,
    String? area,
    String? description,
    bool visibleClient = true,
  }) async {
    final response = await _api.postJson('/proyectos/$projectId/avances', <String, dynamic>{
      'fase': phase,
      'titulo': title,
      'progreso': progress.toInt(),
      'visible_cliente': visibleClient,
      if (area != null && area.isNotEmpty) 'area': area,
      if (description != null && description.trim().isNotEmpty) 'descripcion': description.trim(),
    });
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> adminBilling() async => _map((await _api.getJson('/pagos'))['data']);
  Future<List<Map<String, dynamic>>> adminInbox() async => _list((await _api.getJson('/buzon?per_page=100'))['data']);
  Future<Map<String, dynamic>> adminConversation(int id) async => _map((await _api.getJson('/buzon/$id'))['data']);
  Future<void> sendAdminMessage(int id, String message) async => _api.postJson('/buzon/$id/mensajes', <String, dynamic>{'mensaje': message});
  Future<void> sendAdminImage(int id, {required String filePath, required String fileName, String message = ''}) async => _api.postMultipart('/buzon/$id/mensajes', fields: message.trim().isEmpty ? const <String, String>{} : <String, String>{'mensaje': message.trim()}, fileField: 'archivo', filePath: filePath, fileName: fileName);
  Future<void> sendAdminDocument(int id, {required String filePath, required String fileName, String message = ''}) async => _api.postMultipart('/buzon/$id/documentos', fields: message.trim().isEmpty ? const <String, String>{} : <String, String>{'mensaje': message.trim()}, fileField: 'archivo', filePath: filePath, fileName: fileName);

  Future<Map<String, dynamic>> supportSummary() async => _map((await _api.getJson('/soporte/resumen'))['data']);
  Future<List<Map<String, dynamic>>> supportInbox() async => _list((await _api.getJson('/soporte/buzon?per_page=100'))['data']);
  Future<Map<String, dynamic>> supportConversation(int id) async => _map((await _api.getJson('/soporte/buzon/$id'))['data']);
  Future<void> sendSupportMessage(int id, String message) async => _api.postJson('/soporte/buzon/$id/mensajes', <String, dynamic>{'mensaje': message});
  Future<void> sendSupportFile(int id, {required String filePath, required String fileName, String message = ''}) async => _api.postMultipart('/soporte/buzon/$id/mensajes', fields: message.trim().isEmpty ? const <String, String>{} : <String, String>{'mensaje': message.trim()}, fileField: 'archivo', filePath: filePath, fileName: fileName);

  String _businessAppBase(String key) {
    switch (key) {
      case 'servicio-tecnico':
        return '/mi/apps/servicio-tecnico';
      case 'electrofrio':
        return '/mi/apps/electrofrio';
      default:
        throw const ApiException('Esta VITI App todavía no tiene integración nativa.');
    }
  }

  Future<Map<String, dynamic>> businessAppSummary(String key) async {
    await _ensureClientCompany();
    return _map((await _api.getJson('${_businessAppBase(key)}/resumen'))['data']);
  }

  Future<List<Map<String, dynamic>>> businessAppList(String key, String resource) async {
    await _ensureClientCompany();
    return _list((await _api.getJson('${_businessAppBase(key)}/$resource'))['data']);
  }

  Future<Map<String, dynamic>> createTechnicalClient({required String name, String? phone, String? whatsapp, String? address, String? notes}) async {
    await _ensureClientCompany();
    final response = await _api.postJson('/mi/apps/servicio-tecnico/clientes', <String, dynamic>{
      'nombre': name.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'telefono': phone.trim(),
      if (whatsapp != null && whatsapp.trim().isNotEmpty) 'whatsapp': whatsapp.trim(),
      if (address != null && address.trim().isNotEmpty) 'direccion': address.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'observaciones': notes.trim(),
      'activo': true,
    });
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> createTechnicalOrder({
    required int clientId,
    int? equipmentId,
    int? technicianId,
    required String receptionDate,
    String? scheduledDate,
    String? scheduledTime,
    required String priority,
    required String reportedProblem,
    double? serviceCost,
  }) async {
    await _ensureClientCompany();
    final response = await _api.postJson('/mi/apps/servicio-tecnico/ordenes', <String, dynamic>{
      'cliente_id': clientId,
      if (equipmentId != null && equipmentId > 0) 'equipo_id': equipmentId,
      if (technicianId != null && technicianId > 0) 'tecnico_id': technicianId,
      'fecha_recepcion': receptionDate,
      if (scheduledDate != null && scheduledDate.isNotEmpty) 'fecha_programada': scheduledDate,
      if (scheduledTime != null && scheduledTime.isNotEmpty) 'hora_programada': scheduledTime,
      'prioridad': priority,
      'problema_reportado': reportedProblem.trim(),
      if (serviceCost != null) 'costo_servicio': serviceCost,
      'descuento': 0,
    });
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> registerTechnicalPayment({required int orderId, required double amount, required String method, String? reference}) async {
    await _ensureClientCompany();
    final response = await _api.postJson('/mi/apps/servicio-tecnico/ordenes/$orderId/pagos', <String, dynamic>{
      'monto': amount,
      'metodo': method,
      if (reference != null && reference.trim().isNotEmpty) 'referencia': reference.trim(),
    });
    return _map(response['data']);
  }

  static Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
  static List<Map<String, dynamic>> _list(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
  static int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
}
