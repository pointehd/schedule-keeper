# Frontend — Daily Schedule Keeper

Flutter (Dart `^3.11.4`) 기반 프론트엔드.

## 디렉토리 구조

```
lib/
├── main.dart           # 앱 진입점 (healthcheck + runApp)
├── app/                # MaterialApp 설정 (테마, ChangeNotifierProvider)
├── core/               # UI 없는 인프라 코드
│   └── api/            # Dio 클라이언트, 도메인별 서비스
├── features/           # 화면/도메인 단위 모듈
│   ├── home/           # 홈 대시보드 (달성률, 이번 주, 계획 미리보기)
│   ├── plan/           # 오늘의 계획·체크 (필터, 카드별 측정방식)
│   │   └── widgets/    # PlanCard (시간/횟수/완료 타입)
│   ├── add_plan/       # 새 계획 추가 (IndexedStack 내 영구 보존)
│   ├── calendar/       # 캘린더 뷰 (월별, 선택일 계획 목록)
│   └── mypage/         # 내 정보 및 통계
└── shared/             # 2개 이상의 feature에서 재사용하는 코드
    ├── models/         # Plan, PlanCategory, MeasureType
    ├── providers/      # PlanNotifier (ChangeNotifier)
    └── widgets/        # MainScaffold (하단 네비게이션)
```

## 주요 설계 결정

### 네비게이션
- `MainScaffold`가 `IndexedStack`으로 5개 페이지를 관리한다 (홈·계획·캘린더·내정보·새계획).
- 하단 네비게이션은 항상 표시된다. 새계획 페이지도 IndexedStack 안에 포함되어 별도 route로 push하지 않는다.
- `+ 버튼` → 새계획 페이지로 전환 (이전 탭 기억). 다른 탭으로 이동해도 폼 상태가 유지된다.

### 상태 관리
- `provider` 패키지 + `ChangeNotifier`를 사용한다 (`PlanNotifier`).
- `PlanNotifier`는 `App` 위젯에서 `ChangeNotifierProvider`로 주입하고, 하위 위젯은 `context.watch` / `context.read`로 접근한다.

### 스톱워치 타이머
- `PlanNotifier`가 타이머 상태(`_activeTimerId`, `_timerStartedAt`)를 관리한다.
- 시작 시각을 `SharedPreferences`에 저장해 앱 종료 후 재시작해도 경과 시간을 복원한다.
- 한 번에 하나의 플랜만 활성화된다. 다른 플랜 시작 시 이전 플랜은 자동 일시정지된다.
- 목표 시간 초과 후에도 타이머가 계속 동작한다 (프로그레스 바는 100% 캡, 시간·%는 실제값 표시).

### 측정 방식 (MeasureType)
- `time` : 분 단위 스톱워치. MM:SS 포맷으로 표시.
- `count` : 개수 카운터. ±1 / +5 버튼.
- `check` : 완료 체크박스.

### 구조 규칙
- `main.dart`는 `runApp()` 호출과 1회 초기화(healthcheck)만 둔다.
- feature 내부 전용 위젯은 `features/<name>/widgets/`에 둔다. 여러 feature 공유 시에만 `shared/`로 올린다.
- `core/`에는 UI 코드를 넣지 않는다.

### API 호출
- HTTP 클라이언트는 `Dio`를 사용한다 (`core/api/api_client.dart`).
- 도메인별로 서비스 클래스를 만들어 `ApiClient`를 주입받아 사용한다.
- baseUrl 등 환경별 설정은 `api_client.dart`에서 관리한다.
