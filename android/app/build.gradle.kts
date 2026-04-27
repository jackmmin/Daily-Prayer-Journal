import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// android/key.properties에서 서명 정보 로드
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "com.jong.prayer_journal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    val javaVersion = JavaVersion.VERSION_17

    compileOptions {
        sourceCompatibility = javaVersion
        targetCompatibility = javaVersion
    }

    kotlinOptions {
        @Suppress("DEPRECATION")
        jvmTarget = javaVersion.toString()
    }

    signingConfigs {
        create("release") {
            storeFile = keyProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keyProperties.getProperty("storePassword")
            keyAlias = keyProperties.getProperty("keyAlias")
            keyPassword = keyProperties.getProperty("keyPassword")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.jong.prayer_journal"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (keyPropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug") // key.properties 없을 때 fallback
            }
            // R8/ProGuard: 코드 축소 및 최적화로 APK 용량 감소
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // ABI splits는 assembleRelease(APK)용. bundleRelease(App Bundle) 시 충돌하므로 비활성화
    splits {
        abi {
            isEnable = false
        }
    }
}

flutter {
    source = "../.."
}

// Flutter 플러그인이 assembleRelease.doLast에서 flutter-apk 폴더로 복사 후 파일명을 고정하므로,
// finalizedBy로 후속 Task를 등록해 Flutter 복사 완료 후 rename 수행
val renameReleaseApk = tasks.register("renameReleaseApk") {
    doLast {
        val apkDir = file("${layout.buildDirectory.get()}/outputs/flutter-apk")
        val versionName = android.defaultConfig.versionName ?: "unknown"
        if (apkDir.exists()) {
            apkDir.listFiles()
                ?.filter { it.name.startsWith("app-") && it.name.endsWith(".apk") }
                ?.forEach { apk ->
                    // app-release.apk -> DailyPrayer-1.0.0-release.apk
                    val newName = apk.name.replace("app-", "DailyPrayer-${versionName}-")
                    val dest = File(apkDir, newName)
                    // Flutter CLI가 app-release.apk를 참조하므로 원본은 유지하고 복사본 생성
                    apk.copyTo(dest, overwrite = true)
                    println("[rename] ${apk.name} -> $newName")
                }
        }
    }
}

tasks.whenTaskAdded {
    if (name == "assembleRelease") {
        finalizedBy(renameReleaseApk)
    }
}
