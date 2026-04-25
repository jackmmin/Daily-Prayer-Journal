// lib/domain/entities/bank_plan.dart

class BankPlan {
  final int? id;

  /// 계획 시작일 (시분초 무시, 날짜만 사용)
  final DateTime startDate;

  /// 계획 종료일 (시분초 무시, 날짜만 사용)
  final DateTime endDate;

  /// 기준 기도 시간 (분)
  final int minutes;

  /// 기준 시간당 적립 금액 (원)
  final int amount;

  const BankPlan({
    this.id,
    required this.startDate,
    required this.endDate,
    required this.minutes,
    required this.amount,
  });

  /// 오늘 날짜가 계획 기간에 포함되는지
  bool get isActive {
    final today = _dateOnly(DateTime.now());
    return !today.isBefore(_dateOnly(startDate)) &&
        !today.isAfter(_dateOnly(endDate));
  }

  /// 기도 시간(초)에 해당하는 적립 금액 계산
  int calcEarned(int prayedSeconds) {
    if (minutes <= 0 || amount <= 0 || prayedSeconds <= 0) return 0;
    return (prayedSeconds / (minutes * 60) * amount).floor();
  }

  BankPlan copyWith({
    int? id,
    DateTime? startDate,
    DateTime? endDate,
    int? minutes,
    int? amount,
  }) =>
      BankPlan(
        id: id ?? this.id,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        minutes: minutes ?? this.minutes,
        amount: amount ?? this.amount,
      );

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
