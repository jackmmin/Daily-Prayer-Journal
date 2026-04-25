// lib/presentation/widgets/home/motivation_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../domain/entities/bank_plan.dart';

/// 홈 화면 하단 격려/동기 메시지 카드
class MotivationCard extends ConsumerWidget {
  final AsyncValue<List<BankPlan>> plansAsync;
  const MotivationCard({super.key, required this.plansAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPlan = plansAsync.maybeWhen(
      data: (plans) => plans.isNotEmpty,
      orElse: () => false,
    );

    final msg = hasPlan
        ? '오늘도 기도로 통장을 채워가세요. 🙏'
        : '기도통장 계획을 등록하면\n기도 시간만큼 적립금이 쌓입니다.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_quote, color: Colors.grey, size: 20),
          const Gap(12),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
