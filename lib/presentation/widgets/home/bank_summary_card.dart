// lib/presentation/widgets/home/bank_summary_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/bank_plan_provider.dart';
import '../../../domain/entities/bank_plan.dart';
import '../../screens/bank_plan_screen.dart';
import '../../screens/prayer_list_screen.dart';

/// 기도통장 요약 카드 (진행 중인 계획 목록 또는 빈 상태 표시)
class BankSummaryCard extends ConsumerWidget {
  final AsyncValue<List<BankPlan>> plansAsync;
  const BankSummaryCard({super.key, required this.plansAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return plansAsync.when(
      loading: () => _buildShell(context, const _SummaryLoading(), onTap: null),
      error: (_, __) => _buildShell(context, const _SummaryError(), onTap: null),
      data: (plans) {
        final active = plans.where((p) => p.isActive).toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

        if (active.isEmpty) {
          return _buildShell(
            context,
            _SummaryNoPlan(allPlans: plans),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BankPlanScreen()),
            ),
          );
        }

        return Column(
          children: [
            for (int i = 0; i < active.length; i++) ...[
              if (i > 0) const Gap(12),
              _buildShell(
                context,
                _SummaryActivePlan(plan: active[i]),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PrayerListScreen(initialPlan: active[i]),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildShell(BuildContext context, Widget child, {VoidCallback? onTap}) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─── 진행 중인 계획 ────────────────────────────────────────────────────────────

class _SummaryActivePlan extends ConsumerWidget {
  final BankPlan plan;
  const _SummaryActivePlan({required this.plan});

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
          ],
        ),
        const Gap(12),
        savingsAsync.when(
          data: (amount) => Text(
            '${_formatAmount(amount)}원',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
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
}

// ─── 계획 없음 ────────────────────────────────────────────────────────────────

class _SummaryNoPlan extends StatelessWidget {
  final List<BankPlan> allPlans;
  const _SummaryNoPlan({required this.allPlans});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.savings_outlined, color: Colors.white60, size: 40),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('기도통장', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const Gap(4),
              Text(
                allPlans.isEmpty ? '계획을 등록해보세요' : '진행 중인 계획이 없습니다',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(4),
              const Text(
                '탭하여 계획 등록하기 →',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
    );
  }
}

class _SummaryError extends StatelessWidget {
  const _SummaryError();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.error_outline, color: Colors.white60, size: 28),
        Gap(12),
        Text('불러오기 실패', style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}

// ─── 공통 유틸 ────────────────────────────────────────────────────────────────

String _formatAmount(int amount) => amount
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
