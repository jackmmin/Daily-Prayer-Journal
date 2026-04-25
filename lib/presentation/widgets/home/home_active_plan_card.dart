// lib/presentation/widgets/home/home_active_plan_card.dart
// 홈 화면 진행 중인 기도통장 계획 카드 (점3개 메뉴 포함)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/providers/bank_plan_provider.dart';
import '../../../core/services/excel_export_service.dart';
import '../../../domain/entities/bank_plan.dart';
import '../../../domain/usecases/prayer_usecases.dart';
import '../bank_plan_form_sheet.dart';

class HomeActivePlanCard extends ConsumerWidget {
  final BankPlan plan;
  const HomeActivePlanCard({super.key, required this.plan});

  static final _dateFmt = DateFormat('M월 d일');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(planSavingsProvider(plan));

    final today = DateTime.now();
    final totalDays = plan.endDate.difference(plan.startDate).inDays + 1;
    final passedDays = today.difference(plan.startDate).inDays + 1;
    final progress = (passedDays / totalDays).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.savings_outlined, color: Colors.white, size: 22),
            const Gap(8),
            Text(
              plan.title.isNotEmpty ? plan.title : '진행 중인 기도통장',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '진행 중',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            // 점3개 더보기 메뉴
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _openEdit(context);
                if (v == 'delete') _confirmDelete(context, ref);
                if (v == 'export') _exportExcel(context);
              },
              icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
              color: Colors.white,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('수정')),
                PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text('엑셀 다운로드', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('삭제', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        const Gap(12),
        savingsAsync.when(
          data: (amount) => Text(
            '${_formatAmount(amount)}원',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          loading: () => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          error: (_, __) => const Text('계산 오류', style: TextStyle(color: Colors.white70)),
        ),
        const Gap(4),
        Text(
          '${plan.minutes}분 기도 → ${_formatAmount(plan.amount)}원 적립',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const Gap(16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_dateFmt.format(plan.startDate)} ~ ${_dateFmt.format(plan.endDate)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  '$passedDays / $totalDays일',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            const Gap(6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BankPlanFormSheet(plan: plan),
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

  Future<void> _exportExcel(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('엑셀 파일 생성 중...'),
          ],
        ),
      ),
    );

    try {
      final records = await sl<GetPrayerRecordsByDateRangeUseCase>().execute(
        plan.startDate,
        plan.endDate,
        bankPlanId: plan.id,
      );
      if (context.mounted) Navigator.of(context).pop();
      await ExcelExportService.exportPrayerRecords(plan: plan, records: records);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('내보내기 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

String _formatAmount(int amount) => amount
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
