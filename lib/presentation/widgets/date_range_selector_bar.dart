// lib/presentation/widgets/date_range_selector_bar.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeSelectorBar extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  /// null이면 다음 버튼 비활성화 안 함
  final bool disableNext;

  const DateRangeSelectorBar({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onPrev,
    required this.onNext,
    this.disableNext = false,
  });

  static final _fmt = DateFormat('M월 d일', 'ko');

  String get _label {
    final s = _fmt.format(startDate);
    final e = _fmt.format(endDate);
    // 같은 날짜면 단일 날짜만 표시
    return s == e ? s : '$s ~ $e';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Text(
            _label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          IconButton(
            onPressed: disableNext ? null : onNext,
            icon: Icon(
              Icons.chevron_right,
              color: disableNext ? Colors.white38 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
