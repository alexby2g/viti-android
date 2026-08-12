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
    if (!companies.any((company) => _int(company['id']) == companyId)) {
      throw const ApiException('No tienes acceso a esa empresa.');
    }
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

  Future<Map<String, dynamic>> updateAdminAppCycle({required int appId, required String environment, required String state}) async {
    final response = await _api.postJson('/aplicaciones/$appId/ciclo', <String, dynamic>{'entorno': environment, 'estado': state});
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> deliverAdminApp(int appId) async => _map((await _api.postJson('/aplicaciones/$appId/entregar', const <String, dynamic>{}))['data']);
  Future<Map<String, dynamic>> revokeAdminApp(int appId) async => _map((await _api.postJson('/aplicaciones/$appId/revocar', const <String, dynamic>{}))['data']);

  Future<Map<String, dynamic>> adminBilling() async => _map((await _api.getJson('/pagos'))['data']);

  Future<Map<String, dynamic>> confirmProjectProof(int paymentId) async =>
      _map((await _api.postJson('/pagos/proyecto-pagos/$paymentId/confirmar', const <String, dynamic>{}))['data']);

  Future<Map<String, dynamic>> rejectProjectProof(int paymentId, String reason) async =>
      _map((await _api.postJson('/pagos/proyecto-pagos/$paymentId/rechazar', <String, dynamic>{'motivo': reason.trim()}))['data']);

  Future<Map<String, dynamic>> confirmSubscriptionProof(int paymentId) async =>
      _map((await _api.postJson('/pagos/suscripcion-pagos/$paymentId/confirmar', const <String, dynamic>{}))['data']);

  Future<Map<String, dynamic>> rejectSubscriptionProof(int paymentId, String reason) async =>
      _map((await _api.postJson('/pagos/suscripcion-pagos/$paymentId/rechazar', <String, dynamic>{'motivo': reason.trim()}))['data']);

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

  String _businessAppBase(String key, {required bool admin}) {
    final prefix = admin ? '/apps' : '/mi/apps';
    switch (key) {
      case 'servicio-tecnico':
        return '$prefix/servicio-tecnico';
      case 'electrofrio':
        return '$prefix/electrofrio';
      default:
        throw const ApiException('Esta VITI App todavía no tiene integración nativa.');
    }
  }

  Future<void> _prepareBusinessContext({required bool admin, int? companyId}) async {
    if (admin) {
      if (companyId == null || companyId <= 0) throw const ApiException('Selecciona la empresa que quieres administrar.');
      return;
    }
    await _ensureClientCompany();
  }

  Future<Map<String, dynamic>> businessAppState(String key, {bool admin = false, int? companyId}) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    return _map((await _api.getJson('${_businessAppBase(key, admin: admin)}/estado', companyId: companyId))['data']);
  }

  Future<Map<String, dynamic>> businessAppSummary(String key, {bool admin = false, int? companyId}) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    return _map((await _api.getJson('${_businessAppBase(key, admin: admin)}/resumen', companyId: companyId))['data']);
  }

  Future<List<Map<String, dynamic>>> businessAppList(String key, String resource, {bool admin = false, int? companyId}) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    return _list((await _api.getJson('${_businessAppBase(key, admin: admin)}/$resource', companyId: companyId))['data']);
  }

  Future<Map<String, dynamic>> technicalReferences({bool admin = false, int? companyId}) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    return _map((await _api.getJson('${_businessAppBase('servicio-tecnico', admin: admin)}/referencias', companyId: companyId))['data']);
  }

  Future<List<Map<String, dynamic>>> technicalBusinessUsers({bool admin = false, int? companyId}) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    return _list((await _api.getJson('${_businessAppBase('servicio-tecnico', admin: admin)}/usuarios-negocio', companyId: companyId))['data']);
  }

  Future<Map<String, dynamic>> createTechnicalClient({
    required String name,
    String? phone,
    String? whatsapp,
    String? address,
    String? notes,
    bool active = true,
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.postJson('${_businessAppBase('servicio-tecnico', admin: admin)}/clientes', <String, dynamic>{
      'nombre': name.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'telefono': phone.trim(),
      if (whatsapp != null && whatsapp.trim().isNotEmpty) 'whatsapp': whatsapp.trim(),
      if (address != null && address.trim().isNotEmpty) 'direccion': address.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'observaciones': notes.trim(),
      'activo': active,
    }, companyId: companyId);
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> updateTechnicalClient({
    required int id,
    required String name,
    String? phone,
    String? whatsapp,
    String? address,
    String? notes,
    bool active = true,
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.putJson('${_businessAppBase('servicio-tecnico', admin: admin)}/clientes/$id', <String, dynamic>{
      'nombre': name.trim(),
      'telefono': _nullableText(phone),
      'whatsapp': _nullableText(whatsapp),
      'direccion': _nullableText(address),
      'observaciones': _nullableText(notes),
      'activo': active,
    }, companyId: companyId);
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> createTechnicalEquipment({
    required int clientId,
    required String type,
    String? brand,
    String? model,
    String? serial,
    String? specifications,
    String? accessories,
    String? receptionState,
    String? notes,
    bool active = true,
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.postJson('${_businessAppBase('servicio-tecnico', admin: admin)}/equipos', <String, dynamic>{
      'cliente_id': clientId,
      'tipo': type.trim(),
      'marca': _nullableText(brand),
      'modelo': _nullableText(model),
      'serie': _nullableText(serial),
      'especificaciones': _nullableText(specifications),
      'accesorios_recibidos': _nullableText(accessories),
      'estado_recepcion': _nullableText(receptionState),
      'observaciones': _nullableText(notes),
      'activo': active,
    }, companyId: companyId);
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> updateTechnicalEquipment({
    required int id,
    required int clientId,
    required String type,
    String? brand,
    String? model,
    String? serial,
    String? specifications,
    String? accessories,
    String? receptionState,
    String? notes,
    bool active = true,
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.putJson('${_businessAppBase('servicio-tecnico', admin: admin)}/equipos/$id', <String, dynamic>{
      'cliente_id': clientId,
      'tipo': type.trim(),
      'marca': _nullableText(brand),
      'modelo': _nullableText(model),
      'serie': _nullableText(serial),
      'especificaciones': _nullableText(specifications),
      'accesorios_recibidos': _nullableText(accessories),
      'estado_recepcion': _nullableText(receptionState),
      'observaciones': _nullableText(notes),
      'activo': active,
    }, companyId: companyId);
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> createTechnicalTechnician({
    int? userId,
    required String name,
    String? phone,
    String? specialty,
    bool active = true,
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.postJson('${_businessAppBase('servicio-tecnico', admin: admin)}/tecnicos', <String, dynamic>{
      'usuario_id': userId,
      'nombre': name.trim(),
      'telefono': _nullableText(phone),
      'especialidad': _nullableText(specialty),
      'activo': active,
    }, companyId: companyId);
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> updateTechnicalTechnician({
    required int id,
    int? userId,
    required String name,
    String? phone,
    String? specialty,
    bool active = true,
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.putJson('${_businessAppBase('servicio-tecnico', admin: admin)}/tecnicos/$id', <String, dynamic>{
      'usuario_id': userId,
      'nombre': name.trim(),
      'telefono': _nullableText(phone),
      'especialidad': _nullableText(specialty),
      'activo': active,
    }, companyId: companyId);
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
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.postJson('${_businessAppBase('servicio-tecnico', admin: admin)}/ordenes', <String, dynamic>{
      'cliente_id': clientId,
      'equipo_id': equipmentId,
      'tecnico_id': technicianId,
      'fecha_recepcion': receptionDate,
      'fecha_programada': _nullableText(scheduledDate),
      'hora_programada': _nullableText(scheduledTime),
      'prioridad': priority,
      'problema_reportado': reportedProblem.trim(),
      'costo_servicio': serviceCost,
      'descuento': 0,
    }, companyId: companyId);
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> updateTechnicalOrder({
    required int id,
    required int clientId,
    int? equipmentId,
    int? technicianId,
    required String receptionDate,
    String? scheduledDate,
    String? scheduledTime,
    required String priority,
    required String reportedProblem,
    String? diagnosis,
    String? proposal,
    String? workDone,
    String? recommendations,
    double? serviceCost,
    double? discount,
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.putJson('${_businessAppBase('servicio-tecnico', admin: admin)}/ordenes/$id', <String, dynamic>{
      'cliente_id': clientId,
      'equipo_id': equipmentId,
      'tecnico_id': technicianId,
      'fecha_recepcion': receptionDate,
      'fecha_programada': _nullableText(scheduledDate),
      'hora_programada': _nullableText(scheduledTime),
      'prioridad': priority,
      'problema_reportado': reportedProblem.trim(),
      'diagnostico': _nullableText(diagnosis),
      'propuesta': _nullableText(proposal),
      'trabajo_realizado': _nullableText(workDone),
      'recomendaciones': _nullableText(recommendations),
      'costo_servicio': serviceCost,
      'descuento': discount,
    }, companyId: companyId);
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> decideTechnicalOrder({
    required int orderId,
    required String decision,
    String? rejectionReason,
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.postJson('${_businessAppBase('servicio-tecnico', admin: admin)}/ordenes/$orderId/decision', <String, dynamic>{
      'decision': decision,
      if (rejectionReason != null && rejectionReason.trim().isNotEmpty) 'motivo_rechazo': rejectionReason.trim(),
    }, companyId: companyId);
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> finishTechnicalWork({
    required int orderId,
    required String workDone,
    String? recommendations,
    int warrantyDays = 0,
    String? warrantyTerms,
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.postJson('${_businessAppBase('servicio-tecnico', admin: admin)}/ordenes/$orderId/finalizar-trabajo', <String, dynamic>{
      'trabajo_realizado': workDone.trim(),
      'recomendaciones': _nullableText(recommendations),
      'garantia_dias': warrantyDays,
      'condiciones_garantia': _nullableText(warrantyTerms),
    }, companyId: companyId);
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> changeTechnicalOrderState({
    required int orderId,
    required String state,
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.postJson('${_businessAppBase('servicio-tecnico', admin: admin)}/ordenes/$orderId/estado', <String, dynamic>{'estado': state}, companyId: companyId);
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> registerTechnicalPayment({
    required int orderId,
    required double amount,
    required String method,
    String? reference,
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.postJson('${_businessAppBase('servicio-tecnico', admin: admin)}/ordenes/$orderId/pagos', <String, dynamic>{
      'monto': amount,
      'metodo': method,
      if (reference != null && reference.trim().isNotEmpty) 'referencia': reference.trim(),
    }, companyId: companyId);
    return _map(response['data']);
  }

  Future<Map<String, dynamic>> uploadTechnicalEvidence({
    required int orderId,
    required String stage,
    required String filePath,
    required String fileName,
    String? description,
    bool admin = false,
    int? companyId,
  }) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    final response = await _api.postMultipart(
      '${_businessAppBase('servicio-tecnico', admin: admin)}/ordenes/$orderId/evidencias',
      fields: <String, String>{
        'etapa': stage,
        if (description != null && description.trim().isNotEmpty) 'descripcion': description.trim(),
      },
      fileField: 'archivo',
      filePath: filePath,
      fileName: fileName,
      companyId: companyId,
    );
    return _map(response['data']);
  }

  Future<void> deleteTechnicalClient(int id, {bool admin = false, int? companyId}) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    await _api.deleteJson('${_businessAppBase('servicio-tecnico', admin: admin)}/clientes/$id', companyId: companyId);
  }

  Future<void> deleteTechnicalEquipment(int id, {bool admin = false, int? companyId}) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    await _api.deleteJson('${_businessAppBase('servicio-tecnico', admin: admin)}/equipos/$id', companyId: companyId);
  }

  Future<void> deleteTechnicalTechnician(int id, {bool admin = false, int? companyId}) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    await _api.deleteJson('${_businessAppBase('servicio-tecnico', admin: admin)}/tecnicos/$id', companyId: companyId);
  }

  Future<void> deleteTechnicalOrder(int id, {bool admin = false, int? companyId}) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    await _api.deleteJson('${_businessAppBase('servicio-tecnico', admin: admin)}/ordenes/$id', companyId: companyId);
  }

  Future<void> deleteTechnicalEvidence(int id, {bool admin = false, int? companyId}) async {
    await _prepareBusinessContext(admin: admin, companyId: companyId);
    await _api.deleteJson('${_businessAppBase('servicio-tecnico', admin: admin)}/evidencias/$id', companyId: companyId);
  }

  static dynamic _nullableText(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
  static List<Map<String, dynamic>> _list(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
  static int _int(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
}
