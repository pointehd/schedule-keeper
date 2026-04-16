# Frontend — Daily Schedule Keeper

Flutter (Dart `^3.11.4`) 기반 프론트엔드.

## 디렉토리 구조

```
lib/
├── main.dart               # 앱 진입점. runApp()과 앱 시작 시 1회성 초기화만 둔다.
│
├── app/                    # MaterialApp 설정 (테마, 라우팅)
│
├── core/                   # UI 없는 인프라 코드
│   └── api/                # HTTP 클라이언트(Dio), 서비스 클래스
│
├── features/               # 화면/도메인 단위 모듈
│   ├── auth/               # 로그인, 게스트 상태 관련
│   ├── goals/              # 목표 관리
│   ├── home/               # 홈 화면
│   ├── routine/            # 데일리 루틴
│   └── tracking/           # 여유시간 트래킹
│
└── shared/                 # 2개 이상의 feature에서 재사용하는 위젯/유틸
    └── widgets/            # 공통 위젯 (AppScaffold 등)
```

## 주의사항

### 구조
- `main.dart`는 `runApp()` 호출과 앱 시작 시 1회 초기화(ex. healthcheck)만 둔다. 비즈니스 로직을 넣지 않는다.
- feature 내부에서만 쓰이는 위젯은 해당 `features/<name>/widgets/` 안에 둔다. 여러 feature에서 공유할 때만 `shared/`로 올린다.
- `core/`에는 UI 코드를 넣지 않는다. API 클라이언트, 스토리지, 유틸리티만 둔다.

### API 호출
- HTTP 클라이언트는 `Dio`를 사용한다 (`core/api/api_client.dart`).
- 도메인별로 서비스 클래스를 만들어 `ApiClient`를 주입받아 사용한다 (ex. `HealthService`).
- baseUrl 등 환경별 설정은 `api_client.dart`에서 관리한다.

### 공통 레이아웃
- 모든 페이지는 `AppScaffold`를 사용해 AppBar(햄버거 + 게스트 아바타)와 Drawer를 공유한다.
- 새 페이지 추가 시 `Scaffold`를 직접 쓰지 말고 `AppScaffold`로 감싼다.
