// lib/domain/entities/prayer_record.dart

class PrayerRecord {
  final int? id;
  final String title;
  final String content;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime createdAt;

  /// 연결된 기도통장 계획 ID (null이면 미연결)
  final int? bankPlanId;

  const PrayerRecord({
    this.id,
    required this.title,
    required this.content,
    required this.startTime,
    this.endTime,
    required this.createdAt,
    this.bankPlanId,
  });

  Duration? get prayerDuration {
    if (endTime == null) return null;
    // 초를 버리고 분 단위로만 계산
    final startMin = DateTime(startTime.year, startTime.month, startTime.day, startTime.hour, startTime.minute);
    final endMin   = DateTime(endTime!.year,  endTime!.month,  endTime!.day,  endTime!.hour,  endTime!.minute);
    final diff = endMin.difference(startMin);
    return diff.isNegative ? null : diff;
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
    int? bankPlanId,
    bool clearBankPlanId = false,
  }) {
    return PrayerRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      createdAt: createdAt ?? this.createdAt,
      bankPlanId: clearBankPlanId ? null : (bankPlanId ?? this.bankPlanId),
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
