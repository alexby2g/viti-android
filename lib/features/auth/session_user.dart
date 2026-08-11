class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.role,
    this.username,
  });

  final int id;
  final String name;
  final String role;
  final String? username;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    final first = (json['nombre'] ?? '').toString().trim();
    final last = (json['apellido'] ?? '').toString().trim();
    return SessionUser(
      id: int.tryParse('${json['id']}') ?? 0,
      name: [first, last].where((part) => part.isNotEmpty).join(' '),
      role: (json['rol'] ?? 'cliente').toString(),
      username: json['usuario']?.toString(),
    );
  }
}
