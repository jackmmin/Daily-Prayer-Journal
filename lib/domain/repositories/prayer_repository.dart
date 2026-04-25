// lib/domain/repositories/prayer_repository.dart

import '../entities/prayer_record.dart';

abstract interface class PrayerRepository {
  Future<List<PrayerRecord>> getAllRecords();
  Future<List<PrayerRecord>> getRecordsByDate(DateTime date);
  Future<PrayerRecord?> getRecordById(int id);
  Future<int> insertRecord(PrayerRecord record);
  Future<void> updateRecord(PrayerRecord record);
  Future<void> deleteRecord(int id);
  /// 기도 기록이 존재하는 날짜 목록 반환 (년/월/일만 사용)
  Future<Set<DateTime>> getRecordDates();
}
