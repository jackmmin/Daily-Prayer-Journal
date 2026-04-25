// lib/core/providers/marker_color_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kMarkerColorPrefix = 'marker_color_'; // + yyyy-MM-dd

/// 선택 가능한 dot 마커 색상 목록
const List<Color> markerColorOptions = [
  Color(0xFF5B6EAE), // 기본 (앱 primary)
  Color(0xFFE53935), // 빨강
  Color(0xFFE67C00), // 주황
  Color(0xFFF9A825), // 노랑
  Color(0xFF43A047), // 초록
  Color(0xFF00ACC1), // 청록
  Color(0xFF8E24AA), // 보라
  Color(0xFFEC407A), // 분홍
];

String _dateKey(DateTime date) =>
    '$_kMarkerColorPrefix${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

Color _colorFromARGB32(int argb) => Color.fromARGB(
      (argb >> 24) & 0xFF,
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
    );

/// 날짜별 dot 마커 색상을 관리하는 Notifier.
/// 상태: Map<날짜(정규화), Color>
class MarkerColorNotifier extends StateNotifier<Map<DateTime, Color>> {
  MarkerColorNotifier() : super({}) {
    _loadAll();
  }

  /// SharedPreferences에서 모든 날짜별 색상 로드
  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_kMarkerColorPrefix));
    final map = <DateTime, Color>{};
    for (final key in keys) {
      final dateStr = key.substring(_kMarkerColorPrefix.length);
      final parts = dateStr.split('-');
      if (parts.length != 3) continue;
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final argb = prefs.getInt(key);
      if (argb != null) map[date] = _colorFromARGB32(argb);
    }
    state = map;
  }

  /// 특정 날짜의 dot 색상 변경 및 저장
  Future<void> setColor(DateTime date, Color color) async {
    final normalized = DateTime(date.year, date.month, date.day);
    state = {...state, normalized: color};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dateKey(normalized), color.toARGB32());
  }

  /// 특정 날짜의 dot 색상 조회 (없으면 기본색)
  Color colorFor(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return state[normalized] ?? markerColorOptions.first;
  }
}

final markerColorProvider =
    StateNotifierProvider<MarkerColorNotifier, Map<DateTime, Color>>((ref) {
  return MarkerColorNotifier();
});
