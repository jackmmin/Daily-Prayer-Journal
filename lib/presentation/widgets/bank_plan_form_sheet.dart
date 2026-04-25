// lib/presentation/widgets/bank_plan_form_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bank_plan_provider.dart';
import '../../domain/entities/bank_plan.dart';
import 'calendar_picker_dialog.dart';

class BankPlanFormSheet extends ConsumerStatefulWidget {
  final BankPlan? plan;
  const BankPlanFormSheet({super.key, this.plan});

  @override
  ConsumerState<BankPlanFormSheet> createState() => _BankPlanFormSheetState();
}

class _BankPlanFormSheetState extends ConsumerState<BankPlanFormSheet> {
  static final _dateFmt = DateFormat('yyyy년 M월 d일');

  late DateTime _startDate;
  late DateTime _endDate;
  late TextEditingController _titleCtrl;
  late TextEditingController _minutesCtrl;
  late TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    final today = DateTime.now();
    _startDate = p?.startDate ?? DateTime(today.year, today.month, today.day);
    _endDate = p?.endDate ?? DateTime(today.year, today.month + 1, today.day);
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _minutesCtrl = TextEditingController(text: (p?.minutes ?? 1).toString());
    _amountCtrl = TextEditingController(text: (p?.amount ?? 100).toString());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _minutesCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange({required bool isStart}) async {
    // 탭한 쪽 날짜를 초기 선택일로 열기
    final initialDate = isStart ? _startDate : _endDate;
    final result = await showDialog<DateRangeResult>(
      context: context,
      builder: (_) => CalendarPickerDialog(
        selectedDate: initialDate,
        recordDates: const {},
        allowFuture: true,
      ),
    );
    if (result == null) return;
    setState(() {
      _startDate = result.start;
      _endDate = result.end;
    });
  }

  Future<void> _save() async {
    final minutes = int.tryParse(_minutesCtrl.text.trim());
    final amount = int.tryParse(_amountCtrl.text.trim());

    if (minutes == null || minutes <= 0) {
      _showError('분 단위를 1 이상의 숫자로 입력해주세요.');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('금액을 1 이상의 숫자로 입력해주세요.');
      return;
    }

    final plan = BankPlan(
      id: widget.plan?.id,
      title: _titleCtrl.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      minutes: minutes,
      amount: amount,
    );

    final notifier = ref.read(bankPlanProvider.notifier);
    if (widget.plan == null) {
      await notifier.add(plan);
    } else {
      await notifier.edit(plan);
    }

    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.plan != null;
    final color = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.savings_outlined, color: color),
              const Gap(8),
              Text(
                isEdit ? '계획 수정' : '계획 추가',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Gap(24),
          TextField(
            controller: _titleCtrl,
            maxLength: 20,
            inputFormatters: [LengthLimitingTextInputFormatter(20)],
            decoration: const InputDecoration(
              labelText: '계획 이름 (선택, 최대 20자)',
              hintText: '예) 새벽기도 100일',
              isDense: true,
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(child: _dateTile(label: '시작일', date: _startDate, onTap: () => _pickDateRange(isStart: true))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('~', style: TextStyle(fontSize: 18)),
              ),
              Expanded(child: _dateTile(label: '종료일', date: _endDate, onTap: () => _pickDateRange(isStart: false))),
            ],
          ),
          const Gap(20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _numField(controller: _minutesCtrl, label: '분'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('분 기도 →', style: TextStyle(fontSize: 13)),
              ),
              _numField(controller: _amountCtrl, label: '금액(원)'),
              const Gap(6),
              const Text('원', style: TextStyle(fontSize: 13)),
            ],
          ),
          const Gap(28),
          FilledButton(
            onPressed: _save,
            child: Text(isEdit ? '수정 완료' : '계획 추가'),
          ),
        ],
      ),
    );
  }

  Widget _dateTile({required String label, required DateTime date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const Gap(2),
            Text(_dateFmt.format(date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _numField({required TextEditingController controller, required String label}) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
