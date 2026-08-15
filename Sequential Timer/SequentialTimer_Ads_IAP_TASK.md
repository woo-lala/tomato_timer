# Sequential Timer — 완료 전면광고 & 광고제거 IAP 구현 작업 지시서

> 대상: Claude Code
> 목적: 기존 Swift iOS 앱(Sequential Timer)에, 루틴 완료 시점의 **전면광고 1회**와 **비소모성 IAP(광고 제거)** 를, 기존 기능을 훼손하지 않고 클린하게 추가한다.

---

## 0. 이 문서를 다루는 규칙 (반드시 먼저 읽기)

- 이 문서는 **작업 지시서**다. 코드를 바로 짜지 말고, **1단계(프로젝트 파악)를 먼저 수행 → 결과를 사람에게 보고 → 승인 후 구현**한다.
- **한 번에 한 작업(one task at a time).** 6장의 단계를 순서대로 하나씩 진행하고, 각 단계 끝에서 **빌드가 통과하는지 확인**한 뒤 짧게 보고한다.
- `<<...>>` 로 표시된 값은 **사람이 채워야 하는 값**이다. 임의로 지어내지 말고, 비어 있으면 질문한다.
- 확실하지 않은 프로젝트 구조/이벤트 위치는 추측하지 말고 **먼저 코드에서 확인**한다.
- **GoogleMobileAds SDK와 StoreKit 2의 API 시그니처는 버전에 따라 바뀌었다.** 이 문서의 Swift 조각은 *설계 의도를 보여주는 스케치*일 뿐이다. 실제 SDK 호출은 **현재 설치된 버전의 공식 문서 기준**으로 확인해서 사용한다.

---

## 1. 목표 (한 문장)

루틴이 끝나는 순간 전면광고를 최대 1회 보여주고, 사용자가 원하면 한 번 결제로 광고를 영구 제거할 수 있게 한다. **타이머의 기존 동작·저장·화면 전환은 절대 바뀌면 안 된다.**

---

## 2. 먼저 파악할 것 (탐색 단계 — 코드 작성 전)

아래를 조사하고 **요약해서 보고**한다. 이 보고가 승인되기 전에는 구현을 시작하지 않는다.

1. **UI 프레임워크**: SwiftUI / UIKit / 혼합 중 무엇인가. (전면광고 present 방식이 갈린다 — 5.3 참고)
2. **최소 배포 타겟(iOS Deployment Target)**: StoreKit 2는 iOS 15+ 필요. 15 미만이면 사람에게 알리고 상의.
3. **의존성 관리**: Swift Package Manager / CocoaPods / 수동. (SPM 우선 사용)
4. **앱 진입점 & 루트 계층**: `@main` App, SceneDelegate/AppDelegate 유무, 루트 뷰/뷰컨트롤러.
5. **"루틴 완료" 이벤트가 발생하는 정확한 위치**: 어떤 타입/함수에서 타이머 시퀀스가 끝나는가. **전면광고는 여기에 건다.** 파일/함수명을 특정해서 보고.
6. **기존 상태 저장 방식**: UserDefaults / SwiftData / CoreData 등. (entitlement 캐시에 재사용)
7. **기존 아키텍처 패턴 & 네이밍 컨벤션**: MVVM 등. **새 코드는 기존 패턴을 따른다.**

> 보고 형식 예: "SwiftUI + @main App, iOS 16 타겟, SPM 사용. 완료 이벤트는 `RoutinePlayerViewModel.finishSequence()` 에서 발생. 저장은 UserDefaults. MVVM 사용."

---

## 3. 기능 요구사항

### 3.1 완료 전면광고 (AdMob Interstitial)

- 루틴 완료 시점에 전면광고를 present 한다.
- **미리 로드(preload)** 해 둔다. 완료 순간엔 준비된 광고를 present 만 한다.
- **광고가 아직 로드되지 않았으면, 광고 없이 즉시 다음 흐름을 진행한다.** (로딩 대기로 화면을 막지 않는다.)
- 광고를 닫은 뒤 **즉시 다음 광고를 reload** 한다.
- **빈도 제한**: `<<세션당 1회 | N회 완료마다 1회>>` — 값을 상수로 파라미터화한다. (짧은 루틴이 하루에 여러 번 완료되므로 매번 노출 금지)
- **프리미엄 사용자에게는 로드도 표시도 하지 않는다.**

### 3.2 광고제거 IAP (StoreKit 2)

- 상품 유형: **비소모성(Non-Consumable)**. 한 번 사면 영구.
- 상품 ID: `<<com.example.sequentialtimer.removeads>>`
- **구매(purchase)** 와 **구매 복원(restore)** 을 모두 지원한다. (복원 버튼은 애플 심사 필수)
- **소유 여부 판단의 원천(source of truth)은 `Transaction.currentEntitlements`** 이다. UserDefaults 불리언은 오프라인/즉시반영용 **캐시로만** 쓴다.
- 구매/복원 성공 즉시: 광고 비활성화 + "광고 제거" 관련 UI 숨김.
- `Transaction.updates` 를 구독해 앱 실행 중 발생하는 트랜잭션(다른 기기 구매 등)도 반영한다.

