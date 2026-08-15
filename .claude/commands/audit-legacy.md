---
description: 죽은 코드/중복 로직/논리적 모순/방치된 TODO/미사용 의존성을 점검하고 리포트만 생성 (코드 수정 없음)
argument-hint: "[선택: 점검 범위 경로 또는 항목 번호, 예: Sequential Timer/Sync 또는 3]"
allowed-tools: Read, Grep, Glob, Bash(date:*), Bash(rg:*), Bash(grep:*), Bash(ls:*), Bash(find:*), Bash(wc:*), Write
---

# /audit-legacy — 레거시/모순 코드 점검

Sequential Timer(MaDay) 프로젝트에 누적된 **불필요한 코드, 중복 로직, 논리적 모순, 방치된 TODO, 미사용 의존성**을 점검하고 마크다운 리포트를 생성한다.

범위 인자: `$ARGUMENTS` (비어 있으면 `Sequential Timer/` 전체를 점검한다. 경로가 주어지면 그 경로만, 숫자가 주어지면 아래 체크리스트의 해당 항목만 점검한다.)

## 절대 규칙 (위반 금지)

1. **코드를 절대 수정하지 않는다.** Edit / 코드 파일에 대한 Write / 파일 이동·삭제·포맷팅·자동 수정 금지. 이 커맨드의 유일한 쓰기 작업은 리포트 파일 1개 생성이다.
2. **수정 제안은 리포트 안의 텍스트로만 남긴다.** "제거하면 됩니다"라고 쓰되, 실제로 제거하지 않는다. 사용자가 이어서 "고쳐줘"라고 명시적으로 요청하기 전에는 손대지 않는다.
3. **확신이 없으면 단정하지 않는다.** 근거가 grep 결과 등으로 명확히 확인된 항목만 단정하고, 나머지는 `확인 필요`로 표시하며 *무엇을 확인해야 판정되는지*를 함께 적는다.
4. **빌드/테스트를 돌리지 않는다.** 이 점검은 정적 읽기 기반이다.

## 이 프로젝트에서 주의할 점 (오탐 방지)

정적으로는 "미사용"으로 보이지만 실제로는 살아 있는 것들이 있다. 아래는 **단정하지 말고 반드시 `확인 필요`로 분류**한다.

- **SwiftUI/런타임 간접 참조**: `@FetchRequest`, `Environment` 키, `ObservableObject` 프로퍼티, `PreviewProvider`/`#Preview` 전용 코드, `@objc`/셀렉터, `AppDelegate` 델리게이트 메서드는 호출부가 코드에 안 보여도 사용 중일 수 있다.
- **Core Data 생성 클래스**: `Routine` / `RoutineStep` / `Session` / `SessionStep` / `UploadQueueItem` 는 `codeGenerationType="class"`라 소스 파일이 없다. "정의를 못 찾음"을 죽은 코드로 오판하지 말 것.
- **문자열 키 참조**: `Text("some.key")` 처럼 리터럴 키로 해소되는 로컬라이즈 문자열, `UserDefaults` 키(`seqtimer.*`), 알림 식별자는 심볼 검색으로 잡히지 않는다. 미사용 판정 시 `en.lproj`/`ko.lproj` 양쪽을 함께 확인한다.
- **저장된 raw value**: `NotificationSound` 등 사용자 노출 enum의 raw value는 `UserDefaults`/`SessionState`에 저장된다. "안 쓰는 케이스"로 보여도 과거 저장값 디코딩용일 수 있다.
- **`#if canImport(...)` 분기**: `Sync/` 의 Firebase 경로는 SDK 부재 시 degrade 하도록 의도된 것이다. 이를 "도달 불가능한 분기"로 보고하지 말 것.
- **`SessionState`의 수기 `Decodable` init**: 모든 필드에 기본값 폴백이 있는 것은 의도된 설계다. 중복처럼 보여도 결함이 아니다.

## 점검 체크리스트

각 항목마다 실제로 grep/파일 읽기를 수행해 근거를 확보한 뒤 기록한다. 근거 없는 추측은 리포트에 넣지 않는다.

### 1. Dead code

