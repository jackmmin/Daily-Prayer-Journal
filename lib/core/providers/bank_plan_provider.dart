// lib/core/providers/bank_plan_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/datasources/local/database_helper.dart';
import '../../data/models/bank_plan_model.dart';
import '../../domain/entities/bank_plan.dart';
import '../../domain/entities/prayer_record.dart';
import '../../domain/usecases/prayer_usecases.dart';
import '../di/injection_container.dart';

// ─── Repository ─────────────────────────────────────────────────────────────

class BankPlanRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<BankPlan>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      BankPlanModel.tableName,
      orderBy: '${BankPlanModel.columnStartDate} DESC',
    );
    return rows.map(BankPlanModel.fromMap).toList();
  }

  Future<int> insert(BankPlan plan) async {
    final db = await _db;
    return db.insert(BankPlanModel.tableName, BankPlanModel.toMap(plan));
  }

  Future<void> update(BankPlan plan) async {
    final db = await _db;
    await db.update(
      BankPlanModel.tableName,
      BankPlanModel.toMap(plan),
      where: '${BankPlanModel.columnId} = ?',
      whereArgs: [plan.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(
      BankPlanModel.tableName,
      where: '${BankPlanModel.columnId} = ?',
      whereArgs: [id],
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class BankPlanNotifier extends StateNotifier<AsyncValue<List<BankPlan>>> {
  final BankPlanRepository _repo;

  BankPlanNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final plans = await _repo.getAll();
      state = AsyncValue.data(plans);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(BankPlan plan) async {
    await _repo.insert(plan);
    await load();
  }

  Future<void> edit(BankPlan plan) async {
    await _repo.update(plan);
    await load();
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    await load();
  }
}

final _bankPlanRepoProvider = Provider((_) => BankPlanRepository());

final bankPlanProvider =
    StateNotifierProvider<BankPlanNotifier, AsyncValue<List<BankPlan>>>((ref) {
  return BankPlanNotifier(ref.read(_bankPlanRepoProvider));
});

// ─── 계획별 누적 금액 계산 ────────────────────────────────────────────────────

/// 특정 계획의 기간 내 기도 기록만 집계해 적립 금액을 반환한다.
final planSavingsProvider =
    FutureProvider.family<int, BankPlan>((ref, plan) async {
  // bankPlanProvider 변경 시 재계산
  ref.watch(bankPlanProvider);

  final allRecords = await sl<GetAllPrayerRecordsUseCase>().execute();
  final start = _dateOnly(plan.startDate);
  final end = _dateOnly(plan.endDate).add(const Duration(days: 1)); // 종료일 포함

  int totalSeconds = 0;
  for (final PrayerRecord record in allRecords) {
    // 기도 시작 시간이 계획 기간에 포함되는 기록만 집계
    if (!record.startTime.isBefore(start) && record.startTime.isBefore(end)) {
      final duration = record.prayerDuration;
      if (duration != null && !duration.isNegative) {
        totalSeconds += duration.inSeconds;
      }
    }
  }

  return plan.calcEarned(totalSeconds);
});

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
