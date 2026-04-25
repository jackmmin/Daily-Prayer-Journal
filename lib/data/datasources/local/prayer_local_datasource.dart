// lib/data/datasources/local/prayer_local_datasource.dart

import 'package:sqflite/sqflite.dart';

import '../../models/prayer_record_model.dart';
import '../../../domain/entities/prayer_record.dart';
import 'database_helper.dart';

abstract interface class PrayerLocalDataSource {
  Future<List<PrayerRecord>> getAllRecords();
  Future<List<PrayerRecord>> getRecordsByDate(DateTime date);
  Future<PrayerRecord?> getRecordById(int id);
  Future<int> insertRecord(PrayerRecord record);
  Future<void> updateRecord(PrayerRecord record);
  Future<void> deleteRecord(int id);
  Future<Set<DateTime>> getRecordDates();
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
  Future<List<PrayerRecord>> getRecordsByDate(DateTime date) async {
    final db = await _db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      PrayerRecordModel.tableName,
      where:
          '${PrayerRecordModel.columnCreatedAt} >= ? AND ${PrayerRecordModel.columnCreatedAt} < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
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
  Future<Set<DateTime>> getRecordDates() async {
    final db = await _db;
    // createdAt 컬럼만 조회해 날짜(년/월/일)만 추출
    final maps = await db.query(
      PrayerRecordModel.tableName,
      columns: [PrayerRecordModel.columnCreatedAt],
    );
    return maps.map((row) {
      final ms = row[PrayerRecordModel.columnCreatedAt] as int;
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateTime(dt.year, dt.month, dt.day);
    }).toSet();
  }
}
