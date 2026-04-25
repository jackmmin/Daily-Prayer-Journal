// lib/presentation/widgets/date_selector_bar.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class DateSelectorBar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const DateSelectorBar({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  static final _dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko');

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(selectedDate);

    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => onDateChanged(
              selectedDate.subtract(const Duration(days: 1)),
            ),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Column(
            children: [
              Text(
                _dateFormat.format(selectedDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '오늘',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: isToday
                ? null
                : () => onDateChanged(
                      selectedDate.add(const Duration(days: 1)),
                    ),
            icon: Icon(
              Icons.chevron_right,
              color: isToday ? Colors.white38 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
