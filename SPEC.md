# SPEC.md — Sequential Timer 기능 명세

현재 구현된 동작을 코드에서 역산해 정리한 문서. **"이렇게 만들 것"이 아니라 "지금 이렇게 동작한다"** 를 기술한다. 코드를 바꾸면 이 문서도 같이 갱신한다.

진행 상황·미완료 작업은 [PROGRESS.md](PROGRESS.md), 빌드 명령·컨벤션은 [CLAUDE.md](CLAUDE.md) 참조.

---

## 1. 개요

하나의 루틴(Routine)은 순서가 있는 여러 단계(RoutineStep)로 구성되고, 각 단계는 지정된 시간만큼 진행된다. 사용자가 루틴을 실행하면 세션(Session)이 만들어지고, 단계가 끝날 때마다 소리/진동으로 알린 뒤 다음 단계로 넘어간다.

- 플랫폼: iOS 26.0+, SwiftUI 단일 타겟
- 저장: Core Data(로컬 원본) + UserDefaults(실행 중 세션 상태)
- 원격: Firebase Firestore로 **업로드 전용** 백업 (다운로드 경로 없음)
- 언어: 한국어 / 영어

### 용어

| 용어 | 의미 |
|---|---|
| Routine | 단계들의 묶음. 사용자가 만들고 편집하는 대상 |
| RoutineStep | 루틴 안의 한 단계. `order` + `durationSeconds` |
| Session | 루틴 1회 실행 기록 (Core Data, 이력용) |
| SessionState | 실행 중인 세션의 복구용 스냅샷 (UserDefaults, 휘발성 아님) |
| Timeline | 단계들을 누적 오프셋으로 펼친 배열 (`StepTimelineItem`) |

---

## 2. 데이터 모델

`CoreData/SequentialTimer.xcdatamodeld` — 모든 엔티티 `codeGenerationType="class"` (클래스는 Xcode 자동 생성, 소스 파일 없음).

### Routine
`routineId: UUID`, `name: String`, `createdAt`, `updatedAt`, `isArchived: Bool`, `isTemplate: Bool`, `keepScreenOn: Bool`
관계: `steps` (→RoutineStep, Cascade), `sessions` (→Session, Cascade)

### RoutineStep
`stepId: UUID`, `routineId: UUID`, `order: Int16`, `title: String`, `durationSeconds: Int64`

### Session
`sessionId: UUID`, `routineId: UUID`, `startedAt`, `endedAt`, `status: String`, `pauseCount: Int16`, `createdAt`, `updatedAt`

`status` 값 (`SessionStatus`): `RUNNING` → `PAUSED` → `COMPLETED` | `ABANDONED`

### SessionStep
`sessionStepId`, `sessionId`, `stepOrder: Int16`, `plannedMinutes: Int16`, `actualSeconds: Int64`, `isCompleted: Bool`
> 스키마와 CRUD(`CoreDataManager.createSessionStep`)는 존재하지만 **현재 어디서도 생성하지 않는다.** PROGRESS.md의 알려진 이슈 참조.

### UploadQueueItem
`itemId`, `type` (`routine`|`session`), `entityId: UUID`, `status` (`pending`|`failed`), `createdAt`, `lastAttemptAt`, `attemptCount: Int16`, `payloadHash: String?`

### 정렬 규칙 (전역)
단계 정렬은 항상 `(order, stepId.uuidString)` 복합 비교. `order`가 같아도 순서가 흔들리지 않게 하기 위함이며, 목록·타임라인·동기화·해시 모든 경로에서 동일하게 적용된다.

---

## 3. 루틴 관리

### 3.1 목록 (`RoutineListView`)
- `@FetchRequest`로 `isArchived == false` 루틴을 `createdAt` 내림차순 표시
- 카드 1장 = 루틴 1개(`CDRoutineCard`). 표시 항목:
  - 이름
  - 단계 시간 요약: 앞 3개까지 `·` 구분, 초과분은 `routine.list.steps.more` 로 "외 N개"
  - 최근 실행일 → 없으면 생성일 → 없으면 수정일 순으로 폴백
