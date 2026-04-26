#!/bin/bash
# flutter build apk --release 후 APK 파일명을 DailyPrayer-{버전}-release.apk 형식으로 변경

APK_DIR="build/app/outputs/flutter-apk"
VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)

if [ ! -d "$APK_DIR" ]; then
    echo "[rename_apk] APK 출력 폴더가 없습니다: $APK_DIR"
    exit 1
fi

renamed=0
for apk in "$APK_DIR"/app-*.apk; do
    [ -f "$apk" ] || continue
    filename=$(basename "$apk")
    # app-release.apk -> DailyPrayer-1.0.0-release.apk
    newname="${filename/app-/DailyPrayer-${VERSION}-}"
    mv "$apk" "$APK_DIR/$newname"
    echo "[rename_apk] $filename -> $newname"
    renamed=$((renamed + 1))
done

if [ $renamed -eq 0 ]; then
    echo "[rename_apk] 변경할 APK 파일이 없습니다."
else
    echo "[rename_apk] 완료: $renamed 개 파일 이름 변경됨"
fi
