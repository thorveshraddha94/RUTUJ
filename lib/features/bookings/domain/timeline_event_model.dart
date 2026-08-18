class TimelineEventModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String iconType;
  final bool isCompleted;

  const TimelineEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.iconType,
    this.isCompleted = true,
  });

  factory TimelineEventModel.fromJson(Map<String, dynamic> json) {
    return TimelineEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      iconType: json['iconType'] as String,
      isCompleted: json['isCompleted'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'iconType': iconType,
        'isCompleted': isCompleted,
      };
}