- 카드 탭 → 편집(`RoutineCreateView`), 재생 버튼 → 실행 설정 시트
- 삭제: 컨텍스트 메뉴 + 스와이프
- `.sessionStarted` 알림 수신 시 `refreshTrigger` 갱신으로 목록 재계산
- 우상단 톱니 → `SettingsView`

### 3.2 생성 / 편집 (`RoutineCreateView`)
`routine: Routine?` 이 `nil`이면 생성, 아니면 편집 모드.

**저장 조건 (`canSave` = `isValid && isDirty`)**
- 이름 비어있지 않음
- 단계 1개 이상
- 모든 단계 이름이 공백이 아님
- 모든 단계 시간이 0이 아님
- 편집 모드에서는 이름/템플릿여부/단계 중 하나라도 초기값과 달라야 함 (생성 모드는 항상 dirty)

위반 시 저장 버튼이 비활성화되고, `saveRoutine()` 직접 호출 시에는 해당 검증 메시지를 알럿으로 띄운다.

**시간 입력 포맷**: 단계 시간은 UI에서 `"MMSS"` 꼴 숫자 문자열로 보관한다(예: `"3000"` = 30분 00초, `"1000"` = 10분 00초).
- `totalSecondsFromStorage`: 뒤 2자리는 초(0–59로 clamp), 나머지는 분. 2자리 이하면 전부 초로 해석
- `storageString(from:)`: `"\(총분)\(초 2자리)"`
- 분에는 상한이 없다

**단계 순서 변경**: `DragRelocateDelegate` 기반 드래그 앤 드롭 (`UTType.text`)

**편집 시 저장 절차**: 기존 `RoutineStep`을 전부 삭제 → 컨텍스트 저장 → 입력된 단계를 `order = 배열 인덱스`로 새로 생성 → 저장. 즉 편집 시 `stepId`는 매번 새로 발급된다.

저장 성공 후 `RoutinePayloadHasher.hash(for:)` 를 계산해 `SyncManager.enqueueRoutine`으로 업로드 큐에 넣는다.

### 3.3 템플릿
두 종류가 공존한다.
1. **기본 제공 템플릿** (`defaultTemplates`, 하드코딩): "출퇴근" 30/10/20, "수업" 50/10/50/10
2. **사용자 저장 템플릿**: 루틴 편집 화면의 토글로 `isTemplate = true` 로 표시한 루틴. `fetchTemplateRoutines()`(`isTemplate == true AND isArchived == false`)로 조회해 칩으로 노출

템플릿 칩을 누르면 이름과 단계 목록이 현재 편집 중인 폼에 **복사**된다(참조가 아니라 값 복사).

### 3.4 삭제 / 아카이브
- 삭제는 Core Data 삭제이며 Cascade로 단계·세션이 함께 사라진다
- `isArchived`는 스키마·조회 조건에는 있으나 이를 켜는 UI 경로가 없다

---

## 4. 실행 설정 시트 (`NotificationModeSheet`)

루틴 카드의 재생 버튼을 누르면 `.medium` 디텐트 시트로 뜬다. 여기서 정한 값이 `TimerRunningView`로 전달된다.

**프리셋**
- "기본": 소리 ON / 진동 OFF + 설정 화면의 기본 사운드·진동
- "이전": 마지막으로 사용한 ON/OFF 조합 (`lastUsedSoundEnabled`, `lastUsedVibrationEnabled`)
- 시트 진입 시 기본값은 "이전" 로드

**알림 모드** (`NotificationMode`): `sound` / `vibration` / `soundAndVibration`
- 내부적으로는 `useSound`, `useVibration` 두 불리언의 조합으로 결정
- 둘 다 끄면 시작 불가 (`canStart`)

**단계 전환 모드** (`StepTransitionMode`): `manual`(기본) / `auto`

시작 시 선택값을 `lastUsed*` 키에 저장하고 `onStart(routine, config, transitionMode)` 콜백을 호출한다.

---

## 5. 타이머 실행 (`TimerRunningView`)

### 5.1 시간 계산 원칙 (핵심)

**경과 시간은 벽시계에서 파생되며, 틱을 누적하지 않는다.**

