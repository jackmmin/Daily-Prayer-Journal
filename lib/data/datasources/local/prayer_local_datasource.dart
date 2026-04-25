// lib/data/datasources/local/prayer_local_datasource.dart

import 'package:sqflite/sqflite.dart';

import '../../models/prayer_record_model.dart';
import '../../../domain/entities/prayer_record.dart';
import 'database_helper.dart';

abstract interface class PrayerLocalDataSource {
  Future<List<PrayerRecord>> getAllRecords();
  /// [bankPlanId]가 null이면 전체, 지정하면 해당 계획의 기록만 반환
  Future<List<PrayerRecord>> getRecordsByDate(DateTime date, {int? bankPlanId});
  Future<PrayerRecord?> getRecordById(int id);
  Future<int> insertRecord(PrayerRecord record);
  Future<void> updateRecord(PrayerRecord record);
  Future<void> deleteRecord(int id);
  /// [bankPlanId]가 null이면 전체, 지정하면 해당 계획의 기록 날짜만 반환
  Future<Set<DateTime>> getRecordDates({int? bankPlanId});
}

class PrayerLocalDataSourceImpl implements PrayerLocalDataSource {
  final DatabaseHelper _databaseHelper;

  const PrayerLocalDataSourceImpl(this._databaseHelper);

  Future<Database> get _db => _databaseHelper.database;

  @override
  Future<List<PrayerRecord>> getAllRecords() async {
    final db = await _db;
    final maps = await db.query(
      PrayerRecordModel.tableName,
      orderBy: '${PrayerRecordModel.columnCreatedAt} DESC',
    );
    return maps.map(PrayerRecordModel.fromMap).toList();
  }

  @override
  Future<List<PrayerRecord>> getRecordsByDate(DateTime date, {int? bankPlanId}) async {
    final db = await _db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final where = StringBuffer(
      '${PrayerRecordModel.columnCreatedAt} >= ? AND ${PrayerRecordModel.columnCreatedAt} < ?',
    );
    final whereArgs = <dynamic>[
      startOfDay.millisecondsSinceEpoch,
      endOfDay.millisecondsSinceEpoch,
    ];

    if (bankPlanId != null) {
      where.write(' AND ${PrayerRecordModel.columnBankPlanId} = ?');
      whereArgs.add(bankPlanId);
    }

    final maps = await db.query(
      PrayerRecordModel.tableName,
      where: where.toString(),
      whereArgs: whereArgs,
      orderBy: '${PrayerRecordModel.columnCreatedAt} DESC',
    );
    return maps.map(PrayerRecordModel.fromMap).toList();
  }

  @override
  Future<PrayerRecord?> getRecordById(int id) async {
    final db = await _db;
    final maps = await db.query(
      PrayerRecordModel.tableName,
      where: '${PrayerRecordModel.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PrayerRecordModel.fromMap(maps.first);
  }

  @override
  Future<int> insertRecord(PrayerRecord record) async {
    final db = await _db;
    return await db.insert(
      PrayerRecordModel.tableName,
      PrayerRecordModel.toMap(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateRecord(PrayerRecord record) async {
    final db = await _db;
    await db.update(
      PrayerRecordModel.tableName,
      PrayerRecordModel.toMap(record),
      where: '${PrayerRecordModel.columnId} = ?',
      whereArgs: [record.id],
    );
  }

  @override
  Future<void> deleteRecord(int id) async {
    final db = await _db;
    await db.delete(
      PrayerRecordModel.tableName,
      where: '${PrayerRecordModel.columnId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Set<DateTime>> getRecordDates({int? bankPlanId}) async {
    final db = await _db;
    final maps = await db.query(
      PrayerRecordModel.tableName,
      columns: [PrayerRecordModel.columnCreatedAt],
      where: bankPlanId != null ? '${PrayerRecordModel.columnBankPlanId} = ?' : null,
      whereArgs: bankPlanId != null ? [bankPlanId] : null,
    );
    return maps.map((row) {
      final ms = row[PrayerRecordModel.columnCreatedAt] as int;
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateTime(dt.year, dt.month, dt.day);
    }).toSet();
  }
}
