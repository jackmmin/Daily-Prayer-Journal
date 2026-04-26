// lib/presentation/widgets/prayer_list/bottom_action_bar.dart

import 'package:flutter/material.dart';

import '../calendar_picker_dialog.dart' show CalendarPickerDialog, DateRangeResult;

/// 기도일지 목록 하단 액션 바: 캘린더 버튼 + 기도 기록 추가 버튼
class PrayerListBottomActionBar extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Set<DateTime> recordDates;
  final Future<void> Function(DateTime, DateTime) onRangeChanged;
  final VoidCallback onAddRecord;
  final bool canAddRecord;

  const PrayerListBottomActionBar({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.recordDates,
    required this.onRangeChanged,
    required this.canAddRecord,
    required this.onAddRecord,
  });

  Future<void> _openCalendar(BuildContext context) async {
    final picked = await showDialog<DateRangeResult>(
      context: context,
      builder: (_) => CalendarPickerDialog(
        selectedDate: startDate,
        selectedEndDate: endDate,
        recordDates: recordDates,
        allowFuture: true,
      ),
    );
    if (picked != null) {
      await onRangeChanged(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'fab_calendar',
              onPressed: () => _openCalendar(context),
              child: const Icon(Icons.calendar_month_outlined),
            ),
            FloatingActionButton.extended(
              heroTag: 'fab_add',
              // 기도통장 계획 기간 밖이면 버튼 비활성화
              onPressed: canAddRecord ? onAddRecord : null,
              backgroundColor: canAddRecord ? null : Colors.grey.shade400,
              foregroundColor: canAddRecord ? null : Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('기도 기록'),
            ),
          ],
        ),
      ),
    );
  }
}