```
elapsed = now - startAt - accumulatedPausedSeconds
```
(`SessionState.activeElapsedSeconds(now:)`, 일시정지 중이면 `now` 대신 `pausedAt` 사용, 하한 0)

1초 주기 `Timer.publish`는 오직 `syncDisplay(now:)`를 호출해 화면을 다시 계산할 뿐이다. 따라서 앱 백그라운드 전환, 프로세스 서스펜션, 타이머 드리프트가 자동으로 보정된다. 새 시간 관련 로직을 넣을 때 이 원칙을 깨지 말 것.

`SequentialTimerEngine`은 순수 함수 모음이다:
- `buildTimeline(from:)` → 각 단계의 `startOffset`/`endOffset` 누적 계산
- `resolveProgress(elapsedSeconds:timeline:)` → 경과 시간 → 현재 단계/잔여 시간/완료 여부

### 5.2 화면 구성
상단 카드에 `현재단계/전체단계` 뱃지, 단계 이름, `MM:SS`(1시간 이상이면 `HH:MM:SS`) 모노스페이스 타이머, 다음 단계 안내. 카드 아래 화면 꺼짐 방지 토글과 현재 실행 모드 표시(누르면 설정 시트 재오픈). 하단에 정지 / 일시정지·재개 / 건너뛰기 원형 버튼.

### 5.3 세션 시작·복구 (`loadOrStartSession`)
- `forceNewSession == true` → 저장된 `SessionState`를 지우고 새 세션 시작
- 아니면 저장된 상태의 `routineId`가 현재 루틴과 같을 때 그 상태로 복구, 아니면 새로 시작

새 세션 시작 시 Core Data `Session`(status `RUNNING`)을 만들고 `.sessionStarted`를 포스트한다. `SessionState`의 `sessionId`는 Core Data `Session.sessionId`와 동일하다.

> 현재 UI에서 `TimerRunningView` 진입 경로는 모두 `forceNewSession: true`라서 복구 분기는 실질적으로 도달하지 않는다.

### 5.4 단계 전환

**manual 모드** (기본)
1. 단계 종료 시각 도달 → 초과분(`elapsed - endOffset`)을 `accumulatedPausedSeconds`에 흡수해 시계를 정확히 유지
2. `isPaused = true`, `stepRunState = .waitingForNext`로 고정, 예약 알림 취소
3. 알럿 표시(`maybeShowManualAlert`) — 단계당 1회만(`hasShownManualAlertForStep`). 알림을 눌러 들어온 경우(`seqtimer.didOpenFromNotification`)가 아니면 2.2초 간격 5회 소리/진동 반복
4. "지금 시작" → 다음 단계로 이동하고 `startAt`을 `now - 다음단계.startOffset`으로 재작성, `accumulatedPausedSeconds = 0`
5. "나중에" → 다음 단계로 인덱스만 옮기고 `waitingForNext` 상태로 정지 유지 (마지막 단계면 완료 처리)

**auto 모드**
- `startAt`을 건드리지 않고 경과 시간으로 현재 인덱스를 유도
- 단계가 넘어갔고 앱이 포그라운드면 소리/진동 재생 + 1.2초 후 자동으로 닫히는 안내 알럿
- 마지막 단계 종료 시 `finishSession()`

### 5.5 조작

| 동작 | 결과 |
|---|---|
| 일시정지 | `isPaused = true`, `pausedAt = now`, Core Data status `PAUSED` + `pauseCount += 1`, 예약 알림 취소 |
| 재개 | 정지 구간을 `accumulatedPausedSeconds`에 더함, status `RUNNING`, 알림 재예약 |
| 건너뛰기 | 다음 단계로 이동(`startAt` 재작성, `accumulatedPausedSeconds = 0`). 마지막 단계면 완료 처리 |
| 정지 | Core Data `endedAt` 기록 + status `ABANDONED`, 세션 큐에 등록, 알림 취소, `SessionState` 삭제 |
| 완료 | 동일하되 status `COMPLETED`, 완료 알럿 표시 |

정지·완료 모두 `SyncManager.enqueueSession`을 호출한다.

