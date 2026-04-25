// lib/presentation/widgets/calendar_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/di/injection_container.dart';
import '../../core/providers/marker_color_provider.dart';
import '../../domain/usecases/prayer_usecases.dart';

/// 날짜 범위 선택 결과 타입
typedef DateRangeResult = ({DateTime start, DateTime end});

/// 기도 기록이 있는 날짜에 dot 표시를 포함한 날짜 범위 선택 다이얼로그.
/// - 첫 탭: 시작 날짜 설정
/// - 두 번째 탭: 종료 날짜 설정 (최대 3개월 이내)
/// - 시작 날짜만 선택 시 해당 날짜 하루 범위 반환
/// - 기록 있는 날짜 탭 시 dot 색상 팔레트 표시
class CalendarPickerDialog extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final Set<DateTime> recordDates;

  const CalendarPickerDialog({
    super.key,
    required this.selectedDate,
    required this.recordDates,
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
  bool _pickingEnd = false;

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

  void _onDayTapped(DateTime selected, DateTime focused) {
    if (selected.isAfter(DateTime.now())) return;
    final normalized = DateTime(selected.year, selected.month, selected.day);

    setState(() {
      _focused = focused;

      if (!_pickingEnd) {
        // 첫 탭: 시작 날짜 설정, 종료 날짜 초기화
        _rangeStart = normalized;
        _rangeEnd = null;
        _pickingEnd = true;
        _colorEditingDate = null;
      } else {
        // 두 번째 탭: 종료 날짜 설정
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
        if (isSameDay(start, end) && _hasRecord(start)) {
          _colorEditingDate =
              _colorEditingDate != null && isSameDay(_colorEditingDate!, start)
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
            // 선택 안내 텍스트
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _pickingEnd ? '종료 날짜를 선택하세요' : '시작 날짜를 선택하세요',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TableCalendar(
              locale: 'ko_KR',
              focusedDay: _focused,
              firstDay: DateTime(2000),
              lastDay: DateTime.now(),
              rangeStartDay: _rangeStart,
              rangeEndDay: rangeEnd,
              rangeSelectionMode: rangeEnd != null
                  ? RangeSelectionMode.enforced
                  : RangeSelectionMode.disabled,
              selectedDayPredicate: (day) =>
                  rangeEnd == null && isSameDay(day, _rangeStart),
              onDaySelected: _onDayTapped,
              onRangeSelected: null,
              onPageChanged: (focused) {
                setState(() {
                  _focused = focused;
                  _colorEditingDate = null;
                });
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (!_hasRecord(day)) return const SizedBox.shrink();
                  final color = notifier.colorFor(day);
                  final isEditing = _colorEditingDate != null &&
                      isSameDay(_colorEditingDate!, day);
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: isEditing
                            ? [BoxShadow(color: color, blurRadius: 4, spreadRadius: 1)]
                            : null,
                      ),
                    ),
                  );
                },
                // 범위 내 날짜 배경 커스텀 (rangeEnd가 null일 때 기본 highlight 방지)
                withinRangeBuilder: rangeEnd != null
                    ? null
                    : (context, day, _) => _buildDay(context, day, colorScheme, inRange: false),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              calendarStyle: CalendarStyle(
                rangeHighlightColor: colorScheme.primary.withValues(alpha: 0.15),
                rangeStartDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
            ),
            const Divider(height: 16),

            // 선택된 범위 미리보기 배너
            _RangeBanner(
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
                      child: _ColorPalette(
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

  Widget _buildDay(
    BuildContext context,
    DateTime day,
    ColorScheme colorScheme, {
    required bool inRange,
  }) {
    return Center(
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: inRange ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// 선택된 범위 / 미리보기 배너
class _RangeBanner extends StatelessWidget {
  final DateTime start;
  final DateTime? end;
  final String? previewTitle;
  final bool isLoading;

  const _RangeBanner({
    required this.start,
    required this.end,
    required this.previewTitle,
    required this.isLoading,
  });

  static String _fmt(DateTime d) => '${d.month}/${d.day}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String dateLabel;
    if (end == null || isSameDay(start, end!)) {
      dateLabel = _fmt(start);
    } else {
      dateLabel = '${_fmt(start)} ~ ${_fmt(end!)}';
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: 14,
        width: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: colorScheme.primary,
        ),
      );
    } else if (previewTitle == null || previewTitle!.isEmpty) {
      content = Text(
        '$dateLabel  기도 기록 없음',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      );
    } else {
      content = Row(
        children: [
          Icon(Icons.book_outlined, size: 13, color: colorScheme.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '$dateLabel  $previewTitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );
  }
}

/// dot 마커 색상 선택 팔레트
class _ColorPalette extends StatelessWidget {
  final DateTime editingDate;
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPalette({
    required this.editingDate,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '${editingDate.month}/${editingDate.day} 기록 색상',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: markerColorOptions.map((color) {
            final isSelected = currentColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 2.5,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
