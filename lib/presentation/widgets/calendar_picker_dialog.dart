// lib/presentation/widgets/calendar_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection_container.dart';
import '../../core/providers/marker_color_provider.dart';
import '../../domain/usecases/prayer_usecases.dart';
import 'calendar/range_banner.dart';
import 'calendar/color_palette.dart';
import 'calendar/calendar_table.dart';

/// 날짜 범위 선택 결과 타입
typedef DateRangeResult = ({DateTime start, DateTime end});

/// 기도 기록이 있는 날짜에 dot 표시를 포함한 날짜 범위 선택 다이얼로그.
/// - 첫 탭: 종료 날짜 설정 (전달받은 날짜가 시작으로 하이라이트된 상태에서 시작)
/// - 두 번째 탭: 시작 날짜 재설정
/// - 시작 날짜만 선택 시 해당 날짜 하루 범위 반환
/// - 기록 있는 날짜 탭 시 dot 색상 팔레트 표시
class CalendarPickerDialog extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  /// null이면 단일 날짜 선택 상태로 시작
  final DateTime? selectedEndDate;
  final Set<DateTime> recordDates;
  /// true이면 오늘 이후 미래 날짜도 선택 가능
  final bool allowFuture;

  const CalendarPickerDialog({
    super.key,
    required this.selectedDate,
    this.selectedEndDate,
    required this.recordDates,
    this.allowFuture = false,
  });

  @override
  ConsumerState<CalendarPickerDialog> createState() =>
      _CalendarPickerDialogState();
}

class _CalendarPickerDialogState extends ConsumerState<CalendarPickerDialog> {
  late DateTime _focused;
  /// 시작 날짜 (항상 설정됨)
  late DateTime _rangeStart;
  /// 종료 날짜 (null이면 시작만 선택된 상태)
  DateTime? _rangeEnd;
  /// 선택 단계: true=종료 날짜 선택 중
  /// 범위가 이미 설정된 경우 false로 시작 → 시작 날짜 재선택 단계
  bool _pickingEnd = true;

  /// 색상 편집 중인 날짜
  DateTime? _colorEditingDate;

  /// 미리보기 title (null=로딩 중, ''=기록 없음)
  String? _previewTitle;
  bool _previewLoading = false;

  /// 최대 선택 가능 기간 (3개월 = 92일)
  static const int _maxDays = 92;

  @override
  void initState() {
    super.initState();
    _focused = widget.selectedDate;
    _rangeStart = widget.selectedDate;
    // 이전에 설정된 범위가 있으면 복원하고 시작 날짜 재선택 단계로 시작
    if (widget.selectedEndDate != null &&
        !widget.selectedEndDate!.isAtSameMomentAs(widget.selectedDate)) {
      _rangeEnd = widget.selectedEndDate;
      _pickingEnd = false;
    }
    _loadPreview(widget.selectedDate);
  }

  bool _hasRecord(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return widget.recordDates.contains(normalized);
  }

  Future<void> _loadPreview(DateTime date) async {
    setState(() {
      _previewLoading = true;
      _previewTitle = null;
    });
    try {
      final records = await sl<GetPrayerRecordsByDateUseCase>().execute(date);
      if (!mounted) return;
      setState(() {
        _previewTitle = records.isNotEmpty ? records.first.title : '';
        _previewLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewTitle = '';
        _previewLoading = false;
      });
    }
  }

  void _goToToday() {
    final today = DateTime.now();
    final normalized = DateTime(today.year, today.month, today.day);
    setState(() {
      _focused = normalized;
      _rangeStart = normalized;
      _rangeEnd = null;
      _pickingEnd = true;
      _colorEditingDate = null;
    });
    _loadPreview(normalized);
  }

  void _onDayTapped(DateTime selected, DateTime focused) {
    if (!widget.allowFuture && selected.isAfter(DateTime.now())) return;
    final normalized = DateTime(selected.year, selected.month, selected.day);

    setState(() {
      _focused = focused;

      if (!_pickingEnd) {
        // 시작 날짜 재설정, 종료 날짜 초기화
        _rangeStart = normalized;
        _rangeEnd = null;
        _pickingEnd = true;
        _colorEditingDate = null;
      } else {
        // 종료 날짜 설정
        DateTime start = _rangeStart;
        DateTime end = normalized;

        // 종료가 시작보다 앞이면 swap
        if (end.isBefore(start)) {
          final tmp = start;
          start = end;
          end = tmp;
        }

        // 최대 3개월(92일) 초과 시 끝을 제한
        final diff = end.difference(start).inDays;
        if (diff > _maxDays) {
          end = start.add(const Duration(days: _maxDays));
        }

        _rangeStart = start;
        _rangeEnd = end;
        _pickingEnd = false;

        // 색상 팔레트: 단일 날짜 선택 시에만 표시
        if (start == end && _hasRecord(start)) {
          _colorEditingDate =
              _colorEditingDate != null && _colorEditingDate == start
                  ? null
                  : start;
        } else {
          _colorEditingDate = null;
        }
      }
    });
    _loadPreview(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    ref.watch(markerColorProvider);
    final notifier = ref.read(markerColorProvider.notifier);
    final rangeEnd = _rangeEnd;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 안내 텍스트 + 오늘 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    _pickingEnd ? '종료 날짜를 선택하세요' : '시작 날짜를 선택하세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _goToToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '오늘',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CalendarTable(
              focusedDay: _focused,
              rangeStart: _rangeStart,
              rangeEnd: rangeEnd,
              allowFuture: widget.allowFuture,
              colorEditingDate: _colorEditingDate,
              markerNotifier: notifier,
              hasRecord: _hasRecord,
              onDaySelected: _onDayTapped,
              onPageChanged: (focused) => setState(() {
                _focused = focused;
                _colorEditingDate = null;
              }),
            ),
            const Divider(height: 16),
            RangeBanner(
              start: _rangeStart,
              end: rangeEnd,
              previewTitle: _previewTitle,
              isLoading: _previewLoading,
            ),
            // 색상 팔레트: 단일 날짜 선택 시에만 표시
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _colorEditingDate != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ColorPalette(
                        editingDate: _colorEditingDate!,
                        currentColor: notifier.colorFor(_colorEditingDate!),
                        onColorSelected: (color) async {
                          await notifier.setColor(_colorEditingDate!, color);
                          setState(() {});
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: () {
                    final end = rangeEnd ?? _rangeStart;
                    Navigator.of(context).pop<DateRangeResult>(
                      (start: _rangeStart, end: end),
                    );
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
