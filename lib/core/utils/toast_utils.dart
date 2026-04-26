import 'package:flutter/material.dart';

/// 화면 상단에 Overlay 기반 토스트를 표시하는 내부 함수
void _showOverlayToast(
  BuildContext context,
  String message, {
  Color backgroundColor = const Color(0xFF323232),
  Color textColor = Colors.white,
  Duration duration = const Duration(seconds: 2),
  Widget? leading,
}) {
  final overlay = Overlay.of(context);
  final screenHeight = MediaQuery.of(context).size.height;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: screenHeight * 0.20,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: leading != null
              ? Row(
                  children: [
                    leading,
                    const SizedBox(width: 8),
                    Expanded(child: Text(message, style: TextStyle(color: textColor))),
                  ],
                )
              : Text(message, style: TextStyle(color: textColor)),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(duration, () {
    if (entry.mounted) entry.remove();
  });
}

/// 성공 토스트 - 연한 초록색 배경
void showSuccessToast(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
  _showOverlayToast(
    context,
    message,
    backgroundColor: const Color(0xFFD4EDDA),
    textColor: const Color(0xFF155724),
    duration: duration,
    leading: const Icon(Icons.check_circle_outline, color: Color(0xFF28A745), size: 18),
  );
}

/// 오류 토스트 - 연한 빨간색 배경
void showErrorToast(BuildContext context, String message) {
  _showOverlayToast(
    context,
    message,
    backgroundColor: const Color(0xFFF8D7DA),
    textColor: const Color(0xFF721C24),
    leading: const Icon(Icons.error_outline, color: Color(0xFFDC3545), size: 18),
  );
}

/// 경고 토스트 - 노란색 배경
void showWarningToast(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
  _showOverlayToast(
    context,
    message,
    backgroundColor: const Color(0xFFFFF3CD),
    textColor: const Color(0xFF856404),
    duration: duration,
    leading: const Icon(Icons.warning_amber_outlined, color: Color(0xFFFFC107), size: 18),
  );
}

/// 일반 정보 토스트 (상단)
void showInfoToast(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
  _showOverlayToast(context, message, duration: duration);
}
