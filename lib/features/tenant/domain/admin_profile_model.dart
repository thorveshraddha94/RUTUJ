class AdminProfileModel {
  final String id;
  final String companyId;
  final String email;
  final String username;
  final String companyName;
  final String phone;
  final String role;
  final String status;
  final DateTime createdAt;

  AdminProfileModel({
    required this.id,
    this.companyId = '',
    String? email,
    String? username,
    String? companyName,
    String? phone,
    String? role,
    String? status,
    DateTime? createdAt,
  })  : email = (email == null || email.isEmpty) ? 'No Email' : email,
        username = (username == null || username.isEmpty) ? 'User' : username,
        companyName = (companyName == null || companyName.isEmpty) ? 'Unnamed Workspace' : companyName,
        phone = (phone == null || phone.isEmpty) ? '—' : phone,
        role = (role == null || role.isEmpty) ? 'admin' : role.toLowerCase(),
        status = (status == null || status.isEmpty) ? 'pending' : status.toLowerCase(),
        createdAt = createdAt ?? DateTime.now();

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isSuspended => status.toLowerCase() == 'suspended';
  bool get isSuperAdmin => role.toLowerCase() == 'superadmin' || email.toLowerCase() == 'parthgajjar.bk@gmail.com';

  factory AdminProfileModel.fromJson(Map<String, dynamic> json) {
    String? compName;
    if (json['companies'] != null && json['companies'] is Map) {
      compName = (json['companies'] as Map)['company_name']?.toString();
    } else if (json['company_name'] != null) {
      compName = json['company_name']?.toString();
    } else if (json['company'] != null) {
      compName = json['company']?.toString();
    }

    final rawEmail = (json['email'] ?? json['username'] ?? 'No Email').toString();
    final rawUsername = (json['username'] ?? json['email'] ?? 'User').toString();
    final rawRole = (json['role'] ?? ((rawEmail.toLowerCase() == 'parthgajjar.bk@gmail.com') ? 'superadmin' : 'admin')).toString().toLowerCase();

    final rawStatus = json['status']?.toString().toLowerCase();
    final derivedStatus = rawStatus ??
        ((rawEmail.toLowerCase() == 'parthgajjar.bk@gmail.com' ||
                rawRole == 'superadmin')
            ? 'approved'
            : 'pending');

    return AdminProfileModel(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      email: rawEmail,
      username: rawUsername,
      companyName: compName ?? (json['company_name'] ?? json['company'] ?? 'Unnamed Workspace').toString(),
      phone: (json['contact_phone'] ?? json['phone'] ?? json['mobile_number'] ?? '—').toString(),
      role: rawRole,
      status: derivedStatus,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory AdminProfileModel.fromSupabase(Map<String, dynamic> json) => AdminProfileModel.fromJson(json);

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'company_id': companyId,
      'username': username,
      'email': email,
      'role': role,
      'status': status,
      'phone': phone,
    };
  }

  Map<String, dynamic> toJson() => toSupabase();

  AdminProfileModel copyWith({
    String? id,
    String? companyId,
    String? username,
    String? email,
    String? companyName,
    String? phone,
    String? role,
    String? status,
    DateTime? createdAt,
  }) {
    return AdminProfileModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      username: username ?? this.username,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
