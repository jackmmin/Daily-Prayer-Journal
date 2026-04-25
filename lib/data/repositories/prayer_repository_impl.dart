// lib/data/repositories/prayer_repository_impl.dart

import '../../domain/entities/prayer_record.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../datasources/local/prayer_local_datasource.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  final PrayerLocalDataSource _localDataSource;

  const PrayerRepositoryImpl(this._localDataSource);

  @override
  Future<List<PrayerRecord>> getAllRecords() =>
      _localDataSource.getAllRecords();

  @override
  Future<List<PrayerRecord>> getRecordsByDate(DateTime date, {int? bankPlanId}) =>
      _localDataSource.getRecordsByDate(date, bankPlanId: bankPlanId);

  @override
  Future<PrayerRecord?> getRecordById(int id) =>
      _localDataSource.getRecordById(id);

  @override
  Future<int> insertRecord(PrayerRecord record) =>
      _localDataSource.insertRecord(record);

  @override
  Future<void> updateRecord(PrayerRecord record) =>
      _localDataSource.updateRecord(record);

  @override
  Future<void> deleteRecord(int id) => _localDataSource.deleteRecord(id);

  @override
  Future<Set<DateTime>> getRecordDates({int? bankPlanId}) =>
      _localDataSource.getRecordDates(bankPlanId: bankPlanId);
}
