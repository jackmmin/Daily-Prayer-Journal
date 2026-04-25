// lib/domain/entities/prayer_record.dart

class PrayerRecord {
  final int? id;
  final String title;
  final String content;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime createdAt;

  const PrayerRecord({
    this.id,
    required this.title,
    required this.content,
    required this.startTime,
    this.endTime,
    required this.createdAt,
  });

  Duration? get prayerDuration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  bool get isCompleted => endTime != null;

  PrayerRecord copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    bool clearEndTime = false,
  }) {
    return PrayerRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PrayerRecord(id: $id, title: $title, startTime: $startTime, endTime: $endTime)';
}
