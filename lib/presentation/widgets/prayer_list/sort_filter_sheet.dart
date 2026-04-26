// lib/presentation/widgets/prayer_list/sort_filter_sheet.dart

import 'package:flutter/material.dart';

import '../../viewmodels/prayer_list_viewmodel.dart';

/// 기도일지 목록 정렬 선택 바텀시트
class SortFilterSheet extends StatelessWidget {
  final PrayerSortOrder current;
  final ValueChanged<PrayerSortOrder> onSelected;

  const SortFilterSheet({
    super.key,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '정렬 기준',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...PrayerSortOrder.values.map((order) {
            final selected = order == current;
            return ListTile(
              title: Text(order.label),
              trailing: selected
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () => onSelected(order),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
