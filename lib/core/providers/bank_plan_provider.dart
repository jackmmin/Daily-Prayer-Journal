// lib/core/providers/bank_plan_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/datasources/local/database_helper.dart';
import '../../data/models/bank_plan_model.dart';
import '../../domain/entities/bank_plan.dart';
import '../../domain/entities/prayer_record.dart';
import '../../domain/usecases/prayer_usecases.dart';
import '../di/injection_container.dart';

// ─── 정렬 기준 ────────────────────────────────────────────────────────────────

enum BankPlanSortOrder {
  startDateDesc, // 시작일 최신순 (기본값)
  startDateAsc,  // 시작일 오래된순
  titleAsc,      // 이름 오름차순
  amountDesc,    // 금액 높은순
  amountAsc,     // 금액 낮은순
}

extension BankPlanSortOrderExt on BankPlanSortOrder {
  String get label {
    switch (this) {
      case BankPlanSortOrder.startDateDesc: return '시작일 최신순';
      case BankPlanSortOrder.startDateAsc:  return '시작일 오래된순';
      case BankPlanSortOrder.titleAsc:      return '이름순';
      case BankPlanSortOrder.amountDesc:    return '금액 높은순';
      case BankPlanSortOrder.amountAsc:     return '금액 낮은순';
    }
  }

  String get orderBy {
    switch (this) {
      case BankPlanSortOrder.startDateDesc: return '${BankPlanModel.columnStartDate} DESC';
      case BankPlanSortOrder.startDateAsc:  return '${BankPlanModel.columnStartDate} ASC';
      case BankPlanSortOrder.titleAsc:      return '${BankPlanModel.columnTitle} ASC';
      case BankPlanSortOrder.amountDesc:    return '${BankPlanModel.columnAmount} DESC';
      case BankPlanSortOrder.amountAsc:     return '${BankPlanModel.columnAmount} ASC';
    }
  }
}

// ─── Repository ─────────────────────────────────────────────────────────────

class BankPlanRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<BankPlan>> getAll({BankPlanSortOrder sortOrder = BankPlanSortOrder.startDateDesc}) async {
    final db = await _db;
    final rows = await db.query(
      BankPlanModel.tableName,
      orderBy: sortOrder.orderBy,
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
  BankPlanSortOrder _sortOrder = BankPlanSortOrder.startDateDesc;

  BankPlanNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  BankPlanSortOrder get sortOrder => _sortOrder;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final plans = await _repo.getAll(sortOrder: _sortOrder);
      state = AsyncValue.data(plans);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setSortOrder(BankPlanSortOrder order) async {
    _sortOrder = order;
    await load();
  }

  Future<void> add(BankPlan plan) async {
    await _repo.insert(plan);
    await load();
  }

  Future<void> edit(BankPlan plan) async {
    await _repo.update(plan);
    await load();
  }

  bool _isDeleting = false;

  Future<bool> remove(int id) async {
    if (_isDeleting) return false;
    _isDeleting = true;
    try {
      await _repo.delete(id);
      await load();
      return true;
    } finally {
      _isDeleting = false;
    }
  }
}

final _bankPlanRepoProvider = Provider((_) => BankPlanRepository());

final bankPlanProvider =
    StateNotifierProvider<BankPlanNotifier, AsyncValue<List<BankPlan>>>((ref) {
  return BankPlanNotifier(ref.read(_bankPlanRepoProvider));
});

// ─── 계획별 누적 금액 계산 ────────────────────────────────────────────────────

/// 특정 계획에 연결된 기도 기록만 집계해 적립 금액을 반환한다.
final planSavingsProvider =
    FutureProvider.family<int, BankPlan>((ref, plan) async {
  // bankPlanProvider 변경 시 재계산
  ref.watch(bankPlanProvider);

  final allRecords = await sl<GetAllPrayerRecordsUseCase>().execute();

  int totalMinutes = 0;
  for (final PrayerRecord record in allRecords) {
    // plan.id로 연결된 기록만 집계 (id null이면 기간 기반 fallback)
    final matched = plan.id != null
        ? record.bankPlanId == plan.id
        : _isInPlanPeriod(record, plan);
    if (matched) {
      final duration = record.prayerDuration;
      if (duration != null && !duration.isNegative) {
        // 초 단위 버림: 분 단위만 금액 계산에 반영
        totalMinutes += duration.inMinutes;
      }
    }
  }

  return plan.calcEarned(totalMinutes * 60);
});

/// 특정 계획에 연결된 기도 기록의 총 누적 시간(분)을 반환한다.
final planTotalMinutesProvider =
    FutureProvider.family<int, BankPlan>((ref, plan) async {
  ref.watch(bankPlanProvider);

  final allRecords = await sl<GetAllPrayerRecordsUseCase>().execute();

  int totalMinutes = 0;
  for (final PrayerRecord record in allRecords) {
    final matched = plan.id != null
        ? record.bankPlanId == plan.id
        : _isInPlanPeriod(record, plan);
    if (matched) {
      final duration = record.prayerDuration;
      if (duration != null && !duration.isNegative) {
        totalMinutes += duration.inMinutes;
      }
    }
  }

  return totalMinutes;
});

/// bankPlanId가 없는 레거시 레코드를 기간으로 매칭
bool _isInPlanPeriod(PrayerRecord record, BankPlan plan) {
  final start = _dateOnly(plan.startDate);
  final end = _dateOnly(plan.endDate).add(const Duration(days: 1));
  return !record.startTime.isBefore(start) && record.startTime.isBefore(end);
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
