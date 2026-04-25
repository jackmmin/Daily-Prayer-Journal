// lib/presentation/widgets/calendar/range_banner.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// 캘린더 다이얼로그 선택 범위 + 미리보기 배너
class RangeBanner extends StatelessWidget {
  final DateTime start;
  final DateTime? end;
  final String? previewTitle;
  final bool isLoading;

  const RangeBanner({
    super.key,
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
        child: CircularProgressIndicator(strokeWidth: 1.5, color: colorScheme.primary),
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
