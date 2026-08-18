class AdminProfileModel {
  final String id;
  final String companyId;
  final String username;
  final String? email;
  final String role;
  final DateTime? createdAt;

  const AdminProfileModel({
    required this.id,
    required this.companyId,
    required this.username,
    this.email,
    this.role = 'admin',
    this.createdAt,
  });

  factory AdminProfileModel.fromSupabase(Map<String, dynamic> json) {
    return AdminProfileModel(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'admin',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'admin',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'company_id': companyId,
      'username': username,
      if (email != null) 'email': email,
      'role': role,
    };
  }

  AdminProfileModel copyWith({
    String? id,
    String? companyId,
    String? username,
    String? email,
    String? role,
    DateTime? createdAt,
  }) {
    return AdminProfileModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
