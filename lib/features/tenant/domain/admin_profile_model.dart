class AdminProfileModel {
  final String id;
  final String companyId;
  final String username;
  final String? email;
  final String role;
  final String status; // 'pending', 'approved', 'suspended'
  final String? phone;
  final String? companyName;
  final DateTime? createdAt;

  const AdminProfileModel({
    required this.id,
    required this.companyId,
    required this.username,
    this.email,
    this.role = 'admin',
    this.status = 'pending',
    this.phone,
    this.companyName,
    this.createdAt,
  });

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isSuspended => status.toLowerCase() == 'suspended';
  bool get isSuperAdmin => role.toLowerCase() == 'superadmin' || email?.toLowerCase() == 'parthgajjar.bk@gmail.com';

  factory AdminProfileModel.fromSupabase(Map<String, dynamic> json) {
    final userEmail = json['email']?.toString();
    final userRole = json['role']?.toString() ??
        ((userEmail?.toLowerCase() == 'parthgajjar.bk@gmail.com') ? 'superadmin' : 'admin');

    final rawStatus = json['status']?.toString().toLowerCase();
    final derivedStatus = rawStatus ??
        ((userEmail?.toLowerCase() == 'parthgajjar.bk@gmail.com' ||
                userRole.toLowerCase() == 'superadmin' ||
                userEmail?.toLowerCase() == 'admin@airporttransfer.com')
            ? 'approved'
            : 'pending');

    String? companyName;
    if (json['companies'] != null && json['companies'] is Map) {
      companyName = (json['companies'] as Map)['company_name']?.toString();
    } else if (json['company_name'] != null) {
      companyName = json['company_name']?.toString();
    }

    return AdminProfileModel(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      username: json['username']?.toString() ?? (userEmail?.split('@').first ?? 'admin'),
      email: userEmail,
      role: userRole,
      status: derivedStatus,
      phone: json['phone']?.toString() ?? json['contact_phone']?.toString(),
      companyName: companyName,
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
      'status': status,
      if (phone != null) 'phone': phone,
    };
  }

  AdminProfileModel copyWith({
    String? id,
    String? companyId,
    String? username,
    String? email,
    String? role,
    String? status,
    String? phone,
    String? companyName,
    DateTime? createdAt,
  }) {
    return AdminProfileModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
