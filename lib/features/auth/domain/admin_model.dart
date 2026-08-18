enum UserRole { admin, driver }

class AdminModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final UserRole role;

  const AdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      role: (json['role'] as String).toLowerCase() == 'admin'
          ? UserRole.admin
          : UserRole.driver,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        'role': role == UserRole.admin ? 'ADMIN' : 'DRIVER',
      };
}
