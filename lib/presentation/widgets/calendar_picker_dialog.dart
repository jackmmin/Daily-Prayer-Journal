// lib/presentation/widgets/calendar_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// 기도 기록이 있는 날짜에 dot 표시를 포함한 날짜 선택 다이얼로그
class CalendarPickerDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Set<DateTime> recordDates;

  const CalendarPickerDialog({
    super.key,
    required this.selectedDate,
    required this.recordDates,
  });

  @override
  State<CalendarPickerDialog> createState() => _CalendarPickerDialogState();
}

class _CalendarPickerDialogState extends State<CalendarPickerDialog> {
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
                // 미래 날짜 선택 차단
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
                // 기록 있는 날짜에 dot 추가
                markerBuilder: (context, day, events) {
                  if (!_hasRecord(day)) return const SizedBox.shrink();
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
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
                // 미래 날짜 흐리게
                outsideDaysVisible: false,
              ),
            ),
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