---

## 4. 개인정보 / 동의 (iOS 필수)

- **ATT (App Tracking Transparency)**: 광고 식별자(IDFA) 사용 동의를 `ATTrackingManager` 로 요청한다. 거부 시 비개인화 광고로 자동 폴백(광고 자체는 계속 나감). **프리미엄 사용자에게는 요청하지 않는다.**
- **Google UMP SDK (권장)**: GDPR 등 동의 폼. ATT/UMP 처리가 끝난 뒤 AdMob을 초기화한다.
- **Info.plist 필수 키** (값은 사람이 채움):
  - `GADApplicationIdentifier` = `<<AdMob 앱 ID>>`
  - `SKAdNetworkItems` = `<<AdMob이 제공하는 식별자 배열>>`
  - `NSUserTrackingUsageDescription` = `<<추적 사용 설명 문구>>`

---

## 5. 클린코드 / 아키텍처 원칙

### 5.1 의존성 역전 (가장 중요)

- **도메인(타이머) 레이어는 `GoogleMobileAds` / `StoreKit` 를 직접 import 하지 않는다.** 오직 프로토콜을 통해서만 광고/결제와 대화한다.
- 완료 이벤트 지점에서는 **얇은 인터페이스 호출**만 한다. SDK 세부사항이 도메인으로 새어 들어오면 안 된다.

### 5.2 제안 파일 구조 (기존 컨벤션에 맞게 조정)

```
Monetization/
  MonetizationConfig.swift        // 광고 단위 ID(테스트/실제), 상품 ID, 빈도값 상수
  Entitlements/
    EntitlementProviding.swift    // protocol
    StoreKitEntitlementStore.swift// StoreKit 2 구현
  Ads/
    AdServing.swift               // protocol
    InterstitialAdManager.swift   // AdMob 구현
    ConsentCoordinator.swift      // ATT + UMP
  MonetizationCoordinator.swift   // 완료 이벤트 ↔ 광고/entitlement 연결 (얇게)
```

### 5.3 프로토콜 스케치 (설계 의도 — 실제 SDK 호출은 현재 버전 문서로 확인)

```swift
// 도메인이 참조하는 얇은 추상화. SDK 타입 노출 금지.
protocol EntitlementProviding: AnyObject {
    var isPremium: Bool { get }              // 광고 제거 소유 여부 (원천: currentEntitlements)
    func refresh() async                     // currentEntitlements 재확인
    func removeAdsProduct() async -> AdRemovalProduct?  // 표시용 가격 등
    func purchaseRemoveAds() async throws -> Bool
    func restore() async throws -> Bool
    func observeTransactionUpdates()         // Transaction.updates 구독
}

protocol AdServing: AnyObject {
    func start()                             // 동의 완료 후 SDK 초기화 + 첫 로드 (프리미엄이면 no-op)
    func preload()                           // 다음 전면광고 미리 로드 (프리미엄이면 no-op)
    var isInterstitialReady: Bool { get }
    // present 후 completion 으로 "다음 흐름 진행"을 호출자에게 돌려줌.
    // 미준비/프리미엄이면 즉시 completion() 을 호출(=광고 없이 통과).
    func showInterstitialIfReady(from presenter: AdPresenter, completion: @escaping () -> Void)
}
```

### 5.4 기타

- **하드코딩 금지**: 광고 단위 ID / 상품 ID / 빈도값은 `MonetizationConfig` 한 곳에서만 관리.
- **프리미엄 여부는 단일 소스**(`EntitlementProviding.isPremium`)로 전역 참조. 여러 곳에 중복 저장 금지.
- **테스트 가능성**: 프로토콜 mock 으로 "완료 → (빈도 캡) → 광고 호출 / 프리미엄이면 스킵" 로직을 유닛테스트할 수 있어야 한다.

---

## 6. 단계별 작업 (순서대로, 하나씩 / 각 단계 후 빌드 확인 & 보고)

