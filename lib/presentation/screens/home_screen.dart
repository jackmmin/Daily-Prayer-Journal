// lib/presentation/screens/home_screen.dart
//
// 앱 첫 진입 홈 화면.
// 기도통장 요약 카드와 주요 기능 메뉴(기도 일지, 기도통장 계획)를 제공한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bank_plan_provider.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/bank_summary_card.dart';
import '../widgets/home/menu_card.dart';
import '../widgets/home/motivation_card.dart';
import 'bank_plan_screen.dart';

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
              HomeHeader(today: today),
              const Gap(20),
              BankSummaryCard(plansAsync: plansAsync),
              const Gap(24),
              Text(
                '메뉴',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Colors.grey.shade600, letterSpacing: 0.5),
              ),
              const Gap(12),
              HomeMenuCard(
                icon: Icons.savings_outlined,
                label: '기도통장 계획',
                description: '적립 계획 등록 · 관리',
                color: Colors.teal,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BankPlanScreen()),
                ),
              ),
              const Gap(20),
              MotivationCard(plansAsync: plansAsync),
            ],
          ),
        ),
      ),
    );
  }
}
