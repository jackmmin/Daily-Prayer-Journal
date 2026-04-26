// lib/presentation/widgets/calendar/calendar_table.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/providers/marker_color_provider.dart';

/// CalendarPickerDialog 내부의 TableCalendar 래퍼.
/// 상태는 부모에서 관리하고 이 위젯은 순수 표시/이벤트 전달 역할만 담당한다.
class CalendarTable extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime rangeStart;
  final DateTime? rangeEnd;
  final bool allowFuture;
  final DateTime? colorEditingDate;
  final MarkerColorNotifier markerNotifier;
  final bool Function(DateTime) hasRecord;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;

  const CalendarTable({
    super.key,
    required this.focusedDay,
    required this.rangeStart,
    required this.rangeEnd,
    required this.allowFuture,
    required this.colorEditingDate,
    required this.markerNotifier,
    required this.hasRecord,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TableCalendar(
      locale: 'ko_KR',
      focusedDay: focusedDay,
      firstDay: DateTime(2000),
      lastDay: allowFuture ? DateTime(2100) : DateTime.now(),
      rangeStartDay: rangeStart,
      rangeEndDay: rangeEnd,
      rangeSelectionMode: rangeEnd != null
          ? RangeSelectionMode.enforced
          : RangeSelectionMode.disabled,
      selectedDayPredicate: (day) =>
          rangeEnd == null && isSameDay(day, rangeStart),
      onDaySelected: onDaySelected,
      onRangeSelected: null,
      onPageChanged: onPageChanged,
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (!hasRecord(day)) return const SizedBox.shrink();
          final color = markerNotifier.colorFor(day);
          final isEditing =
              colorEditingDate != null && isSameDay(colorEditingDate!, day);
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
        // rangeEnd가 null일 때 범위 내 기본 highlight 방지
        withinRangeBuilder: rangeEnd != null
            ? null
            : (context, day, _) => Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
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
    );
  }
}
