// lib/presentation/widgets/bank_plan/import_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/bank_plan.dart';

/// 가져오기 방법 선택 바텀 시트
class ImportBottomSheet extends StatelessWidget {
  final VoidCallback onImport;
  final VoidCallback onSample;

  const ImportBottomSheet({super.key, required this.onImport, required this.onSample});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file_outlined, color: color),
                const Gap(8),
                Text(
                  '계획 가져오기',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(8),
            Text(
              '이 앱에서 내보낸 엑셀 파일(.xlsx)로 계획을 가져옵니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const Gap(20),
            _OptionTile(
              icon: Icons.folder_open_outlined,
              color: color,
              title: '내 기기에서 파일 가져오기',
              subtitle: '기존에 내보낸 .xlsx 파일을 선택합니다',
              onTap: onImport,
            ),
            const Gap(12),
            _OptionTile(
              icon: Icons.download_outlined,
              color: Colors.green.shade600,
              title: '샘플 엑셀 파일 다운로드',
              subtitle: '양식을 확인하고 직접 수정해 가져올 수 있습니다',
              onTap: onSample,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const Gap(2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

/// 가져올 계획 내용 확인 다이얼로그
class ImportConfirmDialog extends StatelessWidget {
  final BankPlan plan;

  const ImportConfirmDialog({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy년 M월 d일');

    return AlertDialog(
      title: const Text('계획 가져오기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('아래 계획을 추가하시겠습니까?', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const Gap(16),
          _InfoRow(label: '계획명', value: plan.title.isNotEmpty ? plan.title : '(이름 없음)'),
          const Gap(6),
          _InfoRow(label: '시작일', value: dateFmt.format(plan.startDate)),
          const Gap(6),
          _InfoRow(label: '종료일', value: dateFmt.format(plan.endDate)),
          const Gap(6),
          _InfoRow(label: '기도 기준', value: '${plan.minutes}분 → ${_fmt(plan.amount)}원'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('가져오기'),
        ),
      ],
    );
  }

  static String _fmt(int v) =>
      v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
