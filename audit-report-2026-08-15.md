# 레거시 코드 점검 리포트 — 2026-08-15

- 점검 범위: `Sequential Timer/` 전체
- 점검한 Swift 파일 수: 19개 (4,465줄) + `.strings` 2개 + `project.pbxproj` / `Package.resolved`
- 발견 항목: 상 2건 / 중 12건 / 하 8건 (확인 필요 7건 포함)
- **이 리포트는 코드를 수정하지 않았습니다.**

## 1. Dead code

- [ ] **`Sequential Timer/SequentialTimerEngine.swift:11,37`** — `StepProgress` / `resolveProgress` 가 어디서도 호출되지 않음 **[신규]**
  - **왜 문제인지**: 타이머 진행도 계산의 "정본"으로 만든 순수 함수인데, 실제 실행 화면은 이걸 쓰지 않고 `TimerRunningView.syncDisplay`(567-574줄)에서 같은 루프를 인라인으로 재구현했다. CLAUDE.md의 "타이머 계산은 `SequentialTimerEngine`에" 불변식이 이미 깨져 있고, 엔진만 고치면 동작이 안 바뀌는 함정이 된다.
  - **근거**: `resolveProgress` 전체 검색 → 정의 1건, 호출 0건. `StepProgress` 도 엔진 파일 내부 참조만.
  - **위험도**: 중
  - **판정**: 확정

- [ ] **`Sequential Timer/RoutineDetailView.swift:5`** — 214줄 뷰 전체가 미사용 **[기존: PROGRESS 5장]**
  - **왜 문제인지**: 목록 카드 탭 → `RoutineCreateView` 로 바로 가므로 진입 경로가 없다. 로컬라이즈 키 7개(`routine.detail.*` 4개, `duration.long.*` 3개 × ko/en = 14줄)가 이 뷰 때문에만 살아 있다.
  - **근거**: `RoutineDetailView` 참조 = 정의 + 자기 `#Preview` 뿐. 키별 역참조 결과 위 7개는 이 파일에서만 사용.
  - **위험도**: 하
  - **판정**: 확정

- [ ] **`Sequential Timer/RoutineListView.swift:262`** — `RoutineCard` 미사용 (`CDRoutineCard`가 대체) **[기존]**
  - **왜 문제인지**: 두 카드가 남아 있어 다음 수정 때 잘못된 쪽을 고칠 위험. 278줄의 `Text("")` 같은 빈 껍데기도 그대로다.
  - **근거**: 목록은 `CDRoutineCard`만 렌더(39줄). `RoutineCard` 참조 0건.
  - **위험도**: 하
  - **판정**: 확정

- [ ] **`Sequential Timer/SettingsView.swift:242,277`** — `OptionRow` / `InfoRow` 미사용 **[신규]**
  - **근거**: 두 struct 모두 정의 외 참조 0건.
  - **위험도**: 하
  - **판정**: 확정

- [ ] **`Sequential Timer/Theme.swift:5,10`** — `ThemeMode` / `AccentColorType` 미사용 **[신규]**
  - **왜 문제인지**: 테마가 `ThemeSelection` 5종으로 통합되기 전의 잔재. 남아 있으면 "모드 × 액센트" 축이 아직 있는 것처럼 오해된다.
  - **근거**: 두 enum 모두 참조 0건.
  - **위험도**: 하
  - **판정**: 확정

- [ ] **`Sequential Timer/DesignSystem.swift:6-98`** — `AppColor` 전체와 `Color.md*` 팔레트가 사실상 미사용 **[신규]**
  - **왜 문제인지**: 색 시스템이 두 벌(구 `AppColor`/`Color.md*` vs 현 `ThemePalette`). CLAUDE.md도 `AppColor`를 legacy로 명시. `mdWork`/`mdFitness`/`mdLearning` 카테고리 색은 카테고리 기능 자체가 없어 완전한 유령.
  - **근거**: `AppColor.` 사용처 0건. `Color.md*` 는 `AppColor` 정의부에서만 참조.
  - **위험도**: 하
  - **판정**: 확정 (단, `Color.init(hex:)` 자체는 `Theme.swift`가 사용 — 3-4 항목 참조)

