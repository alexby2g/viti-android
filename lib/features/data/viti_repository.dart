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

  Future<Map<String, dynamic>> supportSummary() => _api.getJson('/soporte/resumen');

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}
