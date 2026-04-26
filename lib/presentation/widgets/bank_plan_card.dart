// lib/presentation/widgets/bank_plan_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bank_plan_provider.dart';
import '../../core/di/injection_container.dart';
import '../../core/services/excel_export_service.dart';
import '../../domain/entities/bank_plan.dart';
import '../../domain/usecases/prayer_usecases.dart';

class BankPlanCard extends ConsumerWidget {
  final BankPlan plan;
  final VoidCallback onEdit;
  final VoidCallback onRecord;

  const BankPlanCard({
    super.key,
    required this.plan,
    required this.onEdit,
    required this.onRecord,
  });

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
        side: isActive ? BorderSide(color: color, width: 1.5) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onRecord,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (plan.title.isNotEmpty)
                          Text(
                            plan.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        Text(
                          '${_dateFmt.format(plan.startDate)} ~ ${_dateFmt.format(plan.endDate)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: plan.title.isNotEmpty ? Colors.grey.shade600 : null,
                                fontSize: plan.title.isNotEmpty ? 12 : null,
                              ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') _confirmDelete(context, ref);
                      if (v == 'export') _exportExcel(context);
                    },
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
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
              const Gap(10),
              // 기도 기록 안내
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '탭하여 기도 일지 목록 보기',
                    style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
                  ),
                  const Gap(4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: color.withValues(alpha: 0.7)),
                ],
              ),
            ],
          ),
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
      final deleted = await ref.read(bankPlanProvider.notifier).remove(plan.id!);
      if (deleted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('삭제되었습니다.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _exportExcel(BuildContext context) async {
    // 로딩 다이얼로그 표시
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
      // 해당 계획의 전체 기도 기록 조회 (계획 기간 전체)
      final records = await sl<GetPrayerRecordsByDateRangeUseCase>().execute(
        plan.startDate,
        plan.endDate,
        bankPlanId: plan.id,
      );

      if (context.mounted) Navigator.of(context).pop(); // 로딩 닫기

      await ExcelExportService.exportPrayerRecords(plan: plan, records: records);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('내보내기 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static String _formatAmount(int amount) => amount
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
