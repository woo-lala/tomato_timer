# PROGRESS.md — 현재 상태와 다음 할 일

작업 세션 사이의 인계 문서. 상태가 바뀌면 이 파일을 갱신한다.
기능 명세는 [SPEC.md](SPEC.md), 빌드 명령·컨벤션은 [CLAUDE.md](CLAUDE.md), 세션별 인수인계는 [HANDOVER.md](HANDOVER.md).

**최종 갱신: 2026-08-15** (레거시 점검 리포트 반영 + git 저장소 도입)

---

## 1. 현재 상태

| 항목 | 값 |
|---|---|
| VCS | GitHub [`woo-lala/sequential_timer`](https://github.com/woo-lala/sequential_timer). 기준 브랜치 `main` (`b244327`) — 2026-08-15 PR #3 병합으로 개인정보 시트와 문서가 모두 반영됨 |
| 빌드 | ✅ 성공 (2026-08-15 확인, Xcode 26.5 / Build 17F42) |
| 테스트 | ❌ 테스트 타겟 없음 |
| 타겟 | `Sequential Timer` 단일, iOS 26.0, `com.ner.sequentialtimer` |
| 버전 | `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1` |
| 서명 | `DEVELOPMENT_TEAM = ""` (미설정 — 실기기 빌드/배포 불가) |
| 의존성 | Firebase iOS SDK 12.8.0 (Analytics / Auth / Firestore), SPM |

**확인용 빌드 명령**
```bash
xcodebuild -project "Sequential Timer.xcodeproj" -scheme "Sequential Timer" \
  -destination 'generic/platform=iOS Simulator' build
```

> 2026-08-15에 기존 GitHub 저장소와 연결했다. 로컬 코드는 원격 `feature/app-frontend-ui`(`b84e9de`, 2026-02-08)와 **바이트 단위로 동일**했으므로 코드 손실 없이 그 위로 올라탔고, PR #3으로 `main`에 병합했다. 2026-02-08 이후 6개월간 병합되지 않았던 개인정보 설정 화면도 이때 함께 들어갔다.
> 병합이 끝난 `feature/app-frontend-ui`는 원격에 남아 있다(삭제 여부 미결). 새 작업은 `main`에서 브랜치를 따서 진행한다.
> **`GoogleService-Info.plist`는 저장소 `.gitignore`가 제외한다**(원격 히스토리에 한 번도 커밋된 적 없음). 로컬 파일은 빌드에 필요하니 지우지 말 것. CLAUDE.md의 "committed" 표현은 "앱 폴더에 존재한다"는 뜻으로 읽어야 한다.
> `.vscode/settings.json`, `xcuserstate`, `xcschememanagement.plist`는 ignore 규칙 추가 **이전에** 커밋돼 아직 추적 중이다. 정리하려면 별도 커밋이 필요하다.

---

## 2. 완료된 기능

동작 세부는 SPEC.md 참조. 요약하면 다음이 끝나 있다.

- 루틴 CRUD, 드래그 순서 변경, 기본/사용자 템플릿
- 실행 설정 시트(알림 모드 3종, 전환 모드 2종, 기본/이전 프리셋)
- 타이머 실행: 벽시계 기반 계산, manual/auto 전환, 일시정지·재개·건너뛰기·정지·완료
- 로컬 알림 예약/취소/재예약, 백그라운드 복귀 동기화
- 세션 상태 UserDefaults 영속화 및 복구 로직
- Firestore 업로드 전용 동기화(영속 큐, 해시 중복 제거, KST 1일 1회)
- 테마 5종, 설정 화면, 한국어/영어 현지화

---

## 3. 미완료 작업

### 3.1 광고 + IAP (스펙 작성됨, 구현 0%)
`Sequential Timer/SequentialTimer_Ads_IAP_TASK.md` 에 한국어 작업 지시서가 있다. 요지:

- 루틴 완료 시 AdMob 전면광고 1회 + 비소모성 IAP("광고 제거", StoreKit 2)
- **구현 전에 2장(프로젝트 파악) 결과를 먼저 사람에게 보고하고 승인받을 것** — 문서가 명시적으로 요구
- 도메인(타이머) 레이어에 `GoogleMobileAds`/`StoreKit` import 금지, 프로토콜 경유만 허용
- 디버그 빌드는 Google 공식 테스트 광고 단위 ID 사용 (실 광고 클릭 시 계정 정지 위험)
- `<<...>>` 자리표시자(AdMob 앱 ID, 상품 ID, SKAdNetworkItems, 빈도 캡)는 사람이 채워야 함 — **임의로 지어내지 말 것**

지시서가 요구하는 "완료 이벤트 위치"는 이미 파악돼 있다: `TimerRunningView.finishSession()` (TimerRunningView.swift:448).

### 3.2 그 밖에 남은 것
- **테스트 타겟 없음.** `SequentialTimerEngine`, `SyncBuilders`(`RoutinePayloadHasher`, `SessionSummaryBuilder`, `SyncDateUtils`), `SessionState.activeElapsedSeconds`가 순수 함수라 우선 대상
- **`SessionStep` 기록 없음** — 아래 4.1 참조
- **아카이브 UI 없음** — `isArchived` 필드와 조회 조건은 있으나 켜는 경로가 없다
- **Firestore 보안 규칙이 저장소에 없음** — 익명 인증만으로 `users/{uid}/**` 에 쓰고 있어 규칙 확인 필요
- **`DEVELOPMENT_TEAM` 미설정** — 실기기/TestFlight 전 필요

---

## 4. 알려진 이슈

우선순위 순. 각 항목은 코드에서 확인한 사실이다. 4.0 및 4.9~4.12는 2026-08-15 `/audit-legacy` 점검에서 새로 발견한 것으로, 전체 근거는 [audit-report-2026-08-15.md](audit-report-2026-08-15.md)에 있다.

### 4.0 auto 모드 완료 후 `finishSession()`이 매초 재실행된다 ⚠️ 최우선
`finishSession`(TimerRunningView.swift:448-465)이 `SessionStore.clear()`만 하고 `sessionState`(@State)는 non-nil · `isPaused == false`로 남긴다. 완료 알럿이 떠 있는 동안 1초 타이머가 계속 돌아 `onReceive` 가드(281줄)를 통과 → `syncDisplay` → 575-580줄에서 **매 초 `finishSession()` 재호출**. 그때마다 `updateSession(endedAt: Date())`가 실행돼 **Core Data의 종료 시각이 알럿을 띄워둔 시간만큼 계속 뒤로 밀리고**, 그 값이 `actualDurationSeconds`로 Firestore에 올라간다.
→ `stopSession`(440줄)은 `sessionState = nil`을 하는데 `finishSession`만 빠져 있다. 한 줄로 대칭을 맞추면 된다.

### 4.1 `ABANDONED` 세션의 `completedStepCount`가 항상 0
`CoreDataManager.createSessionStep`(CoreDataManager.swift:200)은 **어디서도 호출되지 않아** `SessionStep` 레코드가 만들어지지 않는다. 그런데 `SessionSummaryBuilder.resolveCompletedStepCount`(SyncBuilders.swift:125)는 중도 포기 세션의 완료 단계 수를 `session.steps`에서 센다 → 항상 빈 집합 → 0. 업로드되는 중도 포기 통계가 무의미하다.
→ 실행 중 단계 완료 시 `SessionStep`을 기록하거나, `SessionState.currentStepIndex`로 대체 산출해야 한다.

### 4.2 오프라인이면 그날 동기화가 통째로 스킵된다
`SyncManager.handleAppBecameActive`(SyncManager.swift:24-27)가 **네트워크 도달성을 확인하기 전에** `recordSyncAttempt`로 오늘 날짜를 먼저 기록한다. 앱 활성화 시점에 오프라인이면 그날치 시도가 소진되고, 이후 온라인이 돼도 **다음 KST 날짜가 될 때까지 재시도하지 않는다.** 인증 실패도 같은 결과.
→ 실제 시도(또는 성공) 시점에만 기록하거나, 네트워크 복구 시 재시도 훅을 붙여야 한다.

### 4.3 마이그레이션 실패 시 사용자 데이터가 조용히 삭제된다
`PersistenceController.init`(PersistenceController.swift:19-42)은 스토어 로드 실패 시 `destroyPersistentStore` 후 새로 만든다. 경량 마이그레이션이 불가능한 모델 변경을 하면 **경고 없이 전체 데이터가 날아간다.** Core Data 모델을 건드릴 때 반드시 인지할 것.

### 4.4 번들 사운드 리소스가 존재하지 않는다
`NotificationSound.audioResourceName`(DesignSystem.swift:148)이 `short_alert` / `soft_chime`을 가리키지만 저장소에 해당 오디오 파일이 없다. 결과:
- 로컬 알림음(TimerRunningView.swift:734)은 없는 리소스를 참조 → 시스템 기본음으로 폴백
- 앱 내 재생(`AudioManager.playSound`, TimerRunningView.swift:986)은 리소스를 아예 무시하고 `SystemSoundID` 1007/1003/1001을 하드코딩해 재생

즉 "짧은 알림 / 부드러운 알림" 선택이 알림 배너에서는 사실상 구분되지 않는다. 리소스를 추가하거나 선택지를 정리해야 한다.

### 4.5 세션 복구 경로가 도달 불가
`TimerRunningView`의 진입 지점이 전부 `forceNewSession: true`(RoutineListView.swift:211, 315)라서, `loadOrStartSession`의 저장 상태 복구 분기(TimerRunningView.swift:352)는 실행되지 않는다. 앱을 종료했다가 다시 켜면 진행 중이던 세션으로 돌아갈 방법이 없다(`SessionState`는 남아 있는데 쓰이지 않음).
→ "진행 중인 루틴 이어하기" 진입점을 추가하거나, 복구 코드를 정리해야 한다.

### 4.6 전역 "화면 꺼짐 방지" 설정이 기존 루틴에 반영되지 않는다
`CoreDataManager.createRoutine`(CoreDataManager.swift:22)이 `UserDefaults`의 `keepScreenOn`을 **생성 시점에 한 번만** 복사한다. 설정 화면에서 값을 바꿔도 이미 만든 루틴은 그대로다. 의도된 동작일 수 있으나 설정 화면 문구상 오해 소지가 있다.

### 4.7 앱 버전이 하드코딩
`SettingsView.swift:187`이 `"1.0.0"` 문자열을 직접 표시한다. `MARKETING_VERSION`(1.0)과 이미 다르다. `Bundle.main`의 `CFBundleShortVersionString`을 읽도록 바꾸는 게 맞다.

### 4.8 편집할 때마다 `stepId`가 새로 발급된다
`RoutineCreateView.saveRoutine`(RoutineCreateView.swift:309-339)이 기존 단계를 전부 삭제하고 새로 만든다. 단계 이름·시간이 그대로여도 `stepId`가 바뀌므로 `RoutinePayloadHasher` 해시가 달라져 **불필요한 재업로드**가 발생하고, 단계 단위 이력 추적이 불가능하다.

### 4.9 "이전 설정" 프리셋이 `lastUsed*` 키를 읽지 않는다
`NotificationModeSheet.startRoutine`(165-166줄)은 `lastUsedSound` / `lastUsedVibration`에 저장하는데, `loadLastUsedSettings`(154-159줄)는 **`defaultNotificationSound` / `defaultNotificationVibration`(설정 화면 기본값)** 을 읽는다. 그래서 "기본"과 "이전 설정" 버튼이 사운드·진동 **종류**에 대해 같은 값을 넣고, on/off 플래그만 다르다. 반면 `TimerRunningView.loadLastNotificationConfiguration`(327-343줄)은 정반대로 `lastUsed*`를 신뢰한다 — 같은 키를 두 화면이 다르게 취급.
→ 4.4(번들 사운드 부재)와 묶어 "알림음 선택을 살릴지 없앨지"를 함께 결정해야 한다. (2026-08-15 발견)

### 4.10 정지·완료 시 반복 알림음이 취소되지 않는다
`maybeShowManualAlert`가 `playNotificationRepeating(count: 5, interval: 2.2)`로 예약한 `DispatchWorkItem` 최대 5개를 `stopSession` / `finishSession` 어느 쪽도 취소하지 않는다. 정지 후 화면을 닫아도 최대 ~9초간 소리가 이어진다. `startNextStepFromManualAlert`(869줄)와 `handleManualAlertLater`(900줄)에는 취소가 있어 **경로별로 비대칭**. (2026-08-15 발견)

### 4.11 manual 모드 `waitingForNext`에서 재생 버튼이 무동작
`resumeSession`(410-427줄)이 `stepRunState`만 `.running`으로 되돌리고 **단계 인덱스를 진행시키지 않아** 곧바로 같은 대기 상태로 복귀한다. 다음 단계로 가는 경로는 알럿의 "지금 시작"뿐인데 알럿은 단계당 1회만 뜬다(`hasShownManualAlertForStep`). 알럿을 놓친 사용자가 갇히는지는 실행 확인 필요. 같은 맥락에서 "나중에"(881-903줄)는 이름과 달리 **단계를 진행시킨다** — 의도된 정의를 SPEC.md에서 확인할 것. (2026-08-15 발견)

### 4.12 세션 상태를 문자열 리터럴로 기록한다
쓰는 쪽(CoreDataManager.swift:144, TimerRunningView.swift:404·424·432·451)은 `"RUNNING"` / `"PAUSED"` / `"COMPLETED"` / `"ABANDONED"` 리터럴, 읽는 쪽(SyncBuilders.swift:94·126)은 `SessionStatus` enum. enum이 있는데 쓰기 경로가 쓰지 않아, 오타 한 글자면 빌더가 `nil`을 반환해 **업로드가 조용히 스킵**된다. (2026-08-15 발견)

---

## 5. 데드 코드

지울지 살릴지 결정 필요.

| 대상 | 위치 | 상태 |
|---|---|---|
| `RoutineDetailView` | RoutineDetailView.swift:5 (214줄) | 자기 `#Preview` 외 참조 없음. 목록에서 편집 화면으로 바로 가므로 미사용 |
| `RoutineCard` | RoutineListView.swift:262 | `CDRoutineCard`로 대체됨, 미사용 |
| `CoreDataManager` 미사용 API | `createSessionStep`, `fetchSessionSteps`, `updateSessionStep`, `deleteSessionStep`, `fetchRoutine(by:)` 일부, `fetchSessions(for:)` | 4.1과 연결 |
| `SyncManager.calendar` | SyncManager.swift:13 | 선언만 되고 사용 안 함 |
| `AudioManager.audioPlayer` | TimerRunningView.swift:970 | `AVAudioPlayer` 필드가 항상 nil, `stop()`도 무의미 |
| `resolveProgress` / `StepProgress` | SequentialTimerEngine.swift:11, 37 | 호출 0건. 같은 로직을 `TimerRunningView.syncDisplay`(567-574줄)가 인라인 재구현 — "타이머 계산은 엔진에" 불변식이 깨진 상태 |
| `hasSyncedOnce` / `lastSyncedStepIndex` | TimerRunningView.swift:29-30, 604-611 | 대입·분기만 하고 결과로 아무 동작도 하지 않는 **쓰기 전용 상태**. 단계별 동기화를 붙이려던 자리로 보임 (4.1과 연결) |
| `backgroundRepeatInterval` | TimerRunningView.swift:37, 693 | `backgroundRepeatCount = 1`이라 항상 ×0. 반복 알림은 실제로 1회뿐이고, 815줄은 `count: 5, interval: 2.2`를 따로 하드코딩 |
| `OptionRow` / `InfoRow` | SettingsView.swift:242, 277 | 참조 0건 |
| `ThemeMode` / `AccentColorType` | Theme.swift:5, 10 | `ThemeSelection` 통합 이전의 잔재, 참조 0건 |
| `AppColor` + `Color.md*` 팔레트 | DesignSystem.swift:6-98 | `ThemePalette`로 대체된 구 색 시스템. `AppColor.` 사용처 0건 (`Color.init(hex:)` 자체는 Theme.swift가 사용하므로 남겨야 함) |
| `RoutineDetailView` 전용 로컬라이즈 키 7개 | ko/en `.strings` (`routine.detail.*` 4, `duration.long.*` 3) | 죽은 뷰에서만 참조 — 뷰 제거 시 함께 정리 |

> 로컬라이즈 키 전체는 ko/en 154개가 완전히 일치하고 미사용 키는 없다(2026-08-15 확인). 코드 내 TODO/FIXME도 0건.

---

## 6. 다음 세션 제안 순서

1. ~~버전 관리 확보~~ ✅ 2026-08-15 완료 — GitHub 저장소 연결 + PR #3 `main` 병합 (`b244327`)
2. **4.0 `finishSession`에 `sessionState = nil` 추가** — 한 줄, 데이터 오염이 계속되는 중이라 최우선
3. 4.2 동기화 재시도 로직 수정 (사용자 데이터 유실 위험 없음, 효과 큼)
4. 4.10 정지·완료 시 반복 알림음 취소 (한 줄, 체감 큰 버그)
5. 4.9 + 4.4 알림음 선택 방향 결정 → 리소스 추가 또는 선택지 제거
6. 저위험 정리: 4.7 앱 버전, 5장 데드 코드 제거
7. 테스트 타겟 추가 + `SequentialTimerEngine` / `SyncBuilders` 단위 테스트 (5장의 `resolveProgress` 정리를 먼저)
8. 4.1 `SessionStep` 기록 (Core Data 모델 변경 없음 — 4.3 위험 없음)
9. 4.5 세션 이어하기 UX 결정 → 구현 또는 코드 정리
10. 광고/IAP는 위 정리가 끝난 뒤, 지시서의 "파악 → 보고 → 승인" 절차대로 착수