- [ ] **`Sequential Timer/TimerRunningView.swift:970,997`** — `AudioManager.audioPlayer` / `stop()` **[기존]**
  - **왜 문제인지**: `audioPlayer`에 값이 대입되는 곳이 없어 항상 nil이고 `stop()`은 무조건 no-op. `stop()` 호출부도 0건. `setupAudioSession()`이 `.playback` 세션을 잡지만 실제 재생은 `AudioServicesPlaySystemSound`라 세션 설정도 의미가 옅다.
  - **근거**: `audioPlayer` 대입 0건, `AudioManager.shared.stop` 호출 0건.
  - **위험도**: 하
  - **판정**: 확정

- [ ] **`Sequential Timer/CoreData/CoreDataManager.swift:200,219,232,242 외`** — `SessionStep` CRUD 4종 + `fetchSessions` / `fetchRoutineSteps` / `updateRoutineStep` / `deleteRoutineStep` / `deleteSession` 미호출 **[기존: PROGRESS 4.1/5장]**
  - **왜 문제인지**: 단순 미사용이 아니라 3-4의 데이터 오류로 이어진다(`SessionStep`이 없어 `completedStepCount`가 항상 0).
  - **근거**: 각 심볼 호출부 0건.
  - **위험도**: 중 (데이터 정합성과 연결)
  - **판정**: 확정

- [ ] **`Sequential Timer/Sync/SyncManager.swift:13`** — `calendar` 프로퍼티 선언만 있고 미사용 **[기존]**
  - **근거**: 날짜 계산은 전부 `SyncDateUtils`가 수행. `calendar` 참조 0건.
  - **위험도**: 하
  - **판정**: 확정

- [ ] **`Sequential Timer/TimerRunningView.swift:29-30, 604-611`** — `hasSyncedOnce` / `lastSyncedStepIndex` 가 쓰기 전용 상태 **[신규]**
  - **왜 문제인지**: 5곳에서 대입하고 조건 분기도 하지만, 그 결과로 아무 동작(업로드·기록·UI)도 하지 않는다. 609줄 `if lastSyncedStepIndex != currentStepIndex && state.isPaused == false` 블록은 자기 자신에게 대입만 한다. 원래 단계별 동기화를 붙이려던 자리로 보이며, 지금은 "동기화가 되고 있다"는 착각만 준다.
  - **근거**: 두 변수의 값을 읽어 외부 효과를 내는 코드 0건.
  - **위험도**: 중
  - **판정**: 확정 (제거 vs `SessionStep` 기록으로 완성 — 결정 필요)

- [ ] **`Sequential Timer/TimerRunningView.swift:36-37, 692-693`** — `backgroundRepeatInterval`이 항상 ×0으로만 곱해짐 **[신규]**
  - **왜 문제인지**: `backgroundRepeatCount = 1` 이라 루프가 `0..<1` 한 번만 돌고 `backgroundRepeatInterval * Double(0)` = 0. 즉 "백그라운드 반복 알림"은 이름과 달리 1회 발송이고, 간격 상수는 죽은 값이다. 같은 파일 815줄은 반복 횟수/간격을 `count: 5, interval: 2.2`로 하드코딩해 상수를 무시한다.
  - **근거**: `backgroundRepeatCount` 참조 1건(루프 상한), `backgroundRepeatInterval` 참조 1건(×0).
  - **위험도**: 중
  - **판정**: 확정 (의도가 "1회"라면 상수와 루프를 없애고, "N회"라면 값이 잘못됨)

- [ ] **주석 처리된 코드 / 도달 불가 분기** — **발견 없음**
  - **근거**: `// let`, `// func`, `/* */` 안의 실행 코드 패턴 검색 0건. `#if canImport` 분기는 의도된 degrade 경로라 제외.

- [ ] **미사용 로컬라이즈 키** — **발견 없음**, ko/en 키 불일치도 **없음**
  - **근거**: 양쪽 154개 키가 완전히 동일(`comm` 차집합 0). 154개 전부 코드에서 참조됨. 다만 위 7개는 죽은 `RoutineDetailView` 전용.

## 2. 중복 / 유사 로직

- [ ] **시간 포맷 함수 6벌** — `TimerRunningView.swift:922` `formatTime` / `RoutineDetailView.swift:199` `formatDigitalDuration` / `RoutineListView.swift:232` `formatCompactDuration` / `RoutineCreateView.swift:382` `formatCompactDuration` / `RoutineCreateView.swift:574` `formatDisplayFromStorage` / `RoutineDetailView.swift:185` `formatDuration` **[신규]**
  - **왜 문제인지**: `formatTime`과 `formatDigitalDuration`은 문자 단위로 동일하다. `formatCompactDuration`은 두 파일에 같은 이름으로 있으면서 **동작이 다르다** — 리스트판은 시간(h) 단위를 처리하고, 생성 화면판은 시(h)를 아예 무시해 60분 이상이 "90분"으로 표시된다. 같은 이름이 다른 뜻을 갖는 게 가장 위험한 형태다.
  - **근거**: 6개 함수 본문 대조.
  - **위험도**: 중
  - **판정**: 확정

