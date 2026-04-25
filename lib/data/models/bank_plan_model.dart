// lib/data/models/bank_plan_model.dart

import '../../domain/entities/bank_plan.dart';

class BankPlanModel {
  static const String tableName = 'bank_plans';

  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnStartDate = 'start_date';
  static const String columnEndDate = 'end_date';
  static const String columnMinutes = 'minutes';
  static const String columnAmount = 'amount';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnTitle TEXT NOT NULL DEFAULT '',
      $columnStartDate INTEGER NOT NULL,
      $columnEndDate INTEGER NOT NULL,
      $columnMinutes INTEGER NOT NULL,
      $columnAmount INTEGER NOT NULL
    )
  ''';

  static Map<String, dynamic> toMap(BankPlan plan) => {
        if (plan.id != null) columnId: plan.id,
        columnTitle: plan.title,
        columnStartDate: plan.startDate.millisecondsSinceEpoch,
        columnEndDate: plan.endDate.millisecondsSinceEpoch,
        columnMinutes: plan.minutes,
        columnAmount: plan.amount,
      };

  static BankPlan fromMap(Map<String, dynamic> map) => BankPlan(
        id: map[columnId] as int,
        title: (map[columnTitle] as String?) ?? '',
        startDate: DateTime.fromMillisecondsSinceEpoch(map[columnStartDate] as int),
        endDate: DateTime.fromMillisecondsSinceEpoch(map[columnEndDate] as int),
        minutes: map[columnMinutes] as int,
        amount: map[columnAmount] as int,
      );
}
