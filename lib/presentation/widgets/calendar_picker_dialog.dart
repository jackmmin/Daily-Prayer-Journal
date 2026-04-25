// lib/presentation/widgets/calendar_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/providers/marker_color_provider.dart';

/// 기도 기록이 있는 날짜에 dot 표시를 포함한 날짜 선택 다이얼로그.
/// 하단 색상 팔레트로 dot 색상을 변경·저장할 수 있다.
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

  @override
  void initState() {
    super.initState();
    _focused = widget.selectedDate;
    _selected = widget.selectedDate;
  }

  bool _hasRecord(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return widget.recordDates.contains(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final markerColor = ref.watch(markerColorProvider);

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
              onDaySelected: (selected, focused) {
                if (selected.isAfter(DateTime.now())) return;
                setState(() {
                  _selected = selected;
                  _focused = focused;
                });
                Navigator.of(context).pop(selected);
              },
              onPageChanged: (focused) {
                setState(() => _focused = focused);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (!_hasRecord(day)) return const SizedBox.shrink();
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: markerColor,
                        shape: BoxShape.circle,
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
            _ColorPalette(currentColor: markerColor),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }
}

/// dot 마커 색상 선택 팔레트
class _ColorPalette extends ConsumerWidget {
  final Color currentColor;

  const _ColorPalette({required this.currentColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '기록 표시 색상',
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
              onTap: () =>
                  ref.read(markerColorProvider.notifier).setColor(color),
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
