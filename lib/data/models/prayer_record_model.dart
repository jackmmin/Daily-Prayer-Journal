// lib/data/models/prayer_record_model.dart

import 'dart:convert';
import 'dart:io';

import '../../domain/entities/prayer_record.dart';

class PrayerRecordModel {
  static const String tableName = 'prayer_records';

  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnContent = 'content';
  static const String columnStartTime = 'start_time';
  static const String columnEndTime = 'end_time';
  static const String columnBankPlanId = 'bank_plan_id';

  /// content 컬럼을 BLOB으로 저장 (gzip 압축)
  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnTitle TEXT NOT NULL,
      $columnContent BLOB NOT NULL,
      $columnStartTime INTEGER NOT NULL,
      $columnEndTime INTEGER,
      $columnBankPlanId INTEGER
    )
  ''';

  /// 500 bytes 초과 시 gzip 압축 후 BLOB 저장, 이하는 UTF-8 바이트 그대로
  static List<int> _encodeContent(String content) {
    final bytes = utf8.encode(content);
    if (bytes.length <= 500) return bytes;
    return GZipCodec().encode(bytes);
  }

  /// gzip 시그니처(0x1f, 0x8b) 확인 후 압축 해제, 아니면 UTF-8 디코딩
  static String _decodeContent(dynamic raw) {
    final List<int> bytes;
    if (raw is List<int>) {
      bytes = raw;
    } else if (raw is String) {
      // v5 이하 TEXT 컬럼 레거시 데이터 호환
      return raw;
    } else {
      bytes = List<int>.from(raw as List);
    }
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      return utf8.decode(GZipCodec().decode(bytes));
    }
    return utf8.decode(bytes);
  }

  /// seconds 단위로 저장 (milliseconds 대비 ~25% 절감)
  static Map<String, dynamic> toMap(PrayerRecord record) {
    return {
      if (record.id != null) columnId: record.id,
      columnTitle: record.title,
      columnContent: _encodeContent(record.content),
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
      content: _decodeContent(map[columnContent]),
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