- [ ] **`Sequential Timer/RoutineCreateView.swift:363-397` vs `582-596`** — "MMSS" 문자열 파싱이 두 벌 **[신규]**
  - **왜 문제인지**: `totalSecondsFromStorage`(뷰)와 `parseStorage`(TimePickerButton)가 같은 규칙을 각자 구현하고, `clampSecondsValue`는 두 타입에 그대로 복붙돼 있다. 저장 포맷 규칙이 바뀌면 한쪽만 고칠 확률이 높다.
  - **근거**: 두 함수 본문이 분기 구조까지 동일.
  - **위험도**: 중
  - **판정**: 확정

- [ ] **`Sequential Timer/TimerRunningView.swift:620-664`** — 알림 콘텐츠 생성 블록이 auto/manual 두 갈래에 통째로 복사 **[신규]**
  - **왜 문제인지**: 제목·본문·식별자·사운드를 만드는 ~18줄이 거의 동일하게 두 번 나온다(`scheduleBackgroundRepeatNotificationsIfNeeded` 694-706줄까지 포함하면 세 번). 알림 문구를 바꿀 때 한 곳만 고치면 모드에 따라 다른 문구가 나간다.
  - **근거**: 621-641 / 643-663 블록 대조, 차이는 순회 범위뿐.
  - **위험도**: 중
  - **판정**: 확정

- [ ] **`Sequential Timer/RoutineListView.swift:222` / `RoutineDetailView.swift:179`** — 루틴 삭제가 `CoreDataManager`를 우회 **[신규]**
  - **왜 문제인지**: `CoreDataManager.deleteRoutine`이 있는데도 두 뷰가 `managedObjectContext.delete` 를 직접 호출한다. 저장 경로가 갈려서 삭제 시 후처리(동기화 큐 정리 등)를 한 곳에 붙일 수 없다.
  - **근거**: `CoreDataManager.deleteRoutine` 호출 0건, 뷰 직접 삭제 2건.
  - **위험도**: 중
  - **판정**: 확정

- [ ] **`Sequential Timer/DesignSystem.swift:10-31` vs `33-53`** — 다크 색 매핑이 두 벌 **[신규]**
  - **왜 문제인지**: `Color(hex:)` 안의 매핑 테이블은 `3D7AF5 → 6B93D6`, 바로 아래 `semantic()`으로 만든 `mdPrimary`는 같은 라이트 색에 대해 `5E89D6`. 같은 브랜드 색의 다크 대응이 두 값으로 갈려 있다.
  - **근거**: 11줄과 42줄의 다크 값 비교.
  - **위험도**: 중
  - **판정**: 확정 (실사용 영향은 3-4 참조)

## 3. 논리적 모순

### 3-1. 상태값 체크 불일치

- [ ] **`Sequential Timer/CoreData/CoreDataManager.swift:144` / `TimerRunningView.swift:404,424,432,451`** — 세션 상태를 문자열 리터럴로 기록, 소비는 enum **[신규]**
  - **왜 문제인지**: 쓰는 쪽은 `"RUNNING"` / `"PAUSED"` / `"COMPLETED"` / `"ABANDONED"` 리터럴, 읽는 쪽(`SyncBuilders.swift:94,126`)은 `SessionStatus.completed.rawValue`. `SessionStatus` enum이 있는데도 쓰기 경로가 전혀 쓰지 않아, 오타 한 글자로 업로드가 조용히 스킵된다(빌더가 `nil` 반환 → 큐에서 삭제).
  - **근거**: `SessionStatus.` 참조가 SyncBuilders 2곳뿐, 상태 문자열 대입은 전부 리터럴.
  - **위험도**: 중
  - **판정**: 확정

- [ ] **`Sequential Timer/NotificationModeSheet.swift:248` vs 나머지 전체** — locale 소스가 두 가지 **[신규]**
  - **왜 문제인지**: 이 파일만 `Locale.current`를 보고, 다른 모든 뷰는 `@Environment(\.locale)`을 쓴다. 환경 locale을 주입/재정의하면 이 한 줄만 다른 언어 기준으로 분기한다.
  - **근거**: `Locale.current` 사용 1건, `@Environment(\.locale)` 사용 6파일.
  - **위험도**: 하
  - **판정**: 확정

