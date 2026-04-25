// lib/data/datasources/local/database_helper.dart

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/bank_plan_model.dart';
import '../../models/prayer_record_model.dart';

class DatabaseHelper {
  static const String _databaseName = 'prayer_journal.db';
  static const int _databaseVersion = 6;

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

    final db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // 삭제된 레코드의 빈 공간 회수 (앱 시작 시 1회)
    await db.execute('VACUUM');

    return db;
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
    // v4 → v5: created_at 제거 + 타임스탬프 seconds 단위 변환
    // SQLite는 컬럼 삭제 미지원 → 테이블 재생성 후 데이터 이전
    if (oldVersion < 5) {
      await db.transaction((txn) async {
        // prayer_records: ms → sec 변환, created_at 제거
        await txn.execute('''
          CREATE TABLE prayer_records_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            start_time INTEGER NOT NULL,
            end_time INTEGER,
            bank_plan_id INTEGER
          )
        ''');
        await txn.execute('''
          INSERT INTO prayer_records_new (id, title, content, start_time, end_time, bank_plan_id)
          SELECT id, title, content,
                 start_time / 1000,
                 CASE WHEN end_time IS NOT NULL THEN end_time / 1000 ELSE NULL END,
                 bank_plan_id
          FROM prayer_records
        ''');
        await txn.execute('DROP TABLE prayer_records');
        await txn.execute('ALTER TABLE prayer_records_new RENAME TO prayer_records');

        // bank_plans: ms → sec 변환
        await txn.execute('''
          CREATE TABLE bank_plans_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL DEFAULT '',
            start_date INTEGER NOT NULL,
            end_date INTEGER NOT NULL,
            minutes INTEGER NOT NULL,
            amount INTEGER NOT NULL
          )
        ''');
        await txn.execute('''
          INSERT INTO bank_plans_new (id, title, start_date, end_date, minutes, amount)
          SELECT id, title,
                 start_date / 1000,
                 end_date / 1000,
                 minutes, amount
          FROM bank_plans
        ''');
        await txn.execute('DROP TABLE bank_plans');
        await txn.execute('ALTER TABLE bank_plans_new RENAME TO bank_plans');
      });
    }
    // v5 → v6: content TEXT → BLOB (gzip 압축)
    // 기존 TEXT 데이터를 UTF-8 바이트(또는 gzip)로 변환 후 재삽입
    if (oldVersion < 6) {
      await db.transaction((txn) async {
        await txn.execute('''
          CREATE TABLE prayer_records_v6 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content BLOB NOT NULL,
            start_time INTEGER NOT NULL,
            end_time INTEGER,
            bank_plan_id INTEGER
          )
        ''');
        final rows = await txn.query('prayer_records');
        for (final row in rows) {
          final text = row['content'] as String;
          final bytes = utf8.encode(text);
          // 500 bytes 초과 시 gzip 압축
          final blob = bytes.length > 500 ? GZipCodec().encode(bytes) : bytes;
          await txn.insert('prayer_records_v6', {
            'id': row['id'],
            'title': row['title'],
            'content': blob,
            'start_time': row['start_time'],
            'end_time': row['end_time'],
            'bank_plan_id': row['bank_plan_id'],
          });
        }
        await txn.execute('DROP TABLE prayer_records');
        await txn.execute('ALTER TABLE prayer_records_v6 RENAME TO prayer_records');
      });
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
