// lib/data/datasources/local/database_helper.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/bank_plan_model.dart';
import '../../models/prayer_record_model.dart';

class DatabaseHelper {
  static const String _databaseName = 'prayer_journal.db';
  static const int _databaseVersion = 4;

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(PrayerRecordModel.createTableSql);
    await db.execute(BankPlanModel.createTableSql);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 → v2: bank_plans 테이블 추가
    if (oldVersion < 2) {
      await db.execute(BankPlanModel.createTableSql);
    }
    // v2 → v3: bank_plans.title 컬럼 추가
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE ${BankPlanModel.tableName} ADD COLUMN ${BankPlanModel.columnTitle} TEXT NOT NULL DEFAULT ''",
      );
    }
    // v3 → v4: prayer_records.bank_plan_id 컬럼 추가 (계획별 일지 분리)
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE ${PrayerRecordModel.tableName} ADD COLUMN ${PrayerRecordModel.columnBankPlanId} INTEGER",
      );
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
