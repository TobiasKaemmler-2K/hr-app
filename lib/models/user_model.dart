class UserModel {
  final String id;
  final String personalnummer;
  final String firstname;
  final String lastname;
  final String email;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.personalnummer,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.roles,
  });
}