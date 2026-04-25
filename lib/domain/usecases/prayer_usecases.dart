// lib/domain/usecases/prayer_usecases.dart

import '../entities/prayer_record.dart';
import '../repositories/prayer_repository.dart';

class GetAllPrayerRecordsUseCase {
  final PrayerRepository _repository;

  const GetAllPrayerRecordsUseCase(this._repository);

  Future<List<PrayerRecord>> execute() => _repository.getAllRecords();
}

class GetPrayerRecordsByDateUseCase {
  final PrayerRepository _repository;

  const GetPrayerRecordsByDateUseCase(this._repository);

  Future<List<PrayerRecord>> execute(DateTime date) =>
      _repository.getRecordsByDate(date);
}

class SavePrayerRecordUseCase {
  final PrayerRepository _repository;

  const SavePrayerRecordUseCase(this._repository);

  Future<int> execute(PrayerRecord record) async {
    if (record.id == null) {
      return await _repository.insertRecord(record);
    } else {
      await _repository.updateRecord(record);
      return record.id!;
    }
  }
}

class DeletePrayerRecordUseCase {
  final PrayerRepository _repository;

  const DeletePrayerRecordUseCase(this._repository);

  Future<void> execute(int id) => _repository.deleteRecord(id);
}

class GetRecordDatesUseCase {
  final PrayerRepository _repository;

  const GetRecordDatesUseCase(this._repository);

  Future<Set<DateTime>> execute() => _repository.getRecordDates();
}
