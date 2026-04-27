// lib/core/services/excel_import_service.dart

import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/bank_plan.dart';

/// 엑셀 가져오기 결과
class ImportResult {
  final BankPlan? plan;
  final String? errorMessage;

  const ImportResult.success(this.plan) : errorMessage = null;
  const ImportResult.failure(this.errorMessage) : plan = null;

  bool get isSuccess => plan != null;
}

class ExcelImportService {
  static final _dateFmt = DateFormat('yyyy-MM-dd');
  static final _filenameDateFmt = DateFormat('yyyyMMdd_HHmmss');

  /// 기기에서 엑셀 파일을 선택해 BankPlan을 파싱한다.
  static Future<ImportResult> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return const ImportResult.failure('파일을 선택하지 않았습니다.');
    }

    final file = result.files.first;

    // 확장자 재확인 (OS 레벨 필터가 우회될 수 있음)
    final ext = file.extension?.toLowerCase() ?? '';
    if (ext != 'xlsx' && ext != 'xls') {
      return const ImportResult.failure('엑셀 파일(.xlsx, .xls)만 허용됩니다.');
    }

    // 파일 크기 20MB 제한 (OOM 방지)
    if (file.path != null) {
      final fileSize = File(file.path!).lengthSync();
      if (fileSize > 20 * 1024 * 1024) {
        return const ImportResult.failure('파일 크기가 너무 큽니다 (최대 20MB).');
      }
    }

    final bytes = file.bytes ?? (file.path != null ? File(file.path!).readAsBytesSync() : null);
    if (bytes == null) {
      return const ImportResult.failure('파일을 읽을 수 없습니다.');
    }

    return _parseBytes(bytes);
  }

  /// 바이트에서 메타데이터를 파싱해 BankPlan을 반환한다.
  static ImportResult _parseBytes(List<int> bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      if (!excel.tables.containsKey('계획 요약')) {
        return const ImportResult.failure(
          '"계획 요약" 시트를 찾을 수 없습니다.\n이 앱에서 내보낸 엑셀 파일을 사용해주세요.',
        );
      }
      final sheet = excel['계획 요약'];

      // meta_* 키-값 수집
      final meta = <String, String>{};
      for (final row in sheet.rows) {
        if (row.length < 2) continue;
        final key = row[0]?.value?.toString().trim() ?? '';
        final val = row[1]?.value?.toString().trim() ?? '';
        if (key.startsWith('meta_') && val.isNotEmpty) {
          meta[key] = val;
        }
      }

      if (meta.isEmpty) {
        return const ImportResult.failure(
          '가져오기 메타데이터를 찾을 수 없습니다.\n이 앱에서 내보낸 엑셀 파일을 사용해주세요.',
        );
      }

      // 필수 필드 파싱
      final title = meta['meta_title'] ?? '';
      final startDate = _parseDate(meta['meta_start_date']);
      final endDate = _parseDate(meta['meta_end_date']);
      final minutes = int.tryParse(meta['meta_minutes'] ?? '');
      final amount = int.tryParse(meta['meta_amount'] ?? '');

      if (startDate == null) {
        return const ImportResult.failure('시작일 데이터가 올바르지 않습니다.');
      }
      if (endDate == null) {
        return const ImportResult.failure('종료일 데이터가 올바르지 않습니다.');
      }
      if (minutes == null || minutes < 0 || minutes > 1440) {
        return const ImportResult.failure('기도 기준(분) 데이터가 올바르지 않습니다. (0~1440분)');
      }
      if (amount == null || amount < 0 || amount > 10000000000) {
        return const ImportResult.failure('적립 금액 데이터가 올바르지 않습니다. (0~100억원)');
      }

      return ImportResult.success(BankPlan(
        title: title,
        startDate: startDate,
        endDate: endDate,
        minutes: minutes,
        amount: amount,
      ));
    } catch (e) {
      return ImportResult.failure('파일 파싱 중 오류가 발생했습니다: $e');
    }
  }

  /// 샘플 엑셀 파일을 생성해 공유 시트를 띄운다.
  static Future<void> exportSample() async {
    final today = DateTime.now();
    final samplePlan = BankPlan(
      title: '새벽기도 100일',
      startDate: DateTime(today.year, today.month, today.day),
      endDate: DateTime(today.year, today.month + 3, today.day),
      minutes: 30,
      amount: 5000,
    );

    final excel = Excel.createExcel();
    excel.rename('Sheet1', '계획 요약');
    final sheet = excel['계획 요약'];
    final labelStyle = CellStyle(bold: true);
    final metaStyle = CellStyle(bold: true, fontColorHex: ExcelColor.fromHexString('#888888'));

    // 사람이 읽기 좋은 요약 행
    final summaryRows = [
      ['계획명', samplePlan.title],
      ['시작일', _dateFmt.format(samplePlan.startDate)],
      ['종료일', _dateFmt.format(samplePlan.endDate)],
      ['기도 기준', '${samplePlan.minutes}분 → ${samplePlan.amount}원'],
      ['총 기도 기록 수', '0건'],
      ['총 기도 시간', '0분'],
      ['총 적립 금액', '0원'],
    ];

    for (var i = 0; i < summaryRows.length; i++) {
      final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
      labelCell.value = TextCellValue(summaryRows[i][0]);
      labelCell.cellStyle = labelStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).value =
          TextCellValue(summaryRows[i][1]);
    }

    // 가져오기 호환 메타데이터 블록
    final metaStartRow = summaryRows.length + 2;
    final metaHeaderCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: metaStartRow - 1),
    );
    metaHeaderCell.value = TextCellValue('[가져오기 메타데이터 - 수정하지 마세요]');
    metaHeaderCell.cellStyle = metaStyle;

    final metaRows = [
      ['meta_title', samplePlan.title],
      ['meta_start_date', _dateFmt.format(samplePlan.startDate)],
      ['meta_end_date', _dateFmt.format(samplePlan.endDate)],
      ['meta_minutes', samplePlan.minutes.toString()],
      ['meta_amount', samplePlan.amount.toString()],
    ];

    for (var i = 0; i < metaRows.length; i++) {
      final rowIndex = metaStartRow + i;
      final keyCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      keyCell.value = TextCellValue(metaRows[i][0]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue(metaRows[i][1]);
    }

    // 기도일지 시트 (빈 헤더만)
    final journalSheet = excel['기도일지'];
    final journalHeaders = ['날짜', '기도 제목', '기도 내용', '시작 시간', '종료 시간', '기도 시간(분)', '적립 금액(원)'];
    for (var i = 0; i < journalHeaders.length; i++) {
      final cell = journalSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(journalHeaders[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4A90D9'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 30);

    final tmpDir = await getTemporaryDirectory();
    final timestamp = _filenameDateFmt.format(DateTime.now());
    final filePath = '${tmpDir.path}/기도일지_샘플_$timestamp.xlsx';

    final bytes = excel.encode();
    if (bytes == null) throw Exception('샘플 파일 생성 실패');

    await File(filePath).writeAsBytes(bytes);

    final sampleFile = File(filePath);
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: '기도일지 샘플 파일',
    );

    // 공유 완료 후 임시 파일 삭제 (개인정보 보호)
    try {
      await sampleFile.delete();
    } catch (_) {}
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return _dateFmt.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
