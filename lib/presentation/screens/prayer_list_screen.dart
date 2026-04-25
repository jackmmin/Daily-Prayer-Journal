// lib/presentation/screens/prayer_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/bank_plan_provider.dart';
import '../../domain/entities/bank_plan.dart';
import '../../domain/entities/prayer_record.dart';
import '../viewmodels/prayer_list_viewmodel.dart';
import '../widgets/prayer_record_card.dart';
import '../widgets/date_selector_bar.dart';
import '../widgets/calendar_picker_dialog.dart';
import '../widgets/prayer_bank_banner.dart';
import 'prayer_form_screen.dart';

class PrayerListScreen extends ConsumerStatefulWidget {
  /// null이면 전체 기록, 지정하면 해당 계획 날짜로 초기 이동
  final BankPlan? initialPlan;

  const PrayerListScreen({super.key, this.initialPlan});

  @override
  ConsumerState<PrayerListScreen> createState() => _PrayerListScreenState();
}

class _PrayerListScreenState extends ConsumerState<PrayerListScreen> {
  late final int? _bankPlanId;

  @override
  void initState() {
    super.initState();
    _bankPlanId = widget.initialPlan?.id;
    // 계획이 지정된 경우 계획 시작일(또는 오늘)로 날짜 이동
    if (widget.initialPlan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final plan = widget.initialPlan!;
        final today = DateTime.now();
        final target = today.isAfter(plan.startDate) && !today.isAfter(plan.endDate)
            ? today
            : plan.startDate;
        ref.read(prayerListViewModelProvider(_bankPlanId).notifier).changeDate(target);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prayerListViewModelProvider(_bankPlanId));
    final vm = ref.read(prayerListViewModelProvider(_bankPlanId).notifier);
    final plansAsync = ref.watch(bankPlanProvider);

    // 계획이 지정된 경우 해당 계획 기간만, 아니면 전체 계획 기간 기준으로 체크
    final bool canAddRecord = plansAsync.maybeWhen(
      data: (plans) {
        if (widget.initialPlan != null) {
          return _isDateInPlan(state.selectedDate, widget.initialPlan!);
        }
        return _isDateInAnyPlan(state.selectedDate, plans);
      },
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('기도 일지'),
      ),
      body: Column(
        children: [
          if (widget.initialPlan != null) _PlanInfoHeader(plan: widget.initialPlan!),
          const PrayerBankBanner(),
          DateSelectorBar(
            selectedDate: state.selectedDate,
            onDateChanged: vm.changeDate,
          ),
          Expanded(
            child: _buildBody(context, state, vm, canAddRecord),
          ),
        ],
      ),
      // 캘린더(좌) + 기도 기록(우) 버튼을 같은 라인에 배치
      bottomNavigationBar: _BottomActionBar(
        selectedDate: state.selectedDate,
        recordDates: state.recordDates,
        onDateChanged: vm.changeDate,
        canAddRecord: canAddRecord,
        onAddRecord: () => _navigateToForm(context),
      ),
    );
  }

  /// 선택된 날짜가 특정 계획 기간에 포함되는지 확인
  bool _isDateInPlan(DateTime date, BankPlan plan) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(plan.startDate.year, plan.startDate.month, plan.startDate.day);
    final end = DateTime(plan.endDate.year, plan.endDate.month, plan.endDate.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// 선택된 날짜가 하나 이상의 계획 기간에 포함되는지 확인
  bool _isDateInAnyPlan(DateTime date, List<BankPlan> plans) {
    if (plans.isEmpty) return false;
    return plans.any((plan) => _isDateInPlan(date, plan));
  }

  Widget _buildBody(
    BuildContext context,
    PrayerListState state,
    PrayerListViewModel vm,
    bool canAddRecord,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(state.errorMessage!),
            TextButton(onPressed: vm.loadRecords, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (state.records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canAddRecord ? Icons.church_outlined : Icons.lock_outline,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              canAddRecord ? '기도 기록이 없습니다' : '기도통장 계획이 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              canAddRecord
                  ? '+ 버튼을 눌러 기도를 기록해보세요'
                  : '상단 배너에서 기도통장 계획을 먼저 세워주세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.records.length,
        itemBuilder: (context, index) {
          final record = state.records[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PrayerRecordCard(
              record: record,
              onTap: () => _navigateToForm(context, record: record),
              onDelete: () => _confirmDelete(context, vm, record),
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigateToForm(
    BuildContext context, {
    PrayerRecord? record,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrayerFormScreen(
          editingRecord: record,
          bankPlan: widget.initialPlan,
        ),
      ),
    );
    ref.read(prayerListViewModelProvider(_bankPlanId).notifier).loadRecords();
    // 기도 기록 변경 후 누적 금액 재계산
    ref.invalidate(planSavingsProvider);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PrayerListViewModel vm,
    PrayerRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기도 기록 삭제'),
        content: Text('"${record.title}" 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true && record.id != null) {
      await vm.deleteRecord(record.id!);
      ref.invalidate(planSavingsProvider);
    }
  }
}

/// 기도일지 목록 상단 계획 정보 헤더
class _PlanInfoHeader extends StatelessWidget {
  final BankPlan plan;

  const _PlanInfoHeader({required this.plan});

  static String _fmt(DateTime d) => '${d.month}월 ${d.day}일';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.title.isNotEmpty ? plan.title : '기도통장 계획',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_fmt(plan.startDate)} ~ ${_fmt(plan.endDate)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}

/// 하단 액션 바: 좌측 캘린더 버튼 + 우측 기도 기록 버튼
class _BottomActionBar extends StatelessWidget {
  final DateTime selectedDate;
  final Set<DateTime> recordDates;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onAddRecord;

  /// 선택된 날짜에 활성 계획이 있을 때만 true
  final bool canAddRecord;

  const _BottomActionBar({
    required this.selectedDate,
    required this.recordDates,
    required this.onDateChanged,
    required this.canAddRecord,
    required this.onAddRecord,
  });

  Future<void> _openCalendar(BuildContext context) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => CalendarPickerDialog(
        selectedDate: selectedDate,
        recordDates: recordDates,
      ),
    );
    if (picked != null) onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'fab_calendar',
              onPressed: () => _openCalendar(context),
              child: const Icon(Icons.calendar_month_outlined),
            ),
            FloatingActionButton.extended(
              heroTag: 'fab_add',
              // 계획이 없으면 버튼 비활성화
              onPressed: canAddRecord ? onAddRecord : null,
              icon: const Icon(Icons.add),
              label: const Text('기도 기록'),
            ),
          ],
        ),
      ),
    );
  }
}
