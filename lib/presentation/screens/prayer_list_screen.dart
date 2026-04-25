// lib/presentation/screens/prayer_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/bank_plan_provider.dart';
import '../../domain/entities/bank_plan.dart';
import '../../domain/entities/prayer_record.dart';
import '../viewmodels/prayer_list_viewmodel.dart';
import '../widgets/prayer_record_card.dart';
import '../widgets/date_range_selector_bar.dart';
import '../widgets/prayer_bank_banner.dart';
import '../widgets/prayer_list/plan_info_header.dart';
import '../widgets/prayer_list/bottom_action_bar.dart';
import 'prayer_form_screen.dart';

class PrayerListScreen extends ConsumerStatefulWidget {
  /// null이면 전체 기록, 지정하면 해당 계획 기간으로 초기 범위 설정
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
    // Provider가 이전 날짜를 캐시하고 있을 수 있으므로 진입 시 오늘 날짜로 리셋
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = _dateOnly(DateTime.now().toLocal());
      ref.read(prayerListViewModelProvider(_bankPlanId).notifier).changeRange(today, today);
    });
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prayerListViewModelProvider(_bankPlanId));
    final vm = ref.read(prayerListViewModelProvider(_bankPlanId).notifier);
    final plansAsync = ref.watch(bankPlanProvider);

    // 현재 범위 내에 활성 계획이 있는지 확인
    final bool canAddRecord = plansAsync.maybeWhen(
      data: (plans) {
        if (widget.initialPlan != null) {
          return _rangeOverlapsPlan(state.startDate, state.endDate, widget.initialPlan!);
        }
        return plans.any((p) => _rangeOverlapsPlan(state.startDate, state.endDate, p));
      },
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('기도 일지')),
      body: Column(
        children: [
          if (widget.initialPlan != null) PlanInfoHeader(plan: widget.initialPlan!),
          PrayerBankBanner(selectedPlan: widget.initialPlan),
          DateRangeSelectorBar(
            startDate: state.startDate,
            endDate: state.endDate,
            onPrev: vm.movePrev,
            onNext: vm.moveNext,
            disableNext: false,
          ),
          Expanded(child: _buildBody(context, state, vm, canAddRecord)),
        ],
      ),
      bottomNavigationBar: PrayerListBottomActionBar(
        startDate: state.startDate,
        endDate: state.endDate,
        recordDates: state.recordDates,
        onRangeChanged: vm.changeRange,
        canAddRecord: canAddRecord,
        onAddRecord: () => _navigateToForm(context),
      ),
    );
  }

  /// 범위가 계획 기간과 하루라도 겹치는지 확인
  bool _rangeOverlapsPlan(DateTime start, DateTime end, BankPlan plan) {
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    final ps = _dateOnly(plan.startDate);
    final pe = _dateOnly(plan.endDate);
    return !e.isBefore(ps) && !s.isAfter(pe);
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
              Icons.church_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '등록된 기도 일지가 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            if (canAddRecord) ...[
              const SizedBox(height: 8),
              Text(
                '+ 버튼을 눌러 기도를 기록해보세요',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
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

  Future<void> _navigateToForm(BuildContext context, {PrayerRecord? record}) async {
    // 새 기록 작성 시 현재 선택된 날짜를 기본 시작시간 날짜로 전달
    final selectedDate = record == null
        ? ref.read(prayerListViewModelProvider(_bankPlanId)).startDate
        : null;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrayerFormScreen(
          editingRecord: record,
          bankPlan: widget.initialPlan,
          initialDate: selectedDate,
        ),
      ),
    );
    ref.read(prayerListViewModelProvider(_bankPlanId).notifier).loadRecords();
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