- 어디서도 호출되지 않는 `func` / `class` / `struct` / `enum` / 프로퍼티. 판정 방법: 심볼 이름으로 저장소 전체 검색 → 정의 1곳 + 참조 0곳이면 후보. `private` 심볼은 파일 내부만 보면 되므로 신뢰도가 높고, `internal`/`public`은 간접 참조 가능성 때문에 신뢰도가 낮다.
- 주석 처리된 채 방치된 코드 블록 (`// let x =`, `/* ... */` 안의 실행 코드).
- 도달 불가능한 분기: 항상 참/거짓인 조건, 앞선 `return`/`guard` 뒤의 코드, 절대 매칭되지 않는 `switch` 케이스, 사용되지 않는 enum 케이스.
- 사용되지 않는 로컬라이즈 키 (`en.lproj`/`ko.lproj` 에는 있으나 코드에서 참조 없음), 그리고 **한쪽 언어 파일에만 있는 키**(이건 결함이므로 단정 가능).
- 참조되지 않는 애셋/파일.

### 2. 중복 / 유사 로직

- 같은 일을 하는 함수가 여러 파일에 흩어진 경우. 특히 이 프로젝트에서 반복되기 쉬운 것들:
  - 시간 포맷팅 / 초→분:초 변환
  - 타이머 경과 시간 계산 (`SequentialTimerEngine` 밖에서 직접 계산하는 코드가 있으면 아키텍처 위반이므로 기록)
  - 알림 식별자 생성 및 스케줄/취소 로직 (`TimerRunningView` vs 그 외)
  - 색상/스타일 정의 (`Theme.swift` 팔레트 vs `DesignSystem.swift` 의 `AppColor`/`Color(hex:)` — 두 테마 시스템이 겹치는 지점)
  - Core Data 저장 경로 (`CoreDataManager` vs 뷰에서 `@Environment(\.managedObjectContext)` 직접 사용)
- 복사-붙여넣기 흔적(동일한 5줄 이상 블록)도 후보로 기록한다.

### 3. 논리적 모순

- **같은 상태값을 서로 다른 조건으로 체크하는 곳**: 예) `status == "RUNNING"` 을 어떤 곳은 문자열 비교, 다른 곳은 `SessionStatus` enum 으로 비교하거나, 한쪽은 `PAUSED`를 포함하고 다른 쪽은 누락하는 경우.
- **타이머 상태 전이 불일치**:
  - `SessionState` (UserDefaults, `seqtimer.sessionState.v1`) 와 Core Data `Session.status` 가 서로 어긋날 수 있는 경로 (한쪽만 갱신하고 끝나는 코드 경로).
  - `StepTransitionMode.manual` 과 `.auto` 가 종료/스킵/일시정지에서 다르게 처리되어 한쪽에만 있는 보정(overshoot → `accumulatedPausedSeconds` 접기 등)이 빠진 곳.
  - `startAt` 되감기(스킵) 와 경과 시간 파생 계산이 충돌할 수 있는 지점.
  - `stopSession` / `finishSession` 경로에서 알림 취소·큐 적재·상태 저장 중 일부만 수행되는 비대칭.
  - `scenePhase` 변화 시 알림 취소-재스케줄이 특정 상태(예: `waitingForNext`)에서 누락되는지.
- **StoreKit / IAP 검증 로직의 예외 케이스 누락**: 현재 저장소에 StoreKit 구현이 **없으면**(`SequentialTimer_Ads_IAP_TASK.md` 는 미구현 스펙) 그 사실을 리포트에 "해당 없음 — 미구현"으로 명시하고 넘어간다. 구현이 있으면 다음을 점검: 구매 취소/보류(`.pending`), 검증 실패(`.unverified`), 복원 미처리, 트랜잭션 `finish()` 누락, 환불/만료 반영 누락, 오프라인 시 엔타이틀먼트 판정.
- **동기화 로직 모순**: KST 하루 1회 플러시(`SyncDateUtils`) 와 디바이스 타임존 사용이 섞인 곳, `RoutinePayloadHasher` 디듀프가 무력화되는 경로, `SyncConstants.schemaVersion` 과 실제 DTO 모양의 불일치.

### 4. 방치된 TODO / FIXME

- `TODO`, `FIXME`, `HACK`, `XXX`, `임시`, `나중에`, `일단` 등을 검색한다.
- 각 항목이 이미 해결된 것으로 보이는지(주변 코드가 이미 그 일을 하고 있는지) 판단해 **"이미 해결됨 — 주석만 남음"** / **"여전히 유효"** / **확인 필요** 로 분류한다.
- `SPEC.md`, `SequentialTimer_Ads_IAP_TASK.md` 안의 미완료 항목 중 코드와 어긋나는 것도 함께 본다.

