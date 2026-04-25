// lib/presentation/viewmodels/prayer_form_viewmodel.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection_container.dart';
import '../../domain/entities/prayer_record.dart';
import '../../domain/usecases/prayer_usecases.dart';

enum TimerStatus { idle, running, stopped }

class PrayerFormState {
  final PrayerRecord? editingRecord;
  final TimerStatus timerStatus;
  final DateTime? timerStartTime;
  final Duration elapsedDuration;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;

  const PrayerFormState({
    this.editingRecord,
    this.timerStatus = TimerStatus.idle,
    this.timerStartTime,
    this.elapsedDuration = Duration.zero,
    this.isSaving = false,
    this.isSaved = false,
    this.errorMessage,
  });

  bool get isTimerRunning => timerStatus == TimerStatus.running;
  bool get isTimerStopped => timerStatus == TimerStatus.stopped;

  PrayerFormState copyWith({
    PrayerRecord? editingRecord,
    TimerStatus? timerStatus,
    DateTime? timerStartTime,
    Duration? elapsedDuration,
    bool? isSaving,
    bool? isSaved,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PrayerFormState(
      editingRecord: editingRecord ?? this.editingRecord,
      timerStatus: timerStatus ?? this.timerStatus,
      timerStartTime: timerStartTime ?? this.timerStartTime,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PrayerFormViewModel extends StateNotifier<PrayerFormState> {
  final SavePrayerRecordUseCase _saveUseCase;

  Timer? _timer;

  PrayerFormViewModel({
    required SavePrayerRecordUseCase saveUseCase,
    PrayerRecord? initialRecord,
  })  : _saveUseCase = saveUseCase,
        super(PrayerFormState(editingRecord: initialRecord));

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    if (state.isTimerRunning) return;

    final startTime = DateTime.now();
    state = state.copyWith(
      timerStatus: TimerStatus.running,
      timerStartTime: startTime,
      elapsedDuration: Duration.zero,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(startTime);
      state = state.copyWith(elapsedDuration: elapsed);
    });
  }

  void stopTimer() {
    if (!state.isTimerRunning) return;

    _timer?.cancel();
    _timer = null;

    state = state.copyWith(timerStatus: TimerStatus.stopped);
  }

  void resetTimer() {
    _timer?.cancel();
    _timer = null;

    state = state.copyWith(
      timerStatus: TimerStatus.idle,
      timerStartTime: null,
      elapsedDuration: Duration.zero,
    );
  }

  Future<void> saveRecord({
    required String title,
    required String content,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    if (title.trim().isEmpty) {
      state = state.copyWith(errorMessage: '기도 제목을 입력해주세요.');
      return;
    }

    // 타이머 사용 시 타이머의 시작/종료 시간 우선 적용
    final effectiveStartTime =
        state.timerStartTime ?? startTime;
    final effectiveEndTime = state.isTimerStopped
        ? (state.timerStartTime != null
            ? state.timerStartTime!.add(state.elapsedDuration)
            : endTime)
        : endTime;

    final record = PrayerRecord(
      id: state.editingRecord?.id,
      title: title.trim(),
      content: content.trim(),
      startTime: effectiveStartTime,
      endTime: effectiveEndTime,
      createdAt: state.editingRecord?.createdAt ?? DateTime.now(),
    );

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _saveUseCase.execute(record);
      state = state.copyWith(isSaving: false, isSaved: true);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '저장에 실패했습니다.',
      );
    }
  }
}

final prayerFormViewModelProvider = StateNotifierProvider.family<
    PrayerFormViewModel, PrayerFormState, PrayerRecord?>(
  (ref, initialRecord) => PrayerFormViewModel(
    saveUseCase: sl<SavePrayerRecordUseCase>(),
    initialRecord: initialRecord,
  ),
);
