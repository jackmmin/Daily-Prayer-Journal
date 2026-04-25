// lib/presentation/widgets/prayer_record_card.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/prayer_record.dart';

class PrayerRecordCard extends StatelessWidget {
  final PrayerRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PrayerRecordCard({
    super.key,
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  static final _timeFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                const Gap(6),
                Text(
                  record.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Gap(10),
              const Divider(height: 1),
              const Gap(10),
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
          _timeFormat.format(record.startTime),
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        if (record.endTime != null) ...[
          const Text(' → ', style: TextStyle(color: Colors.grey)),
          Text(
            _timeFormat.format(record.endTime!),
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) return '$hours시간 $minutes분';
    if (minutes > 0) return '$minutes분 $seconds초';
    return '$seconds초';
  }
}
