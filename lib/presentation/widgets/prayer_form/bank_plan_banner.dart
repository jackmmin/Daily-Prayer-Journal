// lib/presentation/widgets/prayer_form/bank_plan_banner.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../domain/entities/bank_plan.dart';

/// 기도 기록 폼 상단 기도통장 계획 정보 배너
class BankPlanBanner extends StatelessWidget {
  final BankPlan plan;
  const BankPlanBanner({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final dateFmt = '${plan.startDate.year}년 ${plan.startDate.month}월 ${plan.startDate.day}일'
        ' ~ ${plan.endDate.year}년 ${plan.endDate.month}월 ${plan.endDate.day}일';
    final amountStr = plan.amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_outlined, color: color, size: 22),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '기도통장 계획',
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                ),
                const Gap(2),
                Text(dateFmt, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                Text(
                  '${plan.minutes}분 기도 → $amountStr원 적립',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
