class EventModel {
  final String id;
  final String date; // 'yyyy-M-d' format
  final String title;
  final int updatedAt;
  final bool deleted;

  const EventModel({
    required this.id,
    required this.date,
    required this.title,
    required this.updatedAt,
    this.deleted = false,
  });

  EventModel copyWith({String? title, int? updatedAt, bool? deleted}) {
    return EventModel(
      id: id,
      date: date,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'title': title,
    'updatedAt': updatedAt,
    'deleted': deleted,
  };

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
    id: json['id'] as String,
    date: json['date'] as String,
    title: json['title'] as String,
    updatedAt: json['updatedAt'] as int,
    deleted: json['deleted'] as bool? ?? false,
  );

  static String dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