### 5. 사용하지 않는 의존성

- 이 프로젝트에는 `Package.swift` 도 `Podfile` 도 없다. 의존성은 **Xcode 프로젝트의 SPM 참조**로 관리된다. 따라서 아래를 기준으로 점검한다:
  - `Sequential Timer.xcodeproj/project.pbxproj` 의 `XCRemoteSwiftPackageReference` 및 `XCSwiftPackageProductDependency` (현재: firebase-ios-sdk → FirebaseAnalytics / FirebaseAuth / FirebaseFirestore)
  - `Sequential Timer.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- 각 링크된 프로덕트에 대해 대응하는 `import` 가 소스에 실제로 존재하는지 확인한다. `#if canImport(...)` 로만 감싸인 import 도 사용으로 간주한다.
- 프레임워크 import 중 실제 사용처가 없는 것(예: 파일 상단에만 있고 심볼 사용 0회)도 낮은 위험도로 기록한다.
- `GoogleService-Info.plist` 와 Firebase 설정의 정합성도 확인한다.

## 리포트 작성

`date +%Y-%m-%d` 로 날짜를 구하고, 프로젝트 루트에 `audit-report-{YYYY-MM-DD}.md` 로 저장한다. 같은 날짜 파일이 이미 있으면 덮어쓰지 말고 `audit-report-{YYYY-MM-DD}-2.md` 처럼 접미사를 붙인다.

각 발견 항목은 반드시 아래 형식을 따른다.

```markdown
- [ ] **`파일경로:라인`** — 한 줄 요약
  - **왜 문제인지**: (구체적으로. "정리 필요" 같은 막연한 표현 금지)
  - **근거**: (검색 결과·읽은 코드 등 판정 근거. 예: "심볼 `foo` 참조 0건, private 선언")
  - **위험도**: 상 | 중 | 하
  - **판정**: 확정 | 확인 필요 — (확인 필요면 무엇을 확인해야 결론이 나는지)
```

위험도 기준:
- **상** — 사용자에게 보이는 버그를 이미 일으킬 수 있음(상태 불일치, 데이터 유실, 결제/동기화 오류) 또는 데이터 손상 위험.
- **중** — 지금 당장 버그는 아니지만 다음 수정 때 실수를 유발할 구조(중복 로직, 두 갈래 상태 관리).
- **하** — 순수 정리 대상(죽은 코드, 방치된 주석, 미사용 키).

### 리포트 템플릿

````markdown
# 레거시 코드 점검 리포트 — {YYYY-MM-DD}

- 점검 범위: {경로 또는 "Sequential Timer/ 전체"}
- 점검한 Swift 파일 수: {N}
- 발견 항목: 상 {n}건 / 중 {n}건 / 하 {n}건 (확인 필요 {n}건 포함)
- **이 리포트는 코드를 수정하지 않았습니다.**

## 1. Dead code
## 2. 중복 / 유사 로직
## 3. 논리적 모순
### 3-1. 상태값 체크 불일치
### 3-2. 타이머 상태 전이
### 3-3. StoreKit / IAP
### 3-4. 동기화(Sync)
## 4. 방치된 TODO / FIXME
## 5. 미사용 의존성

## 우선순위 Top 5

| # | 항목 | 파일:라인 | 위험도 | 왜 먼저인가 | 예상 작업량 |
|---|------|-----------|--------|-------------|-------------|
| 1 | | | | | |

## 확인 필요 목록
(단정하지 못한 항목과, 각각 무엇을 확인하면 결론이 나는지)

## 이번에 점검하지 못한 영역
(범위 밖이거나 정적 분석으로 판단 불가한 부분을 솔직히 기록)
````

각 섹션에 발견이 없으면 "발견 없음"이라고 명시한다. 억지로 항목을 채우지 말 것 — **빈 섹션은 실패가 아니라 결과다.**

## 마무리

리포트 저장 후 사용자에게는 다음만 간단히 보고한다: 저장 경로, 위험도별 건수, Top 5 제목 목록, 그리고 "수정은 별도 세션에서 진행하세요"라는 안내. 리포트 본문을 터미널에 통째로 다시 출력하지 않는다.
