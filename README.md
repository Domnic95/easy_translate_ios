# Easy Translate

A Flutter translator app — text, voice, face-to-face conversation, and camera/gallery OCR translation across **100+ languages**, with translation history (single + multi-select delete with undo), favorites, profanity filtering, schema-versioned settings, Material 3 light/dark/system theming, and a full Google AdMob layer (AppOpen, Banner, Native, Interstitial) gated by remote config.

## Features

- **Text translation** with auto language detection, swap button, inline Lottie loader, voice input/output, and profanity-masked output
- **Voice translation** — speech-to-text → translate → text-to-speech, auto re-translates when you change either language. Auto-speak is gated by the global `autoSpeak` setting
- **Face-to-face conversation** — two presentation modes the user can switch between in settings:
  - **Face mode** — Ludo-style split layout, top panel rotated 180° so the person opposite reads their own language right-side-up
  - **Chat mode** — WhatsApp-style threaded bubbles
  Both modes are kept alive together via `IndexedStack` so toggling is instant. A smart speech merger (`smartMergeSpeech`) glues partial recognition results without duplicating overlap
- **Camera OCR** — capture, crop to text, translate. The big camera placeholder is itself the trigger
- **Gallery OCR** — pick an image, crop, translate. Same tap-the-icon affordance
- **Multi-script OCR** — Latin, Devanagari, Chinese, Japanese, and Korean recognizers run in parallel per language hint, then dedupe by bounding-box overlap so mixed-script signs come out clean
- **History** with search, **swipe-to-delete** on individual rows, **long-press to multi-select** with bulk delete, both with 3-second floating-snackbar Undo. Writes are gated by the `saveHistory` setting
- **Favorites** with star toggle
- **Profanity filter** — censors at input time and refuses to translate masked text
- **Material 3** light / dark / system, with a visual three-card theme picker (system shows a diagonal split). Adaptive switches and sliders so iOS sees Cupertino chrome and Android sees Material chrome
- **Settings** — defaults for source/target language, auto-speak toggle, speech rate slider, save-history toggle, conversation mode, plus a **Reset to defaults** button with a stylish destructive-red confirmation dialog that refreshes every provider's in-flight state via `applyDefaults()`
- **Settings schema migration** — bumping `AppSettings.schemaVersion` runs one-shot migrations on existing installs (current version: **3**)
- **Google AdMob** — AppOpen on cold-start and foreground resume, Banner on every screen (lazy-loaded so two stacked banners in conversation mode only request the active one), Native ads in bottom-nav tabs (padding-aware so the floating pill nav never overlaps), Interstitials on share with click-count throttle. All ad units come from a remote config endpoint and the entire layer is master-toggled by `extraParam.adsOnOff`

## Tech stack

| Concern | Package |
| --- | --- |
| State management | `provider` (ChangeNotifier) |
| Translation | `translator` (unofficial Google web endpoint) + `google_mlkit_language_id` |
| Speech | `speech_to_text` + `flutter_tts` (pre-warmed at startup) |
| OCR | `google_mlkit_text_recognition` (Latin / Devanagari / Chinese / Japanese / Korean) |
| Live camera | `camera` |
| Storage | `hive` + `hive_flutter` + `shared_preferences` (onboarding flag, ad click counter, remote-config cache) |
| Image picker / cropper | `image_picker`, `image_cropper` |
| UI / animation | `flutter_animate`, `lottie`, `google_fonts` |
| Sharing | `share_plus` |
| Ads | `google_mobile_ads` + `http` (remote config) |
| Misc | `intl`, `uuid`, `package_info_plus` |

## Project structure

