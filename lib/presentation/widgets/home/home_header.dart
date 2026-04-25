// lib/presentation/widgets/home/home_header.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// 홈 화면 상단 인사 + 날짜 헤더
class HomeHeader extends StatelessWidget {
  final String today;
  const HomeHeader({super.key, required this.today});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wb_sunny_outlined, color: color, size: 22),
            const Gap(6),
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
