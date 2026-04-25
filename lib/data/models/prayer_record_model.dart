// lib/data/models/prayer_record_model.dart

import '../../domain/entities/prayer_record.dart';

class PrayerRecordModel {
  static const String tableName = 'prayer_records';

  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnContent = 'content';
  static const String columnStartTime = 'start_time';
  static const String columnEndTime = 'end_time';
  static const String columnBankPlanId = 'bank_plan_id';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnTitle TEXT NOT NULL,
      $columnContent TEXT NOT NULL,
      $columnStartTime INTEGER NOT NULL,
      $columnEndTime INTEGER,
      $columnBankPlanId INTEGER
    )
  ''';

  /// seconds 단위로 저장 (milliseconds 대비 ~25% 절감)
  static Map<String, dynamic> toMap(PrayerRecord record) {
    return {
      if (record.id != null) columnId: record.id,
      columnTitle: record.title,
      columnContent: record.content,
      columnStartTime: record.startTime.millisecondsSinceEpoch ~/ 1000,
      columnEndTime: record.endTime != null
          ? record.endTime!.millisecondsSinceEpoch ~/ 1000
          : null,
      columnBankPlanId: record.bankPlanId,
    };
  }

  static PrayerRecord fromMap(Map<String, dynamic> map) {
    return PrayerRecord(
      id: map[columnId] as int?,
      title: map[columnTitle] as String,
      content: map[columnContent] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        (map[columnStartTime] as int) * 1000,
      ),
      endTime: map[columnEndTime] != null
          ? DateTime.fromMillisecondsSinceEpoch((map[columnEndTime] as int) * 1000)
          : null,
      bankPlanId: map[columnBankPlanId] as int?,
    );
  }
}
