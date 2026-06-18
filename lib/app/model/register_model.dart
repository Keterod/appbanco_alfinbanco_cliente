class RegisterModel {
  const RegisterModel({
    required this.dni,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.password,
    required this.acceptedTerms,
    required this.createdAt,
  });

  final String dni;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String password;
  final bool acceptedTerms;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName';
}
