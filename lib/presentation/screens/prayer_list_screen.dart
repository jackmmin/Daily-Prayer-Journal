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
  /// 롱프레스된 카드 (삭제 버튼 표시 대상)
  PrayerRecord? _longPressedRecord;

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

  void _setLongPressed(PrayerRecord? record) {
    setState(() => _longPressedRecord = record);
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

    return PopScope(
      // 선택 모드일 때 뒤로가기는 선택 모드 해제로 처리
      canPop: !state.isSelectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && state.isSelectMode) vm.exitSelectMode();
      },
      child: Scaffold(
      appBar: state.isSelectMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: vm.exitSelectMode,
              ),
              title: Text('${state.selectedIds.length}개 선택'),
              actions: [
                // 전체 선택/해제 버튼
                TextButton(
                  onPressed: vm.toggleSelectAll,
                  child: Text(
                    state.selectedIds.length == state.records.length ? '전체 해제' : '전체 선택',
                  ),
                ),
                // 선택 삭제 버튼
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red.shade400,
                  tooltip: '선택 삭제',
                  onPressed: state.selectedIds.isEmpty
                      ? null
                      : () => _confirmDeleteSelected(context, vm),
                ),
              ],
            )
          : AppBar(
              title: const Text('기도 일지'),
            ),
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
          _DateRangeSummaryBar(
            records: state.records,
            longPressedRecord: _longPressedRecord,
            onDeleteLongPressed: _longPressedRecord == null
                ? null
                : () => _confirmDelete(context, vm, _longPressedRecord!),
            onDismissLongPress: () => _setLongPressed(null),
          ),
          Expanded(child: _buildBody(context, state, vm, canAddRecord)),
        ],
      ),
      bottomNavigationBar: PrayerListBottomActionBar(
        startDate: state.startDate,
        endDate: state.endDate,
        recordDates: state.recordDates,
        onRangeChanged: vm.changeRange,
        canAddRecord: canAddRecord && !state.isSelectMode,
        onAddRecord: () => _navigateToForm(context),
      ),
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
              bankPlan: widget.initialPlan,
              isSelectMode: state.isSelectMode,
              isSelected: record.id != null && state.selectedIds.contains(record.id),
              isLongPressed: _longPressedRecord?.id == record.id,
              onTap: state.isSelectMode
                  ? () { if (record.id != null) vm.toggleSelect(record.id!); }
                  : () {
                      _setLongPressed(null); // 다른 카드 탭 시 롱프레스 해제
                      _navigateToForm(context, record: record);
                    },
              onLongPress: state.isSelectMode || record.id == null
                  ? null
                  : () => _setLongPressed(record),
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

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    PrayerListViewModel vm,
  ) async {
    final count = ref.read(prayerListViewModelProvider(_bankPlanId)).selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기도 기록 삭제'),
        content: Text('선택한 $count개의 기록을 삭제하시겠습니까?'),
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
    if (confirmed == true) {
      await vm.deleteSelected();
      ref.invalidate(planSavingsProvider);
    }
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

/// 날짜 범위 내 조회된 기도 기록의 누적 시간 요약 바.
/// 롱프레스된 카드가 있을 때 오른쪽에 삭제 버튼 표시.
class _DateRangeSummaryBar extends StatelessWidget {
  final List<PrayerRecord> records;
  final PrayerRecord? longPressedRecord;
  final VoidCallback? onDeleteLongPressed;
  final VoidCallback onDismissLongPress;

  const _DateRangeSummaryBar({
    required this.records,
    required this.onDismissLongPress,
    this.longPressedRecord,
    this.onDeleteLongPressed,
  });

  @override
  Widget build(BuildContext context) {
    int totalMinutes = 0;
    for (final r in records) {
      final d = r.prayerDuration;
      if (d != null && !d.isNegative) totalMinutes += d.inMinutes;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDeleteMode = longPressedRecord != null;

    return GestureDetector(
      // 요약 바 탭 시 롱프레스 해제
      onTap: isDeleteMode ? onDismissLongPress : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Text(
              '누적 기도시간',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            const Spacer(),
            if (isDeleteMode)
              // 롱프레스 중: 삭제 버튼 표시
              GestureDetector(
                onTap: onDeleteLongPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        '삭제',
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )
            else
              // 기본: 총 기도시간 표시
              Text(
                '총 기도시간 $totalMinutes분',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
