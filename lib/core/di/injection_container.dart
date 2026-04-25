// lib/core/di/injection_container.dart

import 'package:get_it/get_it.dart';

import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/prayer_local_datasource.dart';
import '../../data/repositories/prayer_repository_impl.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../../domain/usecases/prayer_usecases.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerSingleton<DatabaseHelper>(DatabaseHelper.instance);

  // Data Sources
  sl.registerSingleton<PrayerLocalDataSource>(
    PrayerLocalDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerSingleton<PrayerRepository>(
    PrayerRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerFactory(() => GetAllPrayerRecordsUseCase(sl()));
  sl.registerFactory(() => GetPrayerRecordsByDateUseCase(sl()));
  sl.registerFactory(() => GetPrayerRecordsByDateRangeUseCase(sl()));
  sl.registerFactory(() => SavePrayerRecordUseCase(sl()));
  sl.registerFactory(() => DeletePrayerRecordUseCase(sl()));
  sl.registerFactory(() => GetRecordDatesUseCase(sl()));
}
