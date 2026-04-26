// lib/presentation/widgets/prayer_bank_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bank_plan_provider.dart';
import '../../domain/entities/bank_plan.dart';

/// 목록 화면 상단 기도통장 배너.
/// [selectedPlan]이 지정되면 해당 계획을 표시하고, 없으면 활성 계획 중 첫 번째를 표시한다.
class PrayerBankBanner extends ConsumerWidget {
  /// 특정 계획에서 진입한 경우 해당 계획을 직접 전달한다.
  final BankPlan? selectedPlan;

  const PrayerBankBanner({super.key, this.selectedPlan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: _buildContent(ref),
    );
  }

  Widget _buildContent(WidgetRef ref) {
    // 계획이 직접 지정된 경우 provider 조회 없이 바로 표시
    if (selectedPlan != null) {
      return _BannerActivePlan(plan: selectedPlan!);
    }

    final plansAsync = ref.watch(bankPlanProvider);
    return plansAsync.when(
      loading: () => const _BannerLoading(),
      error: (_, __) => const _BannerError(),
      data: (plans) {
        final active = plans.where((p) => p.isActive).toList();
        if (active.isEmpty) return const _BannerNoPlan();
        // 진행 중인 계획이 여러 개면 첫 번째만 표시
        return _BannerActivePlan(plan: active.first);
      },
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
    final totalMinutesAsync = ref.watch(planTotalMinutesProvider(plan));

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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${plan.minutes}분 = ${_formatAmount(plan.amount)}원',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 4),
            totalMinutesAsync.when(
              data: (mins) => Text(
                '총 ${mins}분',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              loading: () => const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
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
