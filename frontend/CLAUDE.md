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
│   ├── edit_plan/      # 기존 계획 수정 (별도 route로 push)
│   ├── calendar/       # 캘린더 뷰 (월별, 선택일 계획 목록)
│   │   └── widgets/    # SelectedDayDetail (선택일 계획 목록 패널)
│   ├── mypage/         # 내 정보 (로그인, 여유시간 설정, 통계)
│   │   ├── my_page.dart
│   │   └── login_page.dart
│   ├── auth/           # 인증 관련 (현재 미사용, 향후 확장용)
│   └── tracking/       # 트래킹 관련 (현재 미사용, 향후 확장용)
└── shared/             # 2개 이상의 feature에서 재사용하는 코드
    ├── models/         # 도메인 모델 및 Hive 어댑터
    ├── providers/      # PlanNotifier (ChangeNotifier)
    ├── theme/          # 앱 전체 공통 색상
    ├── utils/          # 공통 유틸리티 함수
    └── widgets/        # 공통 위젯 (MainScaffold, PageHeader, 폼 컴포넌트)
```

## shared/ 상세

### models/
- `plan.dart` — 도메인 모델 전체 정의
  - `PlanCategory` (enum): 학습·독서·건강·재테크·관계·취미·기타. 각 항목이 label과 Color를 가진다.
  - `MeasureType` (enum): `time` / `count` / `check`. label과 subtitle 포함.
  - `PlanScheduleType` (enum): `daily` / `weekdays` / `specific` / `floating`.
  - `PlanVersion`: 계획 필드 스냅샷. `effectiveFrom`부터 이 버전이 적용된다.
  - `PlanRecord`: Hive에 저장되는 계획 원본. `versions` 리스트로 편집 이력을 보존한다.
  - `Plan`: UI 표시용 뷰 모델. `PlanRecord` + `DailyProgress`를 합성해 만든다.
  - `DailyProgress`: 날짜별 실행 기록 (current, isCompleted). Hive에 `planId_YYYYMMDD` 키로 저장.
  - `FreeHoursSnapshot`: 여유시간 스냅샷 (요일별 7개 값). `effectiveFrom` 기준 가장 최신 스냅샷이 해당 날짜에 적용된다.
  - `fmtMins` / `fmtHours`: 분·시간을 `HH:MM` 포맷으로 변환하는 헬퍼 함수.

- `hive_adapters.dart` — Hive TypeAdapter 등록 모음
  - typeId 매핑: `PlanVersion`=0, `DailyProgress`=1, `PlanRecord`=2, `FreeHoursSnapshot`=3.
  - 새 모델을 Hive에 추가할 때 typeId를 여기서 확인하고 충돌 방지.

### providers/
- `plan_provider.dart` — `PlanNotifier` (앱 전체 유일한 ChangeNotifier)
  - **Hive Box 3개**: `plan_records`, `progress`, `free_hours_history`.
  - **주요 getter**: `plans` (오늘 계획 목록), `plansForDate(date)`, `completedCount`, `overallProgress`, `freeHours`, `todayFreeHours`.
  - **타이머**: `startTimer(id)` / `pauseTimer(id)`. 활성 타이머는 최대 1개. 앱 재시작 시 `SharedPreferences`에서 복원 후 경과분을 즉시 flush.
  - **계획 변경**: `addPlan` → 새 PlanRecord 생성. `editPlan` → 오늘 날짜 기준 새 PlanVersion 추가 (과거 버전 보존). `endPlan` → endDate 설정 (소프트 삭제). `deletePlan` → PlanRecord + 관련 DailyProgress 전체 삭제.
  - **진행 변경**: `updateCount(delta)`, `setCurrentValue(value)`, `toggleCheck(id)`, `reset(id)`.
  - **여유시간**: `setFreeHours(index, hours)` (오늘부터 적용). `setFreeHoursForDate(date, index, hours)` (특정 날짜만, 이후 날짜 보호 로직 내장). `_fillMissingDays()` — 앱 초기화 시 마지막 스냅샷 이후 누락된 날짜를 자동 채운다.
  - **floating 플랜**: 목표를 달성한 날 이후로는 `plansForDate`에서 자동 제외된다.

### theme/
- `app_colors.dart` — 앱 전체 공통 색상 상수
  - `kPrimary` (#5B5FC7, 인디고): 주요 액션·선택 상태.
  - `kWeekend` (#D4873A, 주황): 캘린더 주말 표시.
  - `kBg` (#F2F3F8): 기본 배경색.
  - `kSuccess` (#34C759, 초록): 달성 완료 상태.
  - `kDanger` (#FF3B30, 빨강): 경고/미달성 상태.
  - `kWarning` (#FF9500, 노랑): 중간 경고 상태.

### utils/
- `plan_color_utils.dart` — `dayProgressColor(date, today, notifier)`
  - 캘린더 날짜 셀 색상 결정 함수. 미래 날짜는 `null` 반환.
  - 판단 순서: 집중시간 > 여유시간 → `kPrimary` / 집중시간 < 여유시간×0.2 → `kDanger` / 완료율 ≥ 80% → `kSuccess` / 그 외 → `kWarning`.

### widgets/
- `main_scaffold.dart` — `MainScaffold`: `IndexedStack` 기반 5탭 네비게이션 루트 위젯.
- `page_header.dart` — `PageHeader`: 화면 상단 타이틀 + 선택적 trailing 위젯.
- `plan_form_widgets.dart` — 계획 추가/수정 폼에서 공유하는 UI 컴포넌트 모음
  - `PlanSectionLabel`: 폼 섹션 제목 텍스트.
  - `PlanFormCard`: 흰 배경 + 둥근 모서리 컨테이너.
  - `PlanQuickBtn`: 선택 가능한 pill 버튼 (목표값 단축 입력 등).
  - `PlanQuickDayBtn`: 선택 불가, 단순 pill 버튼 (평일/주말 단축).
  - `PlanCategorySelector`: 카테고리 칩 선택기 (전체 PlanCategory 나열).
  - `PlanMeasureTypeSelector`: time/count/check 선택 카드.
  - `PlanTargetSection`: 목표값 표시 + 단축 버튼. MeasureType에 따라 단위(분/개) 전환.
  - `PlanScheduleSelector`: 반복 주기 선택 (매일/특정요일/특정일/반복없음). 모드별 서브 UI 포함.

## 주요 설계 결정

### 네비게이션
- `MainScaffold`가 `IndexedStack`으로 5개 페이지를 관리한다 (홈·계획·캘린더·내정보·새계획).
- 하단 네비게이션은 항상 표시된다. 새계획 페이지도 IndexedStack 안에 포함되어 별도 route로 push하지 않는다.
- `+ 버튼` → 새계획 페이지로 전환 (이전 탭 기억). 다른 탭으로 이동해도 폼 상태가 유지된다.
- `edit_plan`은 예외적으로 별도 route (`Navigator.push`)로 열린다.

### 상태 관리
- `provider` 패키지 + `ChangeNotifier`를 사용한다 (`PlanNotifier`).
- `PlanNotifier`는 `App` 위젯에서 `ChangeNotifierProvider`로 주입하고, 하위 위젯은 `context.watch` / `context.read`로 접근한다.

### 데이터 저장
- 모든 계획·진행 데이터는 **Hive**로 기기 로컬에 저장한다.
- `DailyProgress`는 `planId_YYYYMMDD` 형식의 키로 `progress` Box에 저장한다.
- 타이머 시작 시각만 `SharedPreferences`에 별도 보관해 앱 재시작 후 복원한다.
- 로그인 사용자만 서버 저장 가능 (실시간 동기화 아님, 향후 구현 예정).

### 계획 버전 관리
- `PlanRecord.versions`는 시간순 정렬된 `PlanVersion` 리스트다.
- 수정 시 오늘 날짜로 새 버전을 추가한다 (과거 날짜의 기록은 이전 버전으로 유지).
- 특정 날짜의 적용 버전은 `PlanRecord.versionForDate(date)`로 조회한다.

### 스톱워치 타이머
- `PlanNotifier`가 타이머 상태(`_activeTimerId`, `_timerStartedAt`)를 관리한다.
- 시작 시각을 `SharedPreferences`에 저장해 앱 종료 후 재시작해도 경과 시간을 복원한다.
- 한 번에 하나의 플랜만 활성화된다. 다른 플랜 시작 시 이전 플랜은 자동 일시정지된다.
- 목표 시간 초과 후에도 타이머가 계속 동작한다 (프로그레스 바는 100% 캡, 시간·%는 실제값 표시).

### 측정 방식 (MeasureType)
- `time` : 분 단위 스톱워치. MM:SS 포맷으로 표시.
- `count` : 개수 카운터. ±1 / +5 버튼.
- `check` : 완료 체크박스.

### 반복 주기 인코딩 (repeatDays)
- `[]` → `daily` (매일)
- `[-1]` → `floating` (목표 달성 전까지 매일 표시, 달성 후 자동 제거)
- `[1..7]` → `weekdays` (요일 지정, 1=월 … 7=일)
- `[> 10000]` → `specific` (특정일, YYYYMMDD 정수 리스트)

### 구조 규칙
- `main.dart`는 `runApp()` 호출과 1회 초기화(healthcheck)만 둔다.
- feature 내부 전용 위젯은 `features/<name>/widgets/`에 둔다. 여러 feature 공유 시에만 `shared/`로 올린다.
- `core/`에는 UI 코드를 넣지 않는다.

### API 호출
- HTTP 클라이언트는 `Dio`를 사용한다 (`core/api/api_client.dart`).
- 도메인별로 서비스 클래스를 만들어 `ApiClient`를 주입받아 사용한다.
- baseUrl 등 환경별 설정은 `api_client.dart`에서 관리한다.
