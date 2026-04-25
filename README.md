# 기도 일지 (Prayer Journal)

하루의 기도를 기록하는 Flutter 앱입니다.

## 기능

- 기도 제목 / 내용 입력
- 기도 시작 · 종료 시간 **직접 입력** 또는 **타이머** 사용
- 날짜별 기도 기록 조회
- 기도 기록 수정 / 삭제
- SQLite 로컬 저장 (인터넷 불필요)

## 아키텍처

```
lib/
├── main.dart
├── core/
│   ├── di/                    # GetIt 의존성 주입
│   └── theme/                 # 앱 테마
├── domain/
│   ├── entities/              # PrayerRecord (순수 도메인 모델)
│   ├── repositories/          # Repository 인터페이스
│   └── usecases/              # 비즈니스 로직 UseCase
├── data/
│   ├── models/                # SQLite 매핑 모델
│   ├── datasources/local/     # SQLite DataSource
│   └── repositories/          # Repository 구현체
└── presentation/
    ├── screens/               # 화면 (List, Form)
    ├── viewmodels/            # Riverpod StateNotifier
    └── widgets/               # 재사용 위젯
```

**패턴**: Clean Architecture + MVVM  
**상태관리**: Riverpod (StateNotifier)  
**DI**: GetIt  
**로컬 DB**: sqflite (SQLite)

## 시작하기

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 주요 패키지

| 패키지 | 버전 | 용도 |
|--------|------|------|
| sqflite | ^2.3.2 | SQLite 로컬 저장 |
| flutter_riverpod | ^2.5.1 | 상태관리 |
| get_it | ^7.7.0 | 의존성 주입 |
| intl | ^0.19.0 | 날짜/시간 포맷 |
| gap | ^3.0.1 | 간격 위젯 |
