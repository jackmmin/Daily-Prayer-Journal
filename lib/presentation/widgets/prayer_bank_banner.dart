// lib/presentation/widgets/prayer_bank_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bank_plan_provider.dart';
import '../../domain/entities/bank_plan.dart';

/// 목록 화면 상단 기도통장 배너.
/// 진행 중인 계획이 있으면 해당 계획의 누적 금액을 표시한다.
class PrayerBankBanner extends ConsumerWidget {
  const PrayerBankBanner({super.key});

  static final _dateFmt = DateFormat('M월 d일');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(bankPlanProvider);
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: plansAsync.when(
        loading: () => const _BannerLoading(),
        error: (_, __) => const _BannerError(),
        data: (plans) {
          final active = plans.where((p) => p.isActive).toList();
          if (active.isEmpty) return const _BannerNoPlan();
          // 진행 중인 계획이 여러 개면 첫 번째만 표시
          return _BannerActivePlan(plan: active.first);
        },
      ),
    );
  }
}

// ─── 진행 중인 계획 표시 ──────────────────────────────────────────────────────

class _BannerActivePlan extends ConsumerWidget {
  final BankPlan plan;
  const _BannerActivePlan({required this.plan});

  static final _dateFmt = DateFormat('M월 d일');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(planSavingsProvider(plan));

    return Row(
      children: [
        const Icon(Icons.savings_outlined, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '기도통장 (${_dateFmt.format(plan.startDate)} ~ ${_dateFmt.format(plan.endDate)})',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 2),
              savingsAsync.when(
                data: (amount) => Text(
                  '${_formatAmount(amount)}원',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                error: (_, __) => const Text('계산 오류', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
        Text(
          '${plan.minutes}분 = ${_formatAmount(plan.amount)}원',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

// ─── 진행 중인 계획 없음 ──────────────────────────────────────────────────────

class _BannerNoPlan extends StatelessWidget {
  const _BannerNoPlan();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.savings_outlined, color: Colors.white60, size: 28),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('기도통장', style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(height: 2),
              Text(
                '진행 중인 계획이 없습니다',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BannerLoading extends StatelessWidget {
  const _BannerLoading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.savings_outlined, color: Colors.white60, size: 28),
        SizedBox(width: 12),
        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      ],
    );
  }
}

class _BannerError extends StatelessWidget {
  const _BannerError();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.savings_outlined, color: Colors.white60, size: 28),
        SizedBox(width: 12),
        Text('기도통장 불러오기 실패', style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}

String _formatAmount(int amount) => amount
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
