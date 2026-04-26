// lib/presentation/widgets/prayer_list/plan_info_header.dart

import 'package:flutter/material.dart';

import '../../../domain/entities/bank_plan.dart';

/// 기도일지 목록 상단 계획 정보 헤더
class PlanInfoHeader extends StatelessWidget {
  final BankPlan plan;

  const PlanInfoHeader({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.primaryContainer,
      child: Text(
        plan.title.isNotEmpty ? plan.title : '기도통장 계획',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
