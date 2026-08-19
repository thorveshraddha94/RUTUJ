enum UserRole { admin, driver, superadmin }
enum UserStatus { pending, approved, suspended }

class AdminModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final UserRole role;
  final UserStatus status;

  const AdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    this.status = UserStatus.approved,
  });

  bool get isAdmin => role == UserRole.admin || role == UserRole.superadmin;
  bool get isSuperAdmin => role == UserRole.superadmin || email.toLowerCase().trim() == 'parthgajjar.bk@gmail.com';

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String? ?? '').toLowerCase().trim();
    final userRole = roleStr == 'superadmin'
        ? UserRole.superadmin
        : roleStr == 'admin'
            ? UserRole.admin
            : UserRole.driver;

    final statusStr = (json['status'] as String? ?? '').toLowerCase().trim();
    final userStatus = (statusStr == 'pending')
        ? UserStatus.pending
        : (statusStr == 'suspended' || statusStr == 'blocked')
            ? UserStatus.suspended
            : UserStatus.approved;

    return AdminModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      role: userRole,
      status: userStatus,
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
        'status': status.name,
      };
}