### 5.6 화면 꺼짐 방지
- 루틴별 값(`Routine.keepScreenOn`)을 실행 화면 토글로 즉시 변경하며, 변경 시 Core Data에 바로 저장
- 화면 진입 시 `UIApplication.isIdleTimerDisabled`에 반영, 이탈 시 무조건 해제
- 루틴 **생성 시점**에 전역 설정(`UserDefaults "keepScreenOn"`)값을 초기값으로 복사한다

---

## 6. 로컬 알림

앱이 서스펜드되므로 알림은 **미리 예약**한다(`UNTimeIntervalNotificationTrigger`).

**식별자 규칙** (세션 UUID 기반이라 취소/재예약이 안전함)
- 단계: `seqtimer.<sessionId>.step.<index>`
- 완료: `seqtimer.<sessionId>.complete`
- manual 백그라운드 반복: `seqtimer.<sessionId>.step.<index>.repeat.<n>`

**예약 범위**
- auto: 남은 타임라인 전체를 한 번에 예약
- manual: 현재 단계 1건만 예약. 백그라운드 진입 시에는 `scheduleBackgroundRepeatNotificationsIfNeeded`로 반복 알림(`backgroundRepeatCount = 1`, 간격 2.2초)을 건다

**생명주기** (`scenePhase`)
- `active`: 화면 동기화 → manual 알럿 확인 → 예약분 정리 → 실행 중이면 재예약
- `background`/`inactive`: 모드에 맞춰 재예약

**표시 정책**: 앱이 떠 있을 때는 배너를 띄우지 않는다(`AppDelegate`가 `completionHandler([])`). 알림 탭으로 진입하면 `seqtimer.didOpenFromNotification`을 세우고 예약분을 정리한다.

**알림음**: `configuration.mode`가 진동 전용이면 무음, 아니면 `NotificationSound.audioResourceName`이 가리키는 번들 사운드, 없으면 `.default`.

---

## 7. 세션 상태 영속화 (`SessionState` / `SessionStore`)

- 저장 위치: `UserDefaults` 키 `seqtimer.sessionState.v1`, JSON 인코딩
- **동시에 하나의 세션만 존재**한다 (키가 하나)
- 필드: `sessionId`, `routineId`, `startAt`, `isPaused`, `pausedAt`, `accumulatedPausedSeconds`, `currentStepIndex`, `stepTransitionMode`, `stepRunState`, `notificationMode`, `notificationPatternId`, `scheduledNotificationIds`
- `init(from:)`이 수기로 작성되어 **모든 필드가 누락 시 기본값으로 폴백**한다. 필드를 추가할 때 이 규칙을 유지해야 기존 사용자의 저장 상태가 깨지지 않는다
- `stepRunState`: `running` / `waitingForNext` / `completed`
- `notificationPatternId`: 소리 모드는 `basic|short|soft`, 진동 모드는 `basic|short|double|heavy`

---

## 8. 동기화 (`Sync/`)

오프라인 우선, **업로드 전용**. Firestore는 백업/분석 싱크이며 절대 원본이 아니다.

### 8.1 흐름
1. **적재**: 루틴 저장 → `enqueueRoutine`, 세션 종료(정지/완료) → `enqueueSession`
2. **큐**: `UploadQueueStore`가 Core Data `UploadQueueItem`으로 영속화(앱 재시작에도 유지)
   - 루틴은 `payloadHash`가 같으면 재적재하지 않음 → 변경 없는 루틴은 재업로드되지 않음
   - 세션은 같은 `entityId`가 이미 있으면 무시
3. **플러시**: `SyncManager.handleAppBecameActive()` — `SequentialTimerApp`의 `scenePhase == .active`에서 호출
   - **KST(Asia/Seoul) 기준 하루 1회**만 시도 (`seqtimer.sync.lastSyncAttemptDate`). 기기 타임존이 아니라 서울 고정
   - 네트워크 도달 가능(`NWPathMonitor`) + 중복 실행 방지 플래그 확인
   - `pending` 또는 `failed` 상태 항목을 `createdAt` 오름차순으로 모아 병렬 업로드
