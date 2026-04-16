# CLAUDE.md

이 파일은 Claude Code(claude.ai/code)가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 프로젝트 개요

**데일리 스케줄 키퍼(Daily Schedule Keeper)** — 사용자가 자기계발 목표를 관리하고 여유시간을 효과적으로 활용하도록 돕는 앱.

주요 기능(예정):
- 목표 북마크 저장 후 요일별 달성도 확인
- 하루 여유시간 트래킹
- 카테고리 검색으로 자기계발 루틴 등록
- AI 리서치로 목표 달성까지 필요한 시간을 산정하여 timed goal 세팅
- 데일리 루틴 체크리스트로 매일 진행 상황 기록
- 앱의 경우 기본적으로 휴대용 기기에 데이터 저장 로그인한 회원만 서버 저장 (실시간 동기화가 아님)
- AI 알고리즘 기반 도서·영상·제품 추천

## 기술 스택

- **frontend**: Flutter (Dart `^3.11.4`)
- **backend**: FastAPI (Python `>=3.14`), `uv`로 의존성 관리

## 개발 커맨드

### 백엔드 (`/backend`)

```bash
# 의존성 설치
uv sync

# 개발 서버 실행 (hot reload)
make start
# 또는 직접 실행:
uv run uvicorn main:app --reload
```

### 프론트엔드 (`/frontend`)

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run

# 테스트 실행
flutter test

# 특정 테스트 파일만 실행
flutter test test/<file>_test.dart

# 린트
flutter analyze
```

## 아키텍처

프로젝트는 초기 단계이며 최소한의 스켈레톤만 갖추고 있습니다.

- `backend/main.py` — FastAPI 앱 엔트리포인트. 현재 모든 라우트가 이 파일에 위치
- `frontend/lib/main.dart` — Flutter 앱 엔트리포인트

백엔드는 REST API를 제공하고, Flutter 프론트엔드가 이를 소비하는 구조입니다. 기능이 늘어남에 따라 백엔드는 도메인별 라우터/서비스(goals, routines, recommendations 등)로 분리하고, 프론트엔드는 `lib/` 아래 feature 단위 모듈로 구조화해야 합니다.
