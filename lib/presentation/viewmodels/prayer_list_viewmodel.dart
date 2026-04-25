// lib/presentation/viewmodels/prayer_list_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection_container.dart';
import '../../domain/entities/prayer_record.dart';
import '../../domain/usecases/prayer_usecases.dart';

class PrayerListState {
  final List<PrayerRecord> records;
  final bool isLoading;
  final String? errorMessage;
  final DateTime selectedDate;

  const PrayerListState({
    this.records = const [],
    this.isLoading = false,
    this.errorMessage,
    required this.selectedDate,
  });

  PrayerListState copyWith({
    List<PrayerRecord>? records,
    bool? isLoading,
    String? errorMessage,
    DateTime? selectedDate,
    bool clearError = false,
  }) {
    return PrayerListState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class PrayerListViewModel extends StateNotifier<PrayerListState> {
  final GetPrayerRecordsByDateUseCase _getByDateUseCase;
  final DeletePrayerRecordUseCase _deleteUseCase;

  PrayerListViewModel({
    required GetPrayerRecordsByDateUseCase getByDateUseCase,
    required DeletePrayerRecordUseCase deleteUseCase,
  })  : _getByDateUseCase = getByDateUseCase,
        _deleteUseCase = deleteUseCase,
        super(PrayerListState(selectedDate: DateTime.now())) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final records = await _getByDateUseCase.execute(state.selectedDate);
      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '기도 기록을 불러오는데 실패했습니다.',
      );
    }
  }

  Future<void> changeDate(DateTime date) async {
    state = state.copyWith(selectedDate: date);
    await loadRecords();
  }

  Future<void> deleteRecord(int id) async {
    try {
      await _deleteUseCase.execute(id);
      await loadRecords();
    } catch (e) {
      state = state.copyWith(errorMessage: '삭제에 실패했습니다.');
    }
  }
}

final prayerListViewModelProvider =
    StateNotifierProvider<PrayerListViewModel, PrayerListState>((ref) {
  return PrayerListViewModel(
    getByDateUseCase: sl<GetPrayerRecordsByDateUseCase>(),
    deleteUseCase: sl<DeletePrayerRecordUseCase>(),
  );
});
