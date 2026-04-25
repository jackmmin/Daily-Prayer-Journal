# Flutter 기본 ProGuard 규칙

# Flutter 엔진
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }

# Dart 관련
-keep class com.google.** { *; }
-dontwarn com.google.**

# SQLite (sqflite)
-keep class com.tekartik.sqflite.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# 일반 Android 규칙
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
