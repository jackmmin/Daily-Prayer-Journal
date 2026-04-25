// lib/presentation/screens/bank_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bank_plan_provider.dart';
import '../../domain/entities/bank_plan.dart';

class BankPlanScreen extends ConsumerWidget {
  const BankPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(bankPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기도통장 계획'),
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (plans) => plans.isEmpty
            ? _buildEmpty(context)
            : _buildList(context, ref, plans),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('계획 추가'),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.savings_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
          ),
          const Gap(16),
          Text(
            '기도통장 계획이 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const Gap(8),
          Text(
            '+ 계획 추가 버튼으로 시작하세요',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<BankPlan> plans) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: plans.length,
      itemBuilder: (context, index) =>
          _PlanCard(plan: plans[index], ref: ref, onEdit: () => _openForm(context, ref, plans[index])),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, BankPlan? plan) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PlanFormSheet(plan: plan),
    );
  }
}

// ─── 계획 카드 ────────────────────────────────────────────────────────────────

class _PlanCard extends ConsumerWidget {
  final BankPlan plan;
  final WidgetRef ref;
  final VoidCallback onEdit;

  const _PlanCard({required this.plan, required this.ref, required this.onEdit});

  static final _dateFmt = DateFormat('yyyy년 M월 d일');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.primary;
    final savingsAsync = ref.watch(planSavingsProvider(plan));
    final isActive = plan.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isActive
            ? BorderSide(color: color, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '진행 중',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                Expanded(
                  child: Text(
                    '${_dateFmt.format(plan.startDate)} ~ ${_dateFmt.format(plan.endDate)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') _confirmDelete(context, ref);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('수정')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('삭제', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const Gap(8),
            Text(
              '${plan.minutes}분 기도 → ${_formatAmount(plan.amount)}원 적립',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const Gap(10),
            const Divider(height: 1),
            const Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('누적 기도통장', style: TextStyle(fontSize: 13, color: Colors.grey)),
                savingsAsync.when(
                  data: (amount) => Text(
                    '${_formatAmount(amount)}원',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text('계산 오류', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('계획 삭제'),
        content: const Text('이 기도통장 계획을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true && plan.id != null) {
      await ref.read(bankPlanProvider.notifier).remove(plan.id!);
    }
  }

  String _formatAmount(int amount) => amount
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ─── 계획 추가/수정 BottomSheet ───────────────────────────────────────────────

class _PlanFormSheet extends ConsumerStatefulWidget {
  final BankPlan? plan;
  const _PlanFormSheet({this.plan});

  @override
  ConsumerState<_PlanFormSheet> createState() => _PlanFormSheetState();
}

class _PlanFormSheetState extends ConsumerState<_PlanFormSheet> {
  static final _dateFmt = DateFormat('yyyy년 M월 d일');

  late DateTime _startDate;
  late DateTime _endDate;
  late TextEditingController _minutesCtrl;
  late TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    final today = DateTime.now();
    _startDate = p?.startDate ?? DateTime(today.year, today.month, today.day);
    _endDate = p?.endDate ?? DateTime(today.year, today.month + 1, today.day);
    _minutesCtrl = TextEditingController(text: (p?.minutes ?? 1).toString());
    _amountCtrl = TextEditingController(text: (p?.amount ?? 100).toString());
  }

  @override
  void dispose() {
    _minutesCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        // 시작일이 종료일보다 늦으면 종료일을 시작일로 맞춤
        if (_startDate.isAfter(_endDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_endDate.isBefore(_startDate)) _startDate = _endDate;
      }
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

          // 날짜 선택
          Row(
            children: [
              Expanded(child: _dateTile(label: '시작일', date: _startDate, onTap: () => _pickDate(isStart: true))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('~', style: TextStyle(fontSize: 18)),
              ),
              Expanded(child: _dateTile(label: '종료일', date: _endDate, onTap: () => _pickDate(isStart: false))),
            ],
          ),
          const Gap(20),

          // 분/금액 입력
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