### 3-2. 타이머 상태 전이

- [ ] **`Sequential Timer/TimerRunningView.swift:575-580` + `448-465`** — auto 모드 완료 후 `finishSession()`이 매초 재실행됨 **[신규]** ⚠️
  - **왜 문제인지**: `finishSession()`은 `SessionStore.clear()`만 하고 `sessionState`(@State)는 non-nil, `isPaused == false` 그대로 둔다. 완료 알럿이 떠 있는 동안 1초 타이머는 계속 돌고, `onReceive` 가드(281줄 `isPaused == false`)를 통과해 `syncDisplay` → `elapsed >= 마지막 endOffset` → `finishSession()` 을 **매초 다시 호출**한다. 그때마다 `updateSession(endedAt: Date())`가 실행돼 **Core Data의 종료 시각이 알럿을 띄워둔 시간만큼 계속 뒤로 밀린다.** 그 값이 그대로 `actualDurationSeconds`로 Firestore에 올라간다(업로드 큐는 중복 제거되지만, 큐에서 읽는 시점의 `endedAt`이 이미 오염).
  - **근거**: `finishSession`이 `sessionState = nil`을 하지 않음(`stopSession`은 440줄에서 함 — 비대칭). `updateSession`은 매 호출 `endedAt`/`updatedAt` 갱신 후 `saveContext()`.
  - **위험도**: 상
  - **판정**: 확정 (증상 크기는 사용자가 알럿을 얼마나 늦게 닫느냐에 비례)

- [ ] **`Sequential Timer/TimerRunningView.swift:410-427`** — manual 모드 `waitingForNext`에서 재생 버튼이 아무 일도 하지 않음 **[신규]**
  - **왜 문제인지**: 단계가 끝나면 `syncDisplay`가 `isPaused = true` + `stepRunState = .waitingForNext`로 만든다. 이 상태에서 하단 버튼은 "재개"로 보이지만, `resumeSession()`은 `stepRunState`만 `.running`으로 되돌릴 뿐 **단계 인덱스를 진행시키지 않는다.** 곧바로 `elapsed >= endOffset`이 다시 참이 되어 같은 대기 상태로 되돌아간다. 다음 단계로 가는 유일한 경로는 알럿의 "지금 시작"뿐인데, 알럿은 단계당 1회만 뜬다(`hasShownManualAlertForStep`).
  - **근거**: `resumeSession`에 `currentStepIndex` 변경 없음. `startNextStepFromManualAlert`(848줄)에만 인덱스 증가 로직이 있음.
  - **위험도**: 중
  - **판정**: 확정 (알럿을 놓친 사용자가 갇히는지는 실기기 확인 필요)

- [ ] **`Sequential Timer/TimerRunningView.swift:881-903`** — "나중에" 버튼이 단계를 건너뛴 것과 같은 상태를 만든다 **[신규]**
  - **왜 문제인지**: `handleManualAlertLater()`는 **다음 단계로 인덱스를 올리고**(891줄) `startAt`을 되감은 뒤 즉시 `isPaused = true` / `waitingForNext`로 만든다. 사용자가 기대하는 "지금은 넘기고 현재 상태 유지"가 아니라, 현재 단계는 끝난 것으로 처리되고 다음 단계는 시작 전 대기 상태가 된다. 다음 단계의 대기 알럿이 다시 뜰 조건도 만들어진다(`hasShownManualAlertForStep`은 이전 인덱스 값이라 새 인덱스에서 재발화).
  - **근거**: 891-896줄. 비교 대상인 `startNextStepFromManualAlert`(860-865줄)와 인덱스 처리가 동일하고 `isPaused`만 다름.
  - **위험도**: 중
  - **판정**: 확인 필요 — "나중에"의 의도된 정의가 SPEC.md에 명시돼 있는지, 그리고 실제로 다음 단계 알럿이 곧바로 다시 뜨는지 실행 확인 필요

