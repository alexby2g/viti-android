import '../../core/api/api_client.dart';
import '../../core/storage/secure_session_store.dart';

class ElectrofrioRepository {
  ElectrofrioRepository({required this.adminMode, this.companyId}) : _api = ApiClient(SecureSessionStore());

  final bool adminMode;
  final int? companyId;
  final ApiClient _api;

  String get _base => adminMode ? '/apps/electrofrio' : '/mi/apps/electrofrio';

  Future<Map<String, dynamic>> state() async {
    if (adminMode) return <String, dynamic>{'rol': 'administrador_viti'};
    return _map((await _api.getJson('$_base/estado', companyId: companyId))['data']);
  }

  Future<Map<String, dynamic>> summary() async => _map((await _api.getJson('$_base/resumen', companyId: companyId))['data']);
  Future<List<Map<String, dynamic>>> list(String resource) async => _list((await _api.getJson('$_base/$resource', companyId: companyId))['data']);
  Future<List<Map<String, dynamic>>> businessUsers() async => list('usuarios-negocio');

  Future<Map<String, dynamic>> create(String resource, Map<String, dynamic> body) async =>
      _map((await _api.postJson('$_base/$resource', body, companyId: companyId))['data']);

  Future<Map<String, dynamic>> update(String resource, int id, Map<String, dynamic> body) async =>
      _map((await _api.putJson('$_base/$resource/$id', body, companyId: companyId))['data']);

  Future<void> delete(String resource, int id) async => _api.deleteJson('$_base/$resource/$id', companyId: companyId);

  Future<Map<String, dynamic>> decideOrder(int orderId, String decision, {String? reason}) async =>
      _map((await _api.postJson('$_base/ordenes/$orderId/decision', <String, dynamic>{
        'decision': decision,
        if (reason != null && reason.trim().isNotEmpty) 'motivo_rechazo': reason.trim(),
      }, companyId: companyId))['data']);

  Future<Map<String, dynamic>> finishOrder(
    int orderId, {
    required String workDone,
    String? recommendations,
    int warrantyDays = 0,
    String? warrantyTerms,
  }) async =>
      _map((await _api.postJson('$_base/ordenes/$orderId/finalizar', <String, dynamic>{
        'trabajo_realizado': workDone.trim(),
        'recomendaciones': _nullable(recommendations),
        'garantia_dias': warrantyDays,
        'condiciones_garantia': _nullable(warrantyTerms),
      }, companyId: companyId))['data']);

  Future<Map<String, dynamic>> useMaterial(int orderId, int materialId, double quantity) async =>
      _map((await _api.postJson('$_base/ordenes/$orderId/materiales', <String, dynamic>{'material_id': materialId, 'cantidad': quantity}, companyId: companyId))['data']);

  Future<Map<String, dynamic>> removeMaterial(int orderId, int materialId) async =>
      _map((await _api.deleteJson('$_base/ordenes/$orderId/materiales/$materialId', companyId: companyId))['data']);

  Future<Map<String, dynamic>> registerPayment(int orderId, double amount, String method, {String? reference}) async =>
      _map((await _api.postJson('$_base/ordenes/$orderId/pagos', <String, dynamic>{
        'monto': amount,
        'metodo': method,
        if (reference != null && reference.trim().isNotEmpty) 'referencia': reference.trim(),
      }, companyId: companyId))['data']);

  static dynamic _nullable(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
  static List<Map<String, dynamic>> _list(dynamic value) => value is List ? value.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
}