```
lib/
├── main.dart                        bootstrap — Hive, TTS warm-up, Ads init, runApp
│
├── models/                          plain data classes (toMap / fromMap)
│   ├── language.dart
│   ├── translation.dart
│   ├── conversation_message.dart
│   └── app_settings.dart            schemaVersion: 3 + ConversationMode enum
│
├── services/                        stateless facades over plugins
│   ├── translator_service.dart      chunking, retry, HTML-entity decode
│   ├── speech_service.dart          onStatus / onError forwarded per session
│   ├── tts_service.dart             warm-up + per-language cache
│   └── ocr_service.dart             multi-script recognizers + dedupe
│
├── repositories/                    Hive box wrappers
│   ├── history_repository.dart      save / remove / removeMany / clear / watch
│   ├── favorites_repository.dart
│   ├── settings_repository.dart     reads + applies pending schema migrations
│   └── conversation_repository.dart
│
├── providers/                       ChangeNotifier state holders
│   ├── deps.dart                    service + repo singletons, currentAppSettings global
│   ├── settings_provider.dart       mirrors changes into currentAppSettings
│   ├── translation_provider.dart    + applyDefaults() for Reset
│   ├── voice_provider.dart          autoSpeak-gated TTS, + applyDefaults()
│   ├── conversation_provider.dart   smart speech merge, autoSpeak-gated, + applyDefaults()
│   ├── ocr_provider.dart            + applyDefaults()
│   ├── history_provider.dart        remove / removeMany / restore (undo)
│   └── favorites_provider.dart
│
├── Google_Ads/                      AdMob integration
│   ├── Config.dart                  unit-id + master toggle accessors
│   ├── ConfigController.dart        fetch + cache remote config
│   ├── ConfigModel.dart
│   ├── SpHelper.dart                shared-preferences helpers (click counts, etc.)
│   ├── ShowAds.dart                 thin presenter
│   ├── AppOpenAds/
│   │   ├── AppOpenManager.dart      load + show with one-shot guard
│   │   └── AppLifeCycleReactor.dart hooks AppStateEventNotifier
│   ├── BannerAds/
│   │   └── BannerAdManager.dart     initLoad gating for lazy load
│   ├── InterstitialAds/
│   │   └── InterstitialAdManager.dart
│   └── Native_Ads/
│       ├── NativeAdManager.dart
│       └── BottomNavSafeNativeAd.dart  padding-aware around floating nav
│
├── widgets/                         reusable UI
│   ├── primary_button.dart
│   ├── empty_state.dart
│   ├── translation_card.dart
│   ├── translation_overlay.dart
│   ├── animated_gradient.dart
│   ├── pulsing_mic.dart
│   ├── language_chip.dart
│   ├── language_picker.dart
│   └── language_swap_bar.dart
│
├── screens/
│   ├── splash.dart
│   ├── onboarding.dart
│   ├── home.dart                    animated mesh-gradient header + tile grid
│   ├── text_translate.dart
│   ├── voice_translate.dart
│   ├── conversation.dart            IndexedStack(face, chat) — both alive
│   ├── camera_translate.dart
│   ├── gallery_translate.dart
│   ├── history.dart                 swipe + long-press multi-select
│   ├── favorites.dart
│   └── settings.dart                card sections, theme picker, reset button
│
├── utils/
│   ├── constants.dart               strings, language list, box keys
│   ├── extensions.dart              BuildContext + String (profanity filter)
│   ├── speech_merge.dart            smartMergeSpeech — overlap-aware glue
│   └── theme.dart                   Material 3 light / dark themes
│
└── assets/
    └── lottie/
        └── loading_dots.json        3-dot bouncing loader, used in text + conv.
```

### How the layers talk

```
Screen → Provider → Service / Repository → Plugin / Hive
                 ↑
            currentAppSettings (global mirror of SettingsProvider)
```

- Screens watch providers via `context.watch<XProvider>()`.
- Providers hold UI state, call services/repos, and `notifyListeners()`.
- Services are stateless facades over plugins (translator, speech, TTS, OCR).
- Repositories wrap Hive boxes and return plain models.
- `currentAppSettings` is a process-global `AppSettings` populated in `main()` and kept in sync by `SettingsProvider`. Providers and ad widgets read from it directly so they don't have to thread `BuildContext` everywhere.

No DI container, no use cases, no `Either`/`Failure` ceremony — providers `try/catch` and surface `isLoading` / `error` / `result` fields directly. Race-safe operations use a monotonic `_reqId` token so stale responses can't clobber the latest one.

### Reset to defaults flow

`SettingsProvider.resetToDefaults()` rewrites the Hive settings box and refreshes `currentAppSettings`, then the Settings screen calls `applyDefaults()` on `TranslationProvider`, `OcrProvider`, `VoiceProvider`, and `ConversationProvider`. Each one re-reads `currentAppSettings.defaultSource/Target` and `notifyListeners()`, so language pickers on every screen visibly revert immediately.

## Setup

```bash
flutter pub get
flutter run
```

Minimum Flutter SDK is set in `pubspec.yaml` (`flutter: ">=3.24.0"`, `sdk: ^3.10.4`).

### Android

Supported OS range: **Android 10 (API 29) → Android 16 (API 35/36)**. Configured in `android/app/build.gradle.kts`:

```kotlin
defaultConfig {
    minSdk = 29
    targetSdk = 35
    multiDexEnabled = true
}
compileSdk = 36
compileOptions { isCoreLibraryDesugaringEnabled = true }
```

API 29 is the floor because ML Kit and modern photo-picker APIs require it; everything above degrades cleanly thanks to version-gated permissions.

R8 / ProGuard rules live in `android/app/proguard-rules.pro` — they keep ML Kit, Hive, `speech_to_text`, `flutter_tts`, `ucrop`, and `google_mobile_ads` reflection-heavy classes.

#### Native ad factory

`ListTileNativeAdFactory` (Kotlin) is registered in `MainActivity.configureFlutterEngine` under the key `"listTile"`. It themes itself from a `customOptions["isDark"]` boolean passed from Dart so native ads match the app's current theme.

#### Permissions in `android/app/src/main/AndroidManifest.xml`