- [ ] **`Sequential Timer/TimerRunningView.swift:429-465`** — `stopSession` / `finishSession` 이 반복 사운드 타이머를 취소하지 않음 **[신규]**
  - **왜 문제인지**: `maybeShowManualAlert`가 `playNotificationRepeating(count: 5, interval: 2.2)`로 최대 5개의 `DispatchWorkItem`을 예약한다. 종료·완료 경로 어디에도 `cancelManualAlertNotifications()`가 없어서, 정지 버튼을 눌러 화면을 닫은 뒤에도 최대 ~9초간 알림음이 계속 난다. (`startNextStepFromManualAlert` 869줄과 `handleManualAlertLater` 900줄에는 취소가 있어 **경로별로 비대칭**.)
  - **근거**: `cancelManualAlertNotifications()` 호출 3건 — 907, 869, 900줄. `stopSession`/`finishSession`엔 없음.
  - **위험도**: 중
  - **판정**: 확정

- [ ] **`Sequential Timer/TimerRunningView.swift:727-732`** — `cancelPendingNotifications`가 백그라운드 반복 알림 식별자를 커버하지 않음 **[신규]**
  - **왜 문제인지**: 취소 대상은 `...step.N` 과 `...complete` 뿐이고, `backgroundRepeatIdentifier`가 만드는 `...step.N.repeat.K` 는 포함되지 않는다. 지금은 `scenePhase == .active`에서 `SessionStore.clearScheduledNotifications()`가 UserDefaults에 저장된 id로 지워주지만, 그 정리보다 `SessionStore.clear()`가 먼저 일어나는 경로(완료 직후 복귀)에서는 저장된 id가 사라져 **취소할 방법이 없어진다.**
  - **근거**: 729-730줄 식별자 구성 vs 723줄 반복 식별자 포맷. `.active` 핸들러(300-307줄)의 실행 순서.
  - **위험도**: 중
  - **판정**: 확인 필요 — 실제로 유령 알림이 뜨는지 재현 필요(포그라운드 복귀 타이밍 의존)

- [ ] **`Sequential Timer/TimerRunningView.swift:352-362`** — 세션 복구 분기가 도달 불가 **[기존: PROGRESS 4.5]**
  - **근거**: 진입점 2곳 모두 `forceNewSession: true`(RoutineListView.swift:211, 315).
  - **위험도**: 중
  - **판정**: 확정

- [ ] **`Sequential Timer/TimerRunningView.swift:410-427`** — 완료된 세션이 되살아날 수 있는 경로 **[신규]**
  - **왜 문제인지**: `finishSession` 후에도 `sessionState`가 남아 있어, 이론상 `resumeSession()`이 이미 `COMPLETED` + `endedAt`이 찍힌 세션을 `"RUNNING"`으로 되돌리고 `SessionStore`에 다시 저장한다.
  - **근거**: `finishSession`에 `sessionState = nil` 없음. `resumeSession` 가드는 `isPaused`만 확인.
  - **위험도**: 하
  - **판정**: 확인 필요 — 완료 알럿이 모달이라 실제로 버튼을 누를 수 있는지 확인 필요(불가능하면 3-2 첫 항목 수정 시 함께 해소)

### 3-3. StoreKit / IAP

- **해당 없음 — 미구현.** 저장소 어디에도 `StoreKit` / `GoogleMobileAds` import나 구매·검증 코드가 없다(`import StoreKit` 0건, pbxproj에 관련 패키지 0건). `Sequential Timer/SequentialTimer_Ads_IAP_TASK.md`는 아직 지시서 단계이며, 문서 스스로 "파악 → 보고 → 승인" 뒤에 착수하라고 못박고 있다.
- 구현이 들어오면 이 섹션에서 점검할 것: `.pending` / `.unverified` 처리, 복원, `Transaction.finish()` 누락, 환불·만료 반영, 오프라인 엔타이틀먼트 판정.

### 3-4. 동기화(Sync) / 데이터 정합성

- [ ] **`Sequential Timer/Sync/SyncManager.swift:24-27`** — 오프라인이면 그날 동기화가 통째로 소진 **[기존: PROGRESS 4.2]**
  - **왜 문제인지**: 네트워크 도달성·인증 확인 **전에** `recordSyncAttempt`로 오늘 날짜를 기록한다. 활성화 시점에 오프라인이면 이후 온라인이 돼도 다음 KST 날짜까지 재시도가 없다.
  - **근거**: 25-27줄 순서. `isNetworkReachable` 가드가 기록 뒤에 있음.
  - **위험도**: 상
  - **판정**: 확정

- [ ] **`Sequential Timer/Sync/SyncBuilders.swift:125-134`** — 중도 포기 세션의 `completedStepCount`가 항상 0 **[기존: PROGRESS 4.1]**
  - **근거**: `createSessionStep` 호출 0건 → `session.steps` 항상 빈 집합.
  - **위험도**: 중
  - **판정**: 확정

