// lib/core/providers/marker_color_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kMarkerColorKey = 'marker_color';

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

class MarkerColorNotifier extends StateNotifier<Color> {
  MarkerColorNotifier() : super(markerColorOptions.first) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final argb = prefs.getInt(_kMarkerColorKey);
    if (argb != null) {
      // toARGB32()로 저장한 값을 컴포넌트로 분해해 복원
      state = Color.fromARGB(
        (argb >> 24) & 0xFF,
        (argb >> 16) & 0xFF,
        (argb >> 8) & 0xFF,
        argb & 0xFF,
      );
    }
  }

  Future<void> setColor(Color color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMarkerColorKey, color.toARGB32());
  }
}

final markerColorProvider =
    StateNotifierProvider<MarkerColorNotifier, Color>((ref) {
  return MarkerColorNotifier();
});
