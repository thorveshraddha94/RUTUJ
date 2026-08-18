class CompanyModel {
  final String id;
  final String name;
  final DateTime? createdAt;

  const CompanyModel({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory CompanyModel.fromSupabase(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id']?.toString() ?? '',
      name: json['company_name']?.toString() ?? json['name']?.toString() ?? 'Airport Operations',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      if (id.isNotEmpty) 'id': id,
      'company_name': name,
    };
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
