import 'package:flutter/material.dart';

/// 화면 상단에 SnackBar 토스트를 표시하는 유틸 함수들
void showTopSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 2),
  Widget? leading,
}) {
  final topPadding = MediaQuery.of(context).padding.top;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: leading != null
            ? Row(children: [leading, const SizedBox(width: 8), Expanded(child: Text(message))])
            : Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: EdgeInsets.only(
          top: topPadding + 8,
          left: 16,
          right: 16,
          bottom: double.maxFinite,
        ),
      ),
    );
}

/// 성공 토스트 (상단)
void showSuccessToast(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
  showTopSnackBar(
    context,
    message,
    backgroundColor: Colors.green,
    duration: duration,
    leading: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
  );
}

/// 오류 토스트 (상단)
void showErrorToast(BuildContext context, String message) {
  showTopSnackBar(context, message, backgroundColor: Colors.red);
}

/// 일반 정보 토스트 (상단)
void showInfoToast(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
  showTopSnackBar(context, message, duration: duration);
}