- [ ] **`Sequential Timer/DesignSystem.swift:148-154` + `TimerRunningView.swift:734-744, 986-995`** — 번들에 없는 사운드 리소스 참조 + 재생 경로 이원화 **[기존: PROGRESS 4.4]**
  - **근거**: 저장소 내 `.caf/.wav/.aiff/.mp3/.m4a` 파일 0건. 알림은 `UNNotificationSound(named:)`, 앱 내 재생은 `SystemSoundID` 하드코딩.
  - **위험도**: 중
  - **판정**: 확정

- [ ] **`Sequential Timer/NotificationModeSheet.swift:154-159` vs `TimerRunningView.swift:327-343`** — "이전 설정" 프리셋이 `lastUsedSound` / `lastUsedVibration` 을 읽지 않음 **[신규]** ⚠️
  - **왜 문제인지**: `startRoutine()`(165-166줄)이 `lastUsedSound` / `lastUsedVibration` 에 값을 저장하는데, 다시 읽는 곳은 `loadLastUsedSettings()`가 아니라 **`defaultNotificationSound` / `defaultNotificationVibration`(설정 화면 기본값)** 이다. 그래서 "기본"과 "이전 설정" 버튼은 사운드/진동 **종류**에 대해 완전히 같은 값을 넣고, on/off 플래그만 다르다. 한편 `TimerRunningView.loadLastNotificationConfiguration()`은 정반대로 `lastUsed*` 키를 신뢰한다 — 같은 두 키를 두 화면이 서로 다르게 취급한다.
  - **근거**: 157-158줄이 `defaultSoundRaw` / `defaultVibrationRaw` 참조. `lastSoundRaw` / `lastVibrationRaw` 는 이 파일에서 **쓰기 전용**(165-166줄 대입뿐).
  - **위험도**: 중 (4.4와 겹쳐 "알림음 선택" 기능 전체가 사실상 무력)
  - **판정**: 확정

- [ ] **`Sequential Timer/RoutineListView.swift:194-200`** — `.swipeActions` 가 `List` 밖에서 사용됨 **[신규]**
  - **왜 문제인지**: 카드가 `ScrollView` + `VStack` 안에 있어 `swipeActions` 수식자는 효과가 없다. 같은 삭제 동작을 `contextMenu`(187줄)가 이미 제공하므로, 동작하지 않는 UI 코드가 남아 "스와이프 삭제가 있다"고 오해하게 한다.
  - **근거**: 38-41줄 `ForEach`가 `VStack` 안. `List` 사용 0건.
  - **위험도**: 하
  - **판정**: 확인 필요 — iOS 26에서 `List` 밖 `swipeActions`가 여전히 무시되는지 실기기/시뮬레이터 확인

- [ ] **`Sequential Timer/Theme.swift:44-82` + `DesignSystem.swift:10-31`** — 팔레트 색이 `Color(hex:)`의 자동 다크 치환을 거친다 **[신규]**
  - **왜 문제인지**: `ThemePalette.lightBlue.accent = Color(hex: "3D7AF5")` 인데 이 이니셜라이저는 매핑 테이블에 걸려 **다크 트레잇에서 몰래 `6B93D6`으로 바뀐다.** 지금은 `preferredColorScheme`가 라이트 테마를 라이트로 고정해 표면화되지 않지만, "명시적으로 고른 팔레트 값이 그대로 그려진다"는 가정이 코드상 성립하지 않는다.
  - **근거**: `ThemePalette` 정의 전부가 `Color(hex:)` 사용, 매핑 테이블에 `3D7AF5` 포함.
  - **위험도**: 중
  - **판정**: 확인 필요 — 시스템 다크 + 라이트 테마 선택 조합에서 실제 렌더 색 확인 필요

- [ ] **`Sequential Timer/Sync/UploadQueueStore.swift:45-53, 75-82`** — 세션 큐 항목의 재시도·갱신 정책 공백 **[신규]**
  - **왜 문제인지**: (a) `enqueueSession`은 같은 `sessionId`가 큐에 있으면 무조건 무시하므로, 큐에 남아 있는 동안 세션 내용이 바뀌어도(위 3-2의 `endedAt` 오염 등) 갱신되지 않는다. (b) `attemptCount`는 증가만 하고 상한이 없어 실패 항목이 영구히 재시도된다.
  - **근거**: 51-53줄 조기 반환, `attemptCount` 비교/삭제 로직 0건.
  - **위험도**: 하
  - **판정**: 확정 (정책 결정 필요)