4. **업로드**: 익명 로그인(`signInAnonymously`) 후
   - `users/{uid}/routines/{routineId}`
   - `users/{uid}/sessions/{sessionId}`
   - 둘 다 `setData(merge: true)`
5. **결과**: 성공 시 큐에서 제거, 실패 시 `failed` + `attemptCount += 1` (다음 날 재시도)

엔티티가 이미 삭제됐거나 DTO를 만들 수 없으면 큐에서 조용히 제거한다.

### 8.2 페이로드
`RoutineDTO`: 루틴 메타 + 정렬된 `steps[]` + `schemaVersion`
`SessionSummaryDTO`: 세션 요약. 주요 파생 필드
- `actualDurationSeconds` = `endedAt - startedAt`
- `date` = `startedAt`의 **KST** `yyyy-MM-dd`
- `patternKey` = 각 단계 분 단위를 `S{분}`으로 이어붙임 (예: `S25-S5-S25`)
- `completedStepCount`: `COMPLETED`면 계획 단계 수, `ABANDONED`면 `SessionStep` 중 완료 개수

`COMPLETED`/`ABANDONED`가 아니거나 필수 필드가 비면 DTO를 만들지 않는다(= 업로드하지 않는다).

### 8.3 추상화
`RemoteBackend` 프로토콜 뒤에 Firebase 구현이 있고, 모든 SDK 호출은 `#if canImport(FirebaseAuth/FirebaseFirestore)`로 감싸여 있다. SDK가 없어도 컴파일되고 실패 결과를 반환한다. `SyncConstants.schemaVersion`(현재 1)은 모든 문서에 기록되며 DTO 형태가 바뀌면 올린다.

---

## 9. 설정 (`SettingsView`)

| 섹션 | 항목 | 저장 키 |
|---|---|---|
| 타이머 | 화면 꺼짐 방지 기본값 | `keepScreenOn` |
| 알림 기본값 | 기본 알림음 (선택 시 즉시 재생) | `defaultNotificationSound` |
| 알림 기본값 | 기본 진동 (선택 시 즉시 재생) | `defaultNotificationVibration` |
| 테마 | 테마 선택 | `theme.selection` |
| 개인정보 | 데이터 수집 안내 시트 | — |
| 정보 | 앱 버전 (하드코딩 문자열) | — |

## 10. 테마 (`Theme.swift`)

`ThemeSelection`: `system` / `lightBlue` / `lightCoral` / `darkBlue` / `darkCoral`
- `system`이면 기기 다크모드에 따라 blue 팔레트 자동 선택, 나머지는 밝기까지 고정(`preferredColorScheme`)
- `ThemePalette` 필드: `background`, `surface`, `textPrimary`, `textSecondary`, `accent`, `border`, `shadow`
- `ThemeStore`(AppStorage 기반) → `ThemeProvider` → `@Environment(\.themePalette)` 로 주입

`DesignSystem.swift`의 `AppColor`는 구세대 정적 색상 시스템으로 남아 있고, `AppFont` / `AppSpacing` / `AppRadius`는 현역 타이포·간격 스케일이다.

## 11. 현지화

- `en.lproj` / `ko.lproj`의 `Localizable.strings`(각 169줄) + `InfoPlist.strings`(앱 표시명: "Sequential Timer" / "순차 타이머")
- SwiftUI `Text("some.key")`는 키를 암묵 해석하고, 포맷 문자열은 `String(format: String(localized: "key", locale: locale), ...)` + `@Environment(\.locale)` 패턴
- 영어 로케일에서만 "소리+진동" 라벨을 여러 줄 버전으로 교체한다(`localeUsesEnglishLineBreak`)
- **새 키는 반드시 두 파일 모두에 추가**

## 12. 권한·초기화

- `FirebaseApp.configure()` — `AppDelegate.didFinishLaunching`
- 알림 권한(`.alert, .sound, .badge`)은 타이머 화면 `onAppear`에서 요청
- 오디오 세션: `.playback` + `.duckOthers, .mixWithOthers`
- 햅틱: `CHHapticEngine` 준비를 시도하되, 실제 재생은 `UINotificationFeedbackGenerator`/`UIImpactFeedbackGenerator` 폴백 사용
