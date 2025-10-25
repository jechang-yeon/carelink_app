# CareLink App

CareLink은 보호소 운영을 지원하기 위해 Flutter로 작성된 애플리케이션입니다. 아래 안내에 따라 개발 환경을 구성하고 실행할 수 있습니다.

## 사전 준비
1. [Flutter 설치](https://docs.flutter.dev/get-started/install)
2. Firebase 프로젝트 및 Firestore, Authentication 설정
3. 지도 및 주소 검색 기능을 위한 Google Maps Platform (Maps, Places, Geocoding) API 키 발급

## 환경 변수 관리
민감한 API 키는 코드에 직접 포함하지 않고 런타임에 주입해야 합니다. Flutter 실행 시 `--dart-define` 옵션을 활용하거나 CI/CD에서 환경 변수를 설정하세요.

```bash
flutter run \
  --dart-define=GOOGLE_MAPS_API_KEY=발급한_구글_API_키
```

빌드 파이프라인에서도 동일한 옵션을 사용합니다.

```bash
flutter build apk \
  --dart-define=GOOGLE_MAPS_API_KEY=발급한_구글_API_키
```

## 개발용 샘플 환경 파일
필요하다면 루트 경로에 `.env.development` 등의 파일을 만들고, 스크립트나 CI에서 해당 파일을 읽어 `--dart-define` 인자에 전달하세요. 이 파일은 민감 정보가 포함되므로 Git에 커밋하지 않습니다.

## 프로젝트 실행
1. 패키지 의존성 설치
   ```bash
   flutter pub get
   ```
2. 플랫폼별 구성 요소 생성 (선택)
   ```bash
   flutter create .
   ```
3. 앱 실행 (환경 변수 포함)
   ```bash
flutter run \
--dart-define=GOOGLE_MAPS_API_KEY=발급한_구글_API_키
   ```

## 테스트 및 정적 분석
품질 관리를 위해 아래 명령을 주기적으로 실행하세요.

```bash
flutter test
flutter analyze
```

## 기여 가이드
1. 새 기능은 별도의 브랜치를 생성해 작업합니다.
2. 기능 구현 후 `dart format`으로 코드 스타일을 맞춥니다.
3. 단위 테스트와 분석을 통과한 뒤 PR을 생성합니다.
4. PR에는 변경 요약과 테스트 결과를 함께 남깁니다.

## 라이선스
해당 프로젝트의 라이선스는 별도로 지정되지 않았습니다. 필요한 경우 `LICENSE` 파일을 추가해 관리하세요.
