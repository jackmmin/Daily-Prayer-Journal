// lib/core/services/excel_export_service.dart

import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/bank_plan.dart';
import '../../domain/entities/prayer_record.dart';

class ExcelExportService {
  static final _dateFmt = DateFormat('yyyy-MM-dd');
  static final _timeFmt = DateFormat('HH:mm');
  static final _filenameDateFmt = DateFormat('yyyyMMdd_HHmmss');

  /// [plan]에 속한 [records]를 엑셀로 내보내 공유 시트를 띄운다.
  static Future<void> exportPrayerRecords({
    required BankPlan plan,
    required List<PrayerRecord> records,
  }) async {
    final excel = Excel.createExcel();

    // 기본 Sheet1 제거 후 새 시트 생성
    excel.rename('Sheet1', '기도일지');
    final sheet = excel['기도일지'];

    // ── 헤더 행 ──────────────────────────────────────────────────────────────
    final headers = ['날짜', '기도 제목', '기도 내용', '시작 시간', '종료 시간', '기도 시간(분)', '적립 금액(원)'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4A90D9'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // ── 계획 요약 시트 ────────────────────────────────────────────────────────
    _writePlanSummary(excel, plan, records);

    // ── 데이터 행 ─────────────────────────────────────────────────────────────
    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      final rowIndex = i + 1;
      final duration = record.prayerDuration;
      final earnedAmount = duration != null ? plan.calcEarned(duration.inSeconds) : 0;

      _writeCell(sheet, rowIndex, 0, _dateFmt.format(record.startTime));
      _writeCell(sheet, rowIndex, 1, record.title);
      _writeCell(sheet, rowIndex, 2, record.content);
      _writeCell(sheet, rowIndex, 3, _timeFmt.format(record.startTime));
      _writeCell(sheet, rowIndex, 4, record.endTime != null ? _timeFmt.format(record.endTime!) : '-');
      _writeCell(sheet, rowIndex, 5, duration?.inMinutes.toString() ?? '-');
      _writeCell(sheet, rowIndex, 6, earnedAmount > 0 ? earnedAmount.toString() : '-');
    }

    // ── 열 너비 설정 ─────────────────────────────────────────────────────────
    sheet.setColumnWidth(0, 14);  // 날짜
    sheet.setColumnWidth(1, 28);  // 기도 제목
    sheet.setColumnWidth(2, 50);  // 기도 내용
    sheet.setColumnWidth(3, 12);  // 시작 시간
    sheet.setColumnWidth(4, 12);  // 종료 시간
    sheet.setColumnWidth(5, 14);  // 기도 시간
    sheet.setColumnWidth(6, 16);  // 적립 금액

    // ── 파일 저장 ─────────────────────────────────────────────────────────────
    final tmpDir = await getTemporaryDirectory();
    final timestamp = _filenameDateFmt.format(DateTime.now());
    final dateRange = '${_dateFmt.format(plan.startDate)}-${_dateFmt.format(plan.endDate)}';
    // 이모지/특수문자 제거 후 순수 텍스트만 추출
    final strippedTitle = plan.title.replaceAll(RegExp(r'[^\w가-힣＀-￯\s\-]'), '').trim();
    // 이모지만 있는 경우 title 생략, 날짜 범위만 사용
    final fileName = strippedTitle.isNotEmpty
        ? '기도일지_${strippedTitle}_${dateRange}_$timestamp.xlsx'
        : '기도일지_${dateRange}_$timestamp.xlsx';
    final filePath = '${tmpDir.path}/$fileName';

    final bytes = excel.encode();
    if (bytes == null) throw Exception('엑셀 파일 생성 실패');

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // ── 공유 시트 ─────────────────────────────────────────────────────────────
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: strippedTitle.isNotEmpty ? '기도일지 - ${strippedTitle}_$dateRange' : '기도일지 - $dateRange',
    );
  }

  static void _writePlanSummary(Excel excel, BankPlan plan, List<PrayerRecord> records) {
    final sheet = excel['계획 요약'];
    final labelStyle = CellStyle(bold: true);

    final totalMinutes = records.fold<int>(
      0,
      (sum, r) => sum + (r.prayerDuration?.inMinutes ?? 0),
    );
    final totalEarned = records.fold<int>(
      0,
      (sum, r) {
        final d = r.prayerDuration;
        return sum + (d != null ? plan.calcEarned(d.inSeconds) : 0);
      },
    );

    final rows = [
      ['계획명', plan.title.isNotEmpty ? plan.title : '(이름 없음)'],
      ['시작일', _dateFmt.format(plan.startDate)],
      ['종료일', _dateFmt.format(plan.endDate)],
      ['기도 기준', '${plan.minutes}분 → ${_formatAmount(plan.amount)}원'],
      ['총 기도 기록 수', '${records.length}건'],
      ['총 기도 시간', '$totalMinutes분'],
      ['총 적립 금액', '${_formatAmount(totalEarned)}원'],
    ];

    for (var i = 0; i < rows.length; i++) {
      final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
      labelCell.value = TextCellValue(rows[i][0]);
      labelCell.cellStyle = labelStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).value =
          TextCellValue(rows[i][1]);
    }

    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 30);
  }

  static void _writeCell(Sheet sheet, int row, int col, String value) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
        TextCellValue(value);
  }

  static String _formatAmount(int amount) => amount
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
