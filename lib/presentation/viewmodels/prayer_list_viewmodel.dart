// lib/presentation/viewmodels/prayer_list_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection_container.dart';
import '../../domain/entities/prayer_record.dart';
import '../../domain/usecases/prayer_usecases.dart';

class PrayerListState {
  final List<PrayerRecord> records;
  final bool isLoading;
  final String? errorMessage;
  final DateTime startDate;
  final DateTime endDate;
  /// 기도 기록이 존재하는 날짜 집합 (년/월/일 정규화)
  final Set<DateTime> recordDates;
  /// 필터링할 기도통장 계획 ID (null이면 전체)
  final int? bankPlanId;

  const PrayerListState({
    this.records = const [],
    this.isLoading = false,
    this.errorMessage,
    required this.startDate,
    required this.endDate,
    this.recordDates = const {},
    this.bankPlanId,
  });

  PrayerListState copyWith({
    List<PrayerRecord>? records,
    bool? isLoading,
    String? errorMessage,
    DateTime? startDate,
    DateTime? endDate,
    Set<DateTime>? recordDates,
    bool clearError = false,
    int? bankPlanId,
  }) {
    return PrayerListState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      recordDates: recordDates ?? this.recordDates,
      bankPlanId: bankPlanId ?? this.bankPlanId,
    );
  }
}

class PrayerListViewModel extends StateNotifier<PrayerListState> {
  final GetPrayerRecordsByDateRangeUseCase _getByRangeUseCase;
  final DeletePrayerRecordUseCase _deleteUseCase;
  final GetRecordDatesUseCase _getRecordDatesUseCase;

  PrayerListViewModel({
    required GetPrayerRecordsByDateRangeUseCase getByRangeUseCase,
    required DeletePrayerRecordUseCase deleteUseCase,
    required GetRecordDatesUseCase getRecordDatesUseCase,
    int? bankPlanId,
    DateTime? initialStart,
    DateTime? initialEnd,
  })  : _getByRangeUseCase = getByRangeUseCase,
        _deleteUseCase = deleteUseCase,
        _getRecordDatesUseCase = getRecordDatesUseCase,
        super(PrayerListState(
          startDate: initialStart ?? _dateOnly(DateTime.now()),
          endDate: initialEnd ?? _dateOnly(DateTime.now()),
          bankPlanId: bankPlanId,
        )) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final planId = state.bankPlanId;
      final results = await Future.wait([
        _getByRangeUseCase.execute(state.startDate, state.endDate, bankPlanId: planId),
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

  Future<void> changeRange(DateTime start, DateTime end) async {
    state = state.copyWith(startDate: start, endDate: end);
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

  /// 이전 구간으로 이동 (같은 기간 길이만큼)
  Future<void> movePrev() async {
    final days = state.endDate.difference(state.startDate).inDays + 1;
    final newEnd = state.startDate.subtract(const Duration(days: 1));
    final newStart = newEnd.subtract(Duration(days: days - 1));
    await changeRange(newStart, newEnd);
  }

  /// 다음 구간으로 이동
  Future<void> moveNext() async {
    final days = state.endDate.difference(state.startDate).inDays + 1;
    final newStart = state.endDate.add(const Duration(days: 1));
    final newEnd = newStart.add(Duration(days: days - 1));
    await changeRange(newStart, newEnd);
  }

  /// 기도통장 계획 기간으로 범위 설정
  Future<void> setToPlanRange(DateTime start, DateTime end) async {
    await changeRange(_dateOnly(start), _dateOnly(end));
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

}

/// 계획별로 독립된 ViewModel을 제공 (bankPlanId로 구분)
final prayerListViewModelProvider = StateNotifierProvider.family<
    PrayerListViewModel, PrayerListState, int?>((ref, bankPlanId) {
  return PrayerListViewModel(
    getByRangeUseCase: sl<GetPrayerRecordsByDateRangeUseCase>(),
    deleteUseCase: sl<DeletePrayerRecordUseCase>(),
    getRecordDatesUseCase: sl<GetRecordDatesUseCase>(),
    bankPlanId: bankPlanId,
  );
});
