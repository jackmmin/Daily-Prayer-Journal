// lib/presentation/widgets/prayer_record_card.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/prayer_record.dart';

class PrayerRecordCard extends StatelessWidget {
  final PrayerRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  /// 다중 선택 모드 활성 여부
  final bool isSelectMode;
  /// 현재 카드가 선택된 상태인지
  final bool isSelected;
  /// 꾹 눌렀을 때 콜백 (선택 모드 시작)
  final VoidCallback? onLongPress;

  const PrayerRecordCard({
    super.key,
    required this.record,
    required this.onTap,
    required this.onDelete,
    this.isSelectMode = false,
    this.isSelected = false,
    this.onLongPress,
  });

  static final _dateTimeFormat = DateFormat('M월d일 HH:mm');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      // 선택된 카드는 테두리 강조
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.primary, width: 2),
            )
          : null,
      color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 선택 모드일 때 체크박스 표시
                  if (isSelectMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap(),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      record.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 선택 모드가 아닐 때만 삭제 버튼 표시
                  if (!isSelectMode)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red.shade300,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              if (record.content.isNotEmpty) ...[
                const Gap(4),
                Text(
                  record.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Gap(6),
              const Divider(height: 1),
              const Gap(6),
              _buildTimeRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(BuildContext context) {
    final duration = record.prayerDuration;

    return Row(
      children: [
        const Icon(Icons.access_time, size: 14, color: Colors.grey),
        const Gap(4),
        Text(
          _dateTimeFormat.format(record.startTime),
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        if (record.endTime != null) ...[
          const Text(' → ', style: TextStyle(color: Colors.grey)),
          Text(
            _dateTimeFormat.format(record.endTime!),
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
        const Spacer(),
        if (duration != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDuration(duration),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) => '${duration.inMinutes}분';
}
