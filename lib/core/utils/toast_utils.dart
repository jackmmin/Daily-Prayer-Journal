import 'package:flutter/material.dart';

/// 화면 상단에 Overlay 기반 토스트를 표시하는 내부 함수
void _showOverlayToast(
  BuildContext context,
  String message, {
  Color backgroundColor = const Color(0xFF323232),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    leading,
                    const SizedBox(width: 8),
                    Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
                  ],
                )
              : Text(message, style: const TextStyle(color: Colors.white)),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(duration, () {
    if (entry.mounted) entry.remove();
  });
}

/// 성공 토스트 (상단)
void showSuccessToast(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
  _showOverlayToast(
    context,
    message,
    backgroundColor: Colors.green,
    duration: duration,
    leading: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
  );
}

/// 오류 토스트 (상단)
void showErrorToast(BuildContext context, String message) {
  _showOverlayToast(context, message, backgroundColor: Colors.red);
}

/// 일반 정보 토스트 (상단)
void showInfoToast(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
  _showOverlayToast(context, message, duration: duration);
}
