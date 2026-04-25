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
  /// 기도 기록이 존재하는 날짜 집합 (년/월/일 정규화)
  final Set<DateTime> recordDates;
  /// 필터링할 기도통장 계획 ID (null이면 전체)
  final int? bankPlanId;

  const PrayerListState({
    this.records = const [],
    this.isLoading = false,
    this.errorMessage,
    required this.selectedDate,
    this.recordDates = const {},
    this.bankPlanId,
  });

  PrayerListState copyWith({
    List<PrayerRecord>? records,
    bool? isLoading,
    String? errorMessage,
    DateTime? selectedDate,
    Set<DateTime>? recordDates,
    bool clearError = false,
    int? bankPlanId,
  }) {
    return PrayerListState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedDate: selectedDate ?? this.selectedDate,
      recordDates: recordDates ?? this.recordDates,
      bankPlanId: bankPlanId ?? this.bankPlanId,
    );
  }
}

class PrayerListViewModel extends StateNotifier<PrayerListState> {
  final GetPrayerRecordsByDateUseCase _getByDateUseCase;
  final DeletePrayerRecordUseCase _deleteUseCase;
  final GetRecordDatesUseCase _getRecordDatesUseCase;

  PrayerListViewModel({
    required GetPrayerRecordsByDateUseCase getByDateUseCase,
    required DeletePrayerRecordUseCase deleteUseCase,
    required GetRecordDatesUseCase getRecordDatesUseCase,
    int? bankPlanId,
    DateTime? initialDate,
  })  : _getByDateUseCase = getByDateUseCase,
        _deleteUseCase = deleteUseCase,
        _getRecordDatesUseCase = getRecordDatesUseCase,
        super(PrayerListState(
          selectedDate: initialDate ?? DateTime.now(),
          bankPlanId: bankPlanId,
        )) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final planId = state.bankPlanId;
      final results = await Future.wait([
        _getByDateUseCase.execute(state.selectedDate, bankPlanId: planId),
        _getRecordDatesUseCase.execute(bankPlanId: planId),
      ]);
      state = state.copyWith(
        records: results[0] as List<PrayerRecord>,
        recordDates: results[1] as Set<DateTime>,
        isLoading: false,
      );
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

/// 계획별로 독립된 ViewModel을 제공 (bankPlanId로 구분)
final prayerListViewModelProvider = StateNotifierProvider.family<
    PrayerListViewModel, PrayerListState, int?>((ref, bankPlanId) {
  return PrayerListViewModel(
    getByDateUseCase: sl<GetPrayerRecordsByDateUseCase>(),
    deleteUseCase: sl<DeletePrayerRecordUseCase>(),
    getRecordDatesUseCase: sl<GetRecordDatesUseCase>(),
    bankPlanId: bankPlanId,
  );
});