```xml
<!-- Network -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Voice + conversation (speech_to_text) -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Camera OCR -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />

<!-- Gallery OCR — version-gated for all supported APIs -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />                                          <!-- Android 10–12 -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />                <!-- Android 13 -->
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />  <!-- Android 14+ -->

<!-- Notifications (user-grantable from Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

The `<application>` tag enables:

- `android:requestLegacyExternalStorage="true"` — keeps gallery access working on Android 10 devices that haven't migrated to scoped storage.
- `android:enableOnBackInvokedCallback="true"` — opts into the Android 13+ predictive-back gesture.

And declares the AdMob app id (`com.google.android.gms.ads.APPLICATION_ID`) plus the UCrop activity for image cropping:

```xml
<activity android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar" />
```

### iOS — `ios/Runner/Info.plist`

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Easy Translate uses speech recognition to convert your voice into text for translation.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Easy Translate uses the microphone for voice and conversation translation.</string>
<key>NSCameraUsageDescription</key>
<string>Easy Translate uses the camera to capture text for camera translation.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Easy Translate accesses your photo library so you can translate text from saved images.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Easy Translate can save translated images back to your photo library.</string>
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~xxxxxxxxxx</string>
<key>SKAdNetworkItems</key>
<array><!-- AdMob SKAdNetwork ids --></array>
```

#### Podfile

`MLKitVision` is pinned and the deployment target is bumped so ML Kit and `image_cropper` are happy:

```ruby
pod 'MLKitVision', '~> 7.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
```

`pod install --repo-update` after any iOS dependency change.

## Running

```bash
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter run
```

### Release APK

```bash
flutter build apk --release --split-per-abi
```

## Ads architecture

```
main() ─ MobileAds.instance.initialize()
       ├── SpHelper().initialize()                    (shared_preferences)
       ├── configController.fetchConfig()             (HTTP → remote config → cache)
       └── appOpenAdManager.loadAd()                  (preload)

AppLifecycleReactor.listenToAppStateChanges()         (resume → AppOpen)
  └── suppressAppOpenAdOnNextResume                   one-shot guard for share/picker round-trips

BannerAdManager(initLoad: bool)                       lazy-load gate
NativeAdManager                                       (with BottomNavSafeNativeAd wrapper)
InterstitialAdManager                                 click-throttled via SpHelper
```

Every accessor in `Config.dart` hits the cached `ConfigModel`; if remote config hasn't arrived yet, callers get `null`/`false` and quietly skip. `Config.showAds()` is the master kill switch — flip `extraParam.adsOnOff` server-side to silence the entire layer.

## Adding things

- **A new screen** — drop it in `lib/screens/`. If it needs state, add a `ChangeNotifier` provider under `lib/providers/`, register it in `main.dart`'s `MultiProvider`, then `context.watch<XxxProvider>()` in the screen.
- **A new reusable widget** — one class per file under `lib/widgets/`.
- **A new default value** — change it in `AppSettings`, bump `AppSettings.schemaVersion`, add an `if (from < N)` branch in `SettingsRepository._migrate` to update existing installs. If providers cache a copy of the value, add it to their `applyDefaults()` so Reset still refreshes the UI.
- **A new language** — append a `Language('code', 'Name', 'Native', '🏳')` entry to `Languages.all` in `utils/constants.dart`. The code must match the `translator` package's accepted code (Google's web endpoint). If the language needs non-Latin OCR, add the code to the relevant set in `services/ocr_service.dart` (`_devanagariLanguages`, `_chineseLanguages`, etc.).
- **A new ad slot** — add the unit id to `ConfigModel`, expose it via `Config.dart`, and place the widget. For banners that share a screen with another banner (like conversation's face/chat split), use `BannerAdManager(initLoad: isActive)` so only the visible one requests an ad.

## Notes

- The translator package is unofficial — for production traffic, swap `TranslatorService` for a paid API (Google Cloud Translation, DeepL, etc.); nothing else needs to change. `TranslatorService` already handles chunking, per-call timeouts (15 s), up to 4 retries, completeness scoring, and HTML-entity decoding.
- The profanity filter is a small English word list in `utils/extensions.dart` (`StringX.censored`). Load from remote config to cover more locales.
- Hive stores rows as plain `Map`s so models can evolve without re-running `build_runner`. Schema-breaking changes go through the `SettingsRepository` migration path.
- TTS is pre-warmed in `main()` so the first speak call after launch doesn't pay platform engine cold-start. All TTS calls outside the text-translate screen check `currentAppSettings.autoSpeak` first.
- Conversation sessions are wiped on every screen entry — long-lived transcripts live in the History screen.
- `currentAppSettings` is intentionally a mutable global. The rule is: `SettingsProvider` owns it, everyone else only reads. Reset uses `applyDefaults()` on each translation provider to push the new values into UI state.

## License

MIT.
