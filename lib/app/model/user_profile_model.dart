import '../repository/supabase_parse_utils.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.fullName,
    required this.dni,
    required this.email,
    required this.phone,
    required this.address,
    required this.clientType,
    required this.joinDate,
  });

  final String fullName;
  final String dni;
  final String email;
  final String phone;
  final String address;
  final String clientType;
  final DateTime joinDate;

  String get maskedDni {
    if (dni.length < 4) return dni;
    return '${'*' * (dni.length - 2)}${dni.substring(dni.length - 2)}';
  }

  factory UserProfileModel.fromSupabase(Map<String, dynamic> json) {
    final nombres = parseSupabaseString(json['nombres']);
    final apellidos = parseSupabaseString(json['apellidos']);
    final fullName = '$nombres $apellidos'.trim();

    return UserProfileModel(
      fullName: fullName.isEmpty
          ? parseSupabaseString(json['nombre_completo'], 'Cliente')
          : fullName,
      dni: parseSupabaseString(json['dni']),
      email: parseSupabaseString(json['email']),
      phone: parseSupabaseString(json['telefono']),
      address: parseSupabaseString(json['direccion']),
      clientType: parseSupabaseString(
        json['tipo_cliente'],
        'Cliente',
      ),
      joinDate: parseSupabaseDate(
            json['fecha_vinculacion'] ??
                json['created_at'] ??
                json['fecha_registro'],
          ) ??
          DateTime.now(),
    );
  }
}
