// lib/presentation/widgets/prayer_list/plan_info_header.dart

import 'package:flutter/material.dart';

import '../../../domain/entities/bank_plan.dart';

/// 기도일지 목록 상단 계획 정보 헤더
class PlanInfoHeader extends StatelessWidget {
  final BankPlan plan;

  const PlanInfoHeader({super.key, required this.plan});

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
