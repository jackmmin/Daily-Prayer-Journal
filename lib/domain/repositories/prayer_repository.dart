// lib/domain/repositories/prayer_repository.dart

import '../entities/prayer_record.dart';

abstract interface class PrayerRepository {
  Future<List<PrayerRecord>> getAllRecords();
  Future<List<PrayerRecord>> getRecordsByDate(DateTime date, {int? bankPlanId});
  Future<List<PrayerRecord>> getRecordsByDateRange(DateTime start, DateTime end, {int? bankPlanId});
  Future<PrayerRecord?> getRecordById(int id);
  Future<int> insertRecord(PrayerRecord record);
  Future<void> updateRecord(PrayerRecord record);
  Future<void> deleteRecord(int id);
  Future<Set<DateTime>> getRecordDates({int? bankPlanId});
}
