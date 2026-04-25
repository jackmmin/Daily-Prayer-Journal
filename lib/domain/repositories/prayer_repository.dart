// lib/domain/repositories/prayer_repository.dart

import '../entities/prayer_record.dart';

abstract interface class PrayerRepository {
  Future<List<PrayerRecord>> getAllRecords();
  Future<List<PrayerRecord>> getRecordsByDate(DateTime date);
  Future<PrayerRecord?> getRecordById(int id);
  Future<int> insertRecord(PrayerRecord record);
  Future<void> updateRecord(PrayerRecord record);
  Future<void> deleteRecord(int id);
}
