// lib/presentation/screens/bank_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/providers/bank_plan_provider.dart';
import '../../core/services/excel_import_service.dart';
import '../../core/utils/toast_utils.dart';
import '../../domain/entities/bank_plan.dart';
import '../widgets/bank_plan_card.dart';
import '../widgets/bank_plan_form_sheet.dart';
import '../widgets/bank_plan/import_bottom_sheet.dart';
import 'prayer_list_screen.dart';

class BankPlanScreen extends ConsumerWidget {
  const BankPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(bankPlanProvider);
    final notifier = ref.read(bankPlanProvider.notifier);
    final sortOrder = notifier.sortOrder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('기도통장 계획'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: '계획 가져오기',
            onPressed: () => _showImportDialog(context, ref),
          ),
          PopupMenuButton<BankPlanSortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: '정렬',
            initialValue: sortOrder,
            onSelected: (order) => notifier.setSortOrder(order),
            itemBuilder: (_) => BankPlanSortOrder.values.map((order) {
              return PopupMenuItem(
                value: order,
                child: Row(
                  children: [
                    Icon(
                      sortOrder == order ? Icons.check : null,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(order.label),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (plans) => plans.isEmpty
            ? _buildEmpty(context)
            : _buildList(context, ref, plans),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
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
      itemBuilder: (context, index) => BankPlanCard(
        plan: plans[index],
        onEdit: () => _openForm(context, plans[index]),
        onRecord: () => _openPrayerForm(context, plans[index]),
      ),
    );
  }

  void _openPrayerForm(BuildContext context, BankPlan plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrayerListScreen(initialPlan: plan),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, BankPlan? plan) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BankPlanFormSheet(plan: plan),
    );
  }

  /// 가져오기 선택 다이얼로그 표시
  void _showImportDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ImportBottomSheet(
        onImport: () async {
          Navigator.pop(ctx);
          await _importFromFile(context, ref);
        },
        onSample: () async {
          Navigator.pop(ctx);
          await _downloadSample(context);
        },
      ),
    );
  }

  /// 기기 파일에서 계획 가져오기
  Future<void> _importFromFile(BuildContext context, WidgetRef ref) async {
    // 로딩 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('파일 읽는 중...'),
          ],
        ),
      ),
    );

    try {
      final result = await ExcelImportService.pickAndParse();
      if (context.mounted) Navigator.of(context).pop(); // 로딩 닫기

      if (!result.isSuccess) {
        if (context.mounted) showErrorToast(context, result.errorMessage!);
        return;
      }

      if (context.mounted) {
        await _showImportConfirm(context, ref, result.plan!);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        showErrorToast(context, '가져오기 실패: $e');
      }
    }
  }

  /// 파싱된 계획 확인 후 저장 다이얼로그
  Future<void> _showImportConfirm(BuildContext context, WidgetRef ref, BankPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ImportConfirmDialog(plan: plan),
    );

    if (confirmed != true) return;

    // 중복 이름 검사
    final plans = ref.read(bankPlanProvider).valueOrNull ?? [];
    final isDuplicate = plans.any((p) => p.title == plan.title);
    if (isDuplicate && context.mounted) {
      showErrorToast(context, '이미 같은 이름의 계획이 있습니다.');
      return;
    }

    await ref.read(bankPlanProvider.notifier).add(plan);
    if (context.mounted) {
      showSuccessToast(context, '계획을 가져왔습니다.', duration: const Duration(seconds: 3));
    }
  }

  /// 샘플 엑셀 파일 다운로드
  Future<void> _downloadSample(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('샘플 파일 생성 중...'),
          ],
        ),
      ),
    );

    try {
      await ExcelImportService.exportSample();
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        showSuccessToast(context, '샘플 파일을 저장하세요.', duration: const Duration(seconds: 3));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        showErrorToast(context, '샘플 파일 생성 실패: $e');
      }
    }
  }
}

