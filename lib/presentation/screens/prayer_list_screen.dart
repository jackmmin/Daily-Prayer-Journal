// lib/presentation/screens/prayer_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/prayer_record.dart';
import '../viewmodels/prayer_list_viewmodel.dart';
import '../widgets/prayer_record_card.dart';
import '../widgets/date_selector_bar.dart';
import 'prayer_form_screen.dart';

class PrayerListScreen extends ConsumerWidget {
  const PrayerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prayerListViewModelProvider);
    final vm = ref.read(prayerListViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기도 일지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _pickDate(context, ref, state.selectedDate),
          ),
        ],
      ),
      body: Column(
        children: [
          DateSelectorBar(
            selectedDate: state.selectedDate,
            onDateChanged: vm.changeDate,
          ),
          Expanded(
            child: _buildBody(context, ref, state, vm),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('기도 기록'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PrayerListState state,
    PrayerListViewModel vm,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(state.errorMessage!),
            TextButton(onPressed: vm.loadRecords, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (state.records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.church_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '오늘의 기도 기록이 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '+ 버튼을 눌러 기도를 기록해보세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.records.length,
        itemBuilder: (context, index) {
          final record = state.records[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PrayerRecordCard(
              record: record,
              onTap: () => _navigateToForm(context, ref, record: record),
              onDelete: () => _confirmDelete(context, vm, record),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(prayerListViewModelProvider.notifier).changeDate(picked);
    }
  }

  Future<void> _navigateToForm(
    BuildContext context,
    WidgetRef ref, {
    PrayerRecord? record,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrayerFormScreen(editingRecord: record),
      ),
    );
    ref.read(prayerListViewModelProvider.notifier).loadRecords();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PrayerListViewModel vm,
    PrayerRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기도 기록 삭제'),
        content: Text('"${record.title}" 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true && record.id != null) {
      vm.deleteRecord(record.id!);
    }
  }
}