- [ ] **`Sequential Timer/TimerRunningView.swift:318-324`** — 루틴 속성을 바꾸면서 동기화 큐에 넣지 않음 **[신규]**
  - **왜 문제인지**: 화면 켜짐 토글이 `routine.keepScreenOn` / `updatedAt` 을 직접 수정·저장하지만 `SyncManager.enqueueRoutine`을 호출하지 않는다(생성/편집 경로인 `RoutineCreateView.swift:347-350`은 호출). Firestore의 `keepScreenOn`이 로컬과 어긋난다.
  - **근거**: 321-323줄 vs RoutineCreateView 347-350줄.
  - **위험도**: 하
  - **판정**: 확정

## 4. 방치된 TODO / FIXME

- **코드 내 TODO / FIXME / HACK / XXX / "임시" / "나중에" — 0건.** (`--include='*.swift'` 전수 검색)
- [ ] **`Sequential Timer/NotificationModeSheet.swift:131-132`** — 결정 근거가 주석으로만 남은 설계 메모
  - **내용**: `// Load last used by default? Users request: "Basic or Previous can be selected"` / `// Let's load Last Used by default for convenience`
  - **왜 문제인지**: 정작 그 아래 `loadLastUsedSettings()`가 "last used"를 읽지 않는다(3-4 항목). 주석이 현재 동작과 어긋나 **틀린 문서**로 기능한다.
  - **위험도**: 하 → **분류: 여전히 유효(코드가 주석을 배신 중)**
  - **판정**: 확정

- [ ] **`SettingsView.swift:187` — 앱 버전 하드코딩 `"1.0.0"`** vs `MARKETING_VERSION = 1.0` **[기존: PROGRESS 4.7]**
  - **분류**: 여전히 유효. `Bundle.main`의 `CFBundleShortVersionString`을 읽어야 함.
  - **위험도**: 하 / **판정**: 확정

- 문서-코드 대조: `PROGRESS.md` 4.1·4.2·4.4·4.5·4.7·4.8과 5장 데드 코드 표는 **오늘 코드 기준으로 전부 여전히 유효**했다(항목별로 위에 [기존] 표기). 반대로 이번 리포트의 [신규] 항목들은 `PROGRESS.md` 4장/5장에 없으므로 반영이 필요하다.

## 5. 미사용 의존성

이 프로젝트에는 `Package.swift`도 `Podfile`도 없다. 의존성은 Xcode SPM 참조로만 관리된다.

| 프로덕트 | 링크 위치 | 코드 사용 | 판정 |
|---|---|---|---|
| FirebaseAuth | pbxproj:369 | `FirebaseBackend.swift:4,30,34,94` | 사용 중 |
| FirebaseFirestore | pbxproj:374 | `FirebaseBackend.swift:8,56,77` | 사용 중 |
| FirebaseAnalytics | pbxproj:379 | **import 0건, 심볼 사용 0건** | 확인 필요 |

- [ ] **`Sequential Timer.xcodeproj/project.pbxproj:379`** — `FirebaseAnalytics` 링크되었으나 코드 참조 0건
  - **왜 문제인지**: 명시적 호출이 전혀 없다. 다만 Analytics는 `FirebaseApp.configure()`(SequentialTimerApp.swift:39)만으로 자동 수집이 동작하고, 개인정보 시트(`settings.privacy.section2.item1` "타이머 및 루틴 사용 패턴 분석")가 수집을 고지하고 있어 **의도된 링크일 가능성이 높다.**
  - **근거**: `import FirebaseAnalytics` 0건, `Analytics.` 0건. Package.resolved: firebase-ios-sdk 12.8.0 (leveldb 1.22.5, nanopb 2.30910.0 — 전이 의존성).
  - **위험도**: 하
  - **판정**: 확인 필요 — 자동 수집을 실제로 쓰는지(Firebase 콘솔에 이벤트가 들어오는지) 확인. 안 쓴다면 링크 제거 + 개인정보 문구 정정, 쓴다면 그대로 유지

- `GoogleService-Info.plist`: 앱 폴더에 존재하고 `FirebaseApp.configure()`가 `AppDelegate`에서 실행됨 — 정합.
- 프레임워크 import 중 미사용 후보: 없음(모두 실제 심볼 사용 확인). `TimerRunningView.swift:5 import Combine`은 `Timer.publish`에 필요.

## 우선순위 Top 5

