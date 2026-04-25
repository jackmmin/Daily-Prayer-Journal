// lib/presentation/widgets/time_picker_field.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final base = time ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      // 기기 설정과 무관하게 24시간 형식으로 표시
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (pickedTime == null) return;

    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    onChanged(result);
  }
}
