// lib/presentation/widgets/calendar_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/di/injection_container.dart';
import '../../core/providers/marker_color_provider.dart';
import '../../domain/usecases/prayer_usecases.dart';

/// 기도 기록이 있는 날짜에 dot 표시를 포함한 날짜 선택 다이얼로그.
/// - 날짜 탭 시 해당 날짜 첫 번째 기도일지 title 미리보기 표시
/// - 확인 버튼으로 해당 날짜로 이동
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
  late DateTime _selected;

  /// 색상 편집 중인 날짜
  DateTime? _colorEditingDate;

  /// 미리보기 title (null=로딩 중, ''=기록 없음)
  String? _previewTitle;
  bool _previewLoading = false;

  @override
  void initState() {
    super.initState();
    _focused = widget.selectedDate;
    _selected = widget.selectedDate;
    // 초기 선택 날짜 미리보기 로드
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
      _selected = normalized;
      _focused = focused;
      // 기록 있는 날짜: 색상 팔레트 토글 / 없는 날짜: 팔레트 닫기
      if (_hasRecord(selected)) {
        _colorEditingDate =
            _colorEditingDate != null && isSameDay(_colorEditingDate!, normalized)
                ? null
                : normalized;
      } else {
        _colorEditingDate = null;
      }
    });
    _loadPreview(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    ref.watch(markerColorProvider);
    final notifier = ref.read(markerColorProvider.notifier);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TableCalendar(
              locale: 'ko_KR',
              focusedDay: _focused,
              firstDay: DateTime(2000),
              lastDay: DateTime.now(),
              selectedDayPredicate: (day) => isSameDay(day, _selected),
              onDaySelected: _onDayTapped,
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

            // 선택된 날짜 첫 번째 기도일지 title 미리보기
            _PreviewBanner(
              date: _selected,
              title: _previewTitle,
              isLoading: _previewLoading,
            ),

            // 색상 팔레트: 기록 있는 날짜를 탭했을 때만 표시
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
                  onPressed: () => Navigator.of(context).pop(_selected),
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

/// 선택 날짜의 첫 번째 기도일지 title 미리보기 배너
class _PreviewBanner extends StatelessWidget {
  final DateTime date;
  final String? title;  // null=로딩, ''=기록 없음
  final bool isLoading;

  const _PreviewBanner({
    required this.date,
    required this.title,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateLabel = '${date.month}/${date.day}';

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
    } else if (title == null || title!.isEmpty) {
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
              '$dateLabel  $title',
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
