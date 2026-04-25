// lib/presentation/screens/bank_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/providers/bank_plan_provider.dart';
import '../../domain/entities/bank_plan.dart';
import '../widgets/bank_plan_card.dart';
import '../widgets/bank_plan_form_sheet.dart';
import 'prayer_list_screen.dart';

class BankPlanScreen extends ConsumerWidget {
  const BankPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(bankPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기도통장 계획'),
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (plans) => plans.isEmpty
            ? _buildEmpty(context)
            : _buildList(context, ref, plans),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('계획 추가'),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.savings_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
          ),
          const Gap(16),
          Text(
            '기도통장 계획이 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const Gap(8),
          Text(
            '+ 계획 추가 버튼으로 시작하세요',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<BankPlan> plans) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: plans.length,
      itemBuilder: (context, index) => BankPlanCard(
        plan: plans[index],
        onEdit: () => _openForm(context, plans[index]),
        onRecord: () => _openPrayerForm(context, plans[index]),
      ),
    );
  }

  void _openPrayerForm(BuildContext context, BankPlan plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrayerListScreen(initialPlan: plan),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, BankPlan? plan) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BankPlanFormSheet(plan: plan),
    );
  }
}
