// lib/presentation/screens/home_screen.dart
//
// 앱 첫 진입 홈 화면.
// 기도통장 요약 카드와 주요 기능 메뉴(기도 일지, 기도통장 계획)를 제공한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bank_plan_provider.dart';
import '../../domain/entities/bank_plan.dart';
import 'bank_plan_screen.dart';
import 'prayer_list_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(bankPlanProvider);
    final today = DateFormat('yyyy년 M월 d일 (E)', 'ko').format(DateTime.now());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 인사 & 날짜 ─────────────────────────────────────────────
              _HomeHeader(today: today),
              const Gap(20),

              // ── 기도통장 요약 카드 ────────────────────────────────────────
              _BankSummaryCard(plansAsync: plansAsync),
              const Gap(24),

              // ── 메뉴 그리드 ──────────────────────────────────────────────
              Text(
                '메뉴',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Colors.grey.shade600, letterSpacing: 0.5),
              ),
              const Gap(12),
              // 기도통장 계획
              _MenuCard(
                icon: Icons.savings_outlined,
                label: '기도통장 계획',
                description: '적립 계획 등록 · 관리',
                color: Colors.teal,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BankPlanScreen()),
                ),
              ),
              const Gap(20),

              // ── 오늘의 말씀 또는 격려 문구 ───────────────────────────────
              _MotivationCard(plansAsync: plansAsync),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 상단 인사 헤더 ─────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final String today;
  const _HomeHeader({required this.today});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wb_sunny_outlined, color: color, size: 22),
            const Gap(8),
            Text(
              today,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Gap(6),
        Text(
          '기도통장',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          '기도로 채우는 나만의 통장',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
        ),
      ],
    );
  }
}

// ─── 기도통장 요약 카드 ──────────────────────────────────────────────────────────

class _BankSummaryCard extends ConsumerWidget {
  final AsyncValue<List<BankPlan>> plansAsync;
  const _BankSummaryCard({required this.plansAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.primary;

    // 진행 중인 계획이 있으면 해당 계획의 기도일지 목록으로, 없으면 계획 관리 화면으로 이동
    final activePlan = plansAsync.maybeWhen(
      data: (plans) => plans.where((p) => p.isActive).firstOrNull,
      orElse: () => null,
    );

    return GestureDetector(
      onTap: () {
        if (activePlan != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PrayerListScreen(initialPlan: activePlan),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BankPlanScreen()),
          );
        }
      },
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
        child: plansAsync.when(
          loading: () => const _SummaryLoading(),
          error: (_, __) => const _SummaryError(),
          data: (plans) {
            final active = plans.where((p) => p.isActive).toList();
            if (active.isEmpty) {
              return _SummaryNoPlan(allPlans: plans);
            }
            return _SummaryActivePlan(plan: active.first);
          },
        ),
      ),
    );
  }
}

// 진행 중인 계획 표시
class _SummaryActivePlan extends ConsumerWidget {
  final BankPlan plan;
  const _SummaryActivePlan({required this.plan});

  static final _dateFmt = DateFormat('M월 d일');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(planSavingsProvider(plan));

    // 전체 기간 대비 오늘까지 진행률
    final today = DateTime.now();
    final start = plan.startDate;
    final end = plan.endDate;
    final totalDays = end.difference(start).inDays + 1;
    final passedDays = today.difference(start).inDays + 1;
    final progress = (passedDays / totalDays).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.savings_outlined, color: Colors.white, size: 22),
            const Gap(8),
            const Text(
              '진행 중인 기도통장',
              style: TextStyle(color: Colors.white70, fontSize: 12),
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

        // 누적 금액
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

        // 기간 진행 바
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_dateFmt.format(start)} ~ ${_dateFmt.format(end)}',
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

// 계획 없음 표시
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
              const Text(
                '기도통장',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
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

// ─── 메뉴 카드 ───────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const Gap(12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Gap(4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 격려 / 동기 카드 ──────────────────────────────────────────────────────────

class _MotivationCard extends ConsumerWidget {
  final AsyncValue<List<BankPlan>> plansAsync;
  const _MotivationCard({required this.plansAsync});

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

// ─── 공통 유틸 ───────────────────────────────────────────────────────────────────

String _formatAmount(int amount) => amount
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