| # | 항목 | 파일:라인 | 위험도 | 왜 먼저인가 | 예상 작업량 |
|---|------|-----------|--------|-------------|-------------|
| 1 | auto 모드 완료 후 `finishSession()` 매초 재실행 → `endedAt`이 계속 밀림 | TimerRunningView.swift:448-465, 575-580 | 상 | 업로드되는 세션 통계가 실제와 달라진다. 이미 나간 데이터는 되돌릴 수 없고, 고치는 건 `sessionState = nil` 한 줄 수준 | 소 (1줄 + 회귀 확인) |
| 2 | 오프라인이면 그날 동기화가 통째로 소진 | Sync/SyncManager.swift:24-27 | 상 | 백업이 조용히 며칠씩 밀릴 수 있다. 기록 시점만 뒤로 옮기면 되고 위험이 거의 없다 | 소 |
| 3 | "이전 설정" 프리셋이 `lastUsed*`를 읽지 않음 (+ 번들 사운드 부재) | NotificationModeSheet.swift:154-159 / DesignSystem.swift:148 | 중 | 사용자가 고른 알림음이 반영되지 않는 명백한 오동작. 4.4와 묶어 "알림음 선택을 살릴지 없앨지"를 한 번에 결정해야 한다 | 중 (제품 결정 포함) |
| 4 | 정지·완료 시 반복 알림음 `DispatchWorkItem` 미취소 | TimerRunningView.swift:429-465 | 중 | 화면을 닫은 뒤에도 소리가 계속 나는, 체감이 큰 버그. 다른 두 경로엔 이미 취소가 있어 대칭만 맞추면 된다 | 소 |
| 5 | `SequentialTimerEngine.resolveProgress` 미사용 + 뷰에서 동일 로직 재구현 | SequentialTimerEngine.swift:37 / TimerRunningView.swift:567-574 | 중 | 타이머 계산의 단일 출처 원칙이 깨진 상태. 테스트 타겟을 붙이기 전에 정리해야 테스트가 실제 코드 경로를 검증한다 | 중 |

## 확인 필요 목록

| 항목 | 무엇을 확인하면 결론이 나는가 |
|---|---|
| "나중에" 버튼의 의도 (3-2) | SPEC.md의 manual 모드 대기 알럿 정의. 그리고 실기기에서 "나중에" 후 다음 단계 알럿이 즉시 뜨는지 |
| manual `waitingForNext`에서 재생 버튼 (3-2) | 알럿을 닫은 뒤 재생 버튼만으로 다음 단계로 갈 수 있는지 실행 확인 |
| 반복 알림 식별자 미취소 (3-2) | 백그라운드에서 루틴 완료 → 복귀 순서로 유령 알림이 남는지 재현 |
| 완료 세션 되살아남 (3-2) | 완료 알럿이 모달이라 재생 버튼 탭이 실제로 불가능한지 |
| `Color(hex:)` 다크 치환 (3-4) | 시스템 다크 + "라이트 블루" 테마에서 액센트가 `3D7AF5`인지 `6B93D6`인지 |
| `.swipeActions` 무효 (3-4) | iOS 26 시뮬레이터에서 카드 스와이프 삭제가 실제로 되는지 |
| FirebaseAnalytics (5) | Firebase 콘솔에 이벤트가 실제로 수집되는지 |

## 이번에 점검하지 못한 영역

- **런타임 동작 검증 없음.** 규칙대로 빌드·실행을 하지 않았으므로 위 모든 항목은 정적 읽기 기준이다. "확인 필요" 표시가 붙은 7건은 실행해 봐야 결론이 난다.
- **Core Data 엔티티 클래스**(`Routine`/`RoutineStep`/`Session`/`SessionStep`/`UploadQueueItem`)는 Xcode 생성이라 소스가 없어 속성 단위 미사용 여부는 판단하지 않았다. `.xcdatamodel` 상의 미사용 속성(예: `isArchived` — 켜는 UI 없음)은 PROGRESS 3.2에 이미 기록돼 있다.
- **`Assets.xcassets`** 는 `AppIcon` / `AccentColor` 뿐이라 미참조 애셋 점검이 사실상 불필요했다.
- **Firestore 보안 규칙**은 저장소에 없어 점검 불가(PROGRESS 3.2와 동일 결론).
- **`SPEC.md` 전문 대조**는 하지 않았다. 이번 [신규] 항목들이 SPEC과 어긋나는지는 별도 확인이 필요하다.
