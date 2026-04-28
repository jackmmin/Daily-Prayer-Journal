// lib/presentation/widgets/date_time_picker_sheet.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 날짜/시간 드럼롤 피커 바텀시트
class DateTimePickerSheet extends StatefulWidget {
  final DateTime initial;
  const DateTimePickerSheet({super.key, required this.initial});

  @override
  State<DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<DateTimePickerSheet> {
  late int _year, _month, _day, _hour, _minute;

  late FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;

  static const int _yearBase = 2000;
  // 현재 연도 기준 +1년까지 표시 (매년 자동 확장)
  static int get _yearCount => DateTime.now().year - _yearBase + 2;

  @override
  void initState() {
    super.initState();
    _year   = widget.initial.year;
    _month  = widget.initial.month;
    _day    = widget.initial.day;
    _hour   = widget.initial.hour;
    _minute = widget.initial.minute;

    _yearCtrl   = FixedExtentScrollController(initialItem: _year - _yearBase);
    _monthCtrl  = FixedExtentScrollController(initialItem: _month - 1);
    _dayCtrl    = FixedExtentScrollController(initialItem: _day - 1);
    _hourCtrl   = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  void _onYearChanged(int idx) {
    setState(() {
      _year = _yearBase + idx;
      final maxDay = _daysInMonth(_year, _month);
      if (_day > maxDay) {
        _day = maxDay;
        _dayCtrl.jumpToItem(_day - 1);
      }
    });
  }

  void _onMonthChanged(int idx) {
    setState(() {
      _month = idx + 1;
      final maxDay = _daysInMonth(_year, _month);
      if (_day > maxDay) {
        _day = maxDay;
        _dayCtrl.jumpToItem(_day - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxDay = _daysInMonth(_year, _month);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          const Center(
            child: SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFBDBDBD), // Colors.grey.shade300
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 헤더 (취소 / 제목 / 확인)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              Text(
                '날짜 / 시간 선택',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  DateTime(_year, _month, _day, _hour, _minute),
                ),
                child: Text(
                  '확인',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 컬럼 레이블
          const Row(
            children: [
              Expanded(child: Center(child: Text('년', style: TextStyle(fontSize: 12, color: Colors.grey)))),
              Expanded(child: Center(child: Text('월', style: TextStyle(fontSize: 12, color: Colors.grey)))),
              Expanded(child: Center(child: Text('일', style: TextStyle(fontSize: 12, color: Colors.grey)))),
              Expanded(child: Center(child: Text('시', style: TextStyle(fontSize: 12, color: Colors.grey)))),
              Expanded(child: Center(child: Text('분', style: TextStyle(fontSize: 12, color: Colors.grey)))),
            ],
          ),
          const SizedBox(height: 4),
          // 드럼롤 피커
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 선택 영역 하이라이트
                Positioned(
                  top: 76,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Row(
                  children: [
                    // 년
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _yearCtrl,
                        itemExtent: 48,
                        onSelectedItemChanged: _onYearChanged,
                        selectionOverlay: const SizedBox.shrink(),
                        children: List.generate(
                          _yearCount,
                          (i) => _pickerItem('${_yearBase + i}'),
                        ),
                      ),
                    ),
                    // 월
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _monthCtrl,
                        itemExtent: 48,
                        onSelectedItemChanged: _onMonthChanged,
                        selectionOverlay: const SizedBox.shrink(),
                        children: List.generate(
                          12,
                          (i) => _pickerItem('${i + 1}'),
                        ),
                      ),
                    ),
                    // 일
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _dayCtrl,
                        itemExtent: 48,
                        onSelectedItemChanged: (i) => setState(() => _day = i + 1),
                        selectionOverlay: const SizedBox.shrink(),
                        children: List.generate(
                          maxDay,
                          (i) => _pickerItem('${i + 1}'),
                        ),
                      ),
                    ),
                    // 시
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _hourCtrl,
                        itemExtent: 48,
                        onSelectedItemChanged: (i) => setState(() => _hour = i),
                        selectionOverlay: const SizedBox.shrink(),
                        children: List.generate(
                          24,
                          (i) => _pickerItem(i.toString().padLeft(2, '0')),
                        ),
                      ),
                    ),
                    // 분
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _minuteCtrl,
                        itemExtent: 48,
                        onSelectedItemChanged: (i) => setState(() => _minute = i),
                        selectionOverlay: const SizedBox.shrink(),
                        children: List.generate(
                          60,
                          (i) => _pickerItem(i.toString().padLeft(2, '0')),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerItem(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }
}
