// lib/data/datasources/local/database_helper.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/prayer_record_model.dart';

class DatabaseHelper {
  static const String _databaseName = 'prayer_journal.db';
  static const int _databaseVersion = 1;

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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 향후 스키마 마이그레이션 처리
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
