enum UserRole { admin, driver, superadmin }

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

  bool get isAdmin => role == UserRole.admin || role == UserRole.superadmin;
  bool get isSuperAdmin => role == UserRole.superadmin || email.toLowerCase() == 'parthgajjar.bk@gmail.com';

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String? ?? '').toLowerCase();
    final userRole = roleStr == 'superadmin'
        ? UserRole.superadmin
        : roleStr == 'admin'
            ? UserRole.admin
            : UserRole.driver;

    return AdminModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      role: userRole,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        'role': role == UserRole.superadmin
            ? 'SUPERADMIN'
            : role == UserRole.admin
                ? 'ADMIN'
                : 'DRIVER',
      };
}
