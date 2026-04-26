// lib/presentation/widgets/color_range_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/marker_color_provider.dart';

/// 조회된 날짜 범위 전체에 단일 색상을 일괄 적용하는 다이얼로그.
/// 달력 없이 색상 팔레트만 표시하며, 개별 날짜 선택 불가.
class ColorRangeDialog extends ConsumerStatefulWidget {
  /// 조회 범위 내 기록이 있는 날짜들
  final List<DateTime> recordDates;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  const ColorRangeDialog({
    super.key,
    required this.recordDates,
    required this.rangeStart,
    required this.rangeEnd,
  });

  @override
  ConsumerState<ColorRangeDialog> createState() => _ColorRangeDialogState();
}

class _ColorRangeDialogState extends ConsumerState<ColorRangeDialog> {
  /// 현재 선택된 색상 (범위 내 첫 날짜 기준 초기화)
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(markerColorProvider.notifier);
    // 기록 있는 첫 날짜의 현재 색상을 초기값으로 사용
    _selectedColor = widget.recordDates.isNotEmpty
        ? notifier.colorFor(widget.recordDates.first)
        : markerColorOptions.first;
  }

  String _formatRange() {
    final s = widget.rangeStart;
    final e = widget.rangeEnd;
    if (s == e) return '${s.month}/${s.day}';
    return '${s.month}/${s.day} ~ ${e.month}/${e.day}';
  }

  Future<void> _applyColor(Color color) async {
    setState(() => _selectedColor = color);
    final notifier = ref.read(markerColorProvider.notifier);
    // 범위 내 기록 있는 모든 날짜에 동일 색상 적용
    for (final date in widget.recordDates) {
      await notifier.setColor(date, color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = widget.recordDates.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 범위 및 적용 대상 개수
            Text(
              '날짜 색상 지정',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatRange()}  ·  기록 $count개에 동일 색상 적용',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            // 색상 팔레트
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: markerColorOptions.map((color) {
                final isSelected =
                    _selectedColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => _applyColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: colorScheme.onSurface,
                              width: 2.5,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // 닫기 버튼
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
