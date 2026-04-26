// lib/presentation/widgets/time_picker_field.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'date_time_picker_sheet.dart';

/// 날짜/시간 선택 입력 필드 — 탭 시 드럼롤 바텀시트(DateTimePickerSheet) 오픈
class TimePickerField extends StatelessWidget {
  final String label;
  final DateTime? time;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onCleared;
  final bool nullable;

  const TimePickerField({
    super.key,
    required this.label,
    required this.time,
    required this.onChanged,
    this.onCleared,
    this.nullable = false,
  });

  static final _formatter = DateFormat('yyyy.MM.dd HH:mm');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pickDateTime(context),
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.schedule),
          suffixIcon: (nullable && time != null)
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onCleared,
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          time != null ? _formatter.format(time!) : '탭하여 선택',
          style: TextStyle(
            color: time != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    // 바텀시트 오픈 전 포커스 완전 해제
    FocusManager.instance.primaryFocus?.unfocus();
    final base = time ?? DateTime.now();
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DateTimePickerSheet(initial: base),
    );
    if (!context.mounted) return;
    // 바텀시트 닫힌 후 Flutter가 포커스를 복원하기 전에 강제로 해제
    // — textInputAction.next 자동 이동 방지
    FocusManager.instance.primaryFocus?.unfocus();
    if (result != null) onChanged(result);
  }
}