1. **의존성 추가** — GoogleMobileAds SDK (+ 필요 시 UMP). SPM 우선. 빌드 확인.
2. **Info.plist 키 추가** — 4장의 세 키. 값은 `<<...>>` 자리표시자로 두고, 실제 값은 사람이 채운다고 명시.
3. **`MonetizationConfig` 상수 파일** — 개발용은 **Google 공식 테스트 광고 단위 ID**, 실제 ID는 릴리스 빌드에서만. 상품 ID, 빈도값 정의.
4. **Entitlement (StoreKit 2)** — `EntitlementProviding` + `StoreKitEntitlementStore`: 상품 로드, purchase, restore, `currentEntitlements` 확인, `Transaction.updates` 구독, `isPremium` 게시. UserDefaults 캐시.
5. **광고 (AdMob)** — `AdServing` + `InterstitialAdManager`: 동의 후 init, preload, `showInterstitialIfReady(from:completion:)`, 표시 후 reload. **프리미엄이면 전부 no-op.**
6. **동의 플로우** — `ConsentCoordinator`로 ATT(+UMP) 처리 후 AdMob 초기화 연결. 앱 시작의 적절한 시점에 배치.
7. **완료 이벤트 연결** — 2장에서 특정한 완료 지점에서 `MonetizationCoordinator` 경유로 광고 호출. **빈도 캡 적용, 미준비 시 스킵**, completion 으로 기존 다음 흐름 이어가기.
8. **설정 화면 UI** — "광고 제거" 구매 버튼 + "구매 복원" 버튼 + 가격 표시(상품 정보에서). 구매/복원 시 즉시 반영.
9. **프리미엄 분기 마감** — 프리미엄이면 광고 SDK/ATT 진입 자체를 스킵, 광고 호출은 no-op, 관련 UI 숨김.
10. **정리/검토** — 전체 빌드, 경고 제거, **도메인 레이어에 `GoogleMobileAds`/`StoreKit` import 가 없는지 확인**, 기존 기능 회귀 점검.

---

## 7. 반드시 지킬 것 / 하지 말 것 (CRITICAL)

- **개발·디버그 빌드에서는 반드시 Google 공식 테스트 광고 단위 ID를 사용**한다. 실제 광고를 직접 클릭/노출 테스트하지 않는다 → **부정 트래픽으로 AdMob 계정이 정지**될 수 있다. 실제 ID는 릴리스 빌드에서만 사용하도록 빌드 컨피그로 분기한다.
  - (참고) iOS 전면광고 테스트 단위 ID: `ca-app-pub-3940256099942544/4411468910` — **사용 전 Google 공식 테스트 광고 ID 페이지에서 현재 값 확인.**
- **광고 로딩으로 사용자 흐름을 막지 않는다.** 완료 화면을 로딩 스피너로 지연시키지 말 것.
- **프리미엄 사용자에게 광고·ATT 팝업을 절대 노출하지 않는다.**
- **entitlement 판단을 UserDefaults 불리언만으로 하지 않는다.** 원천은 `Transaction.currentEntitlements`.
- **도메인 로직에 SDK 세부사항 누출 금지** (프로토콜 경유).
- **기존 기능 회귀 금지**: 완료 흐름·저장·네비게이션이 그대로 동작해야 한다.

---

## 8. 사람이 해야 하는 사전 준비 (Claude Code가 못 하는 것)

- **AdMob**: 계정/앱 등록 → 전면 광고 단위 생성 → 실제 ad unit ID 발급 → `<<...>>` 채우기. `SKAdNetworkItems` 목록 확보.
- **App Store Connect**: 비소모성 IAP 상품 생성(상품 ID·가격·메타데이터), 계약·세금·정산(은행) 정보 입력. 없으면 IAP 심사/지급 불가.
- **Info.plist**: `GADApplicationIdentifier`(실제 앱 ID) 입력.
- **(한국) 사업자등록·세금정보**: IAP 판매 전 필요. (직장 겸업 규정 확인 포함)

---

## 9. 완료 기준 (Acceptance Criteria)

- [ ] 테스트 광고가 완료 시점에 노출되고, 닫으면 기존 다음 흐름이 정상 진행된다.
- [ ] 광고가 로드되지 않은 상황에서도 완료 흐름이 지연/중단 없이 진행된다.
- [ ] 빈도 캡 설정대로 노출이 제한된다(매 완료마다 뜨지 않는다).
- [ ] "광고 제거" 구매 → 즉시 광고가 사라진다.
- [ ] 앱 재시작 및 재설치+복원 후에도 프리미엄 상태가 유지된다.
- [ ] 프리미엄 상태에서 ATT/광고 코드 경로에 진입하지 않는다.
- [ ] 도메인(타이머) 레이어에 `GoogleMobileAds`/`StoreKit` import 가 0건이다.
- [ ] 기존 타이머 기능에 회귀가 없다.

---

## 부록 — 시작 프롬프트 예시 (사람이 Claude Code에게 붙일 문장)

> 이 저장소에 이 작업 지시서(`SequentialTimer_Ads_IAP_TASK.md`)에 따라 광고/IAP를 붙이려고 해.
> 먼저 **2장(먼저 파악할 것)만 수행**해서 결과를 요약해 줘. 코드는 아직 짜지 말고, 파악 결과와 완료 이벤트 위치를 알려주면 내가 승인할게.
