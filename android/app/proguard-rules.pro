# ── Flutter / Dart ─────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# ── ML Kit text recognition ────────────────────────────────────────────────
# The text-recognition plugin references all script options (Latin, Chinese,
# Devanagari, Japanese, Korean). We only ship Latin, so R8 complains about
# the others being missing. Tell R8 to ignore those references.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep ML Kit option-builder classes (they're reflected from Kotlin).
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }

# ── Hive ───────────────────────────────────────────────────────────────────
-keep class * extends hive.flutter.HiveObject { *; }

# ── speech_to_text / flutter_tts / image_picker / image_cropper ────────────
# These plugins use reflection-heavy callbacks.
-keep class com.csdcorp.speech_to_text.** { *; }
-keep class com.tundralabs.fluttertts.** { *; }
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# ── Kotlin metadata + coroutines ───────────────────────────────────────────
-keepattributes *Annotation*, InnerClasses, Signature
-keep class kotlin.Metadata { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Required for Play Core dynamic delivery referenced by Flutter
-dontwarn com.google.android.play.core.**

# ── Google Mobile Ads (AdMob) ──────────────────────────────────────────────
# Keep the entire ads SDK — mediation adapters, ad loaders, native ad
# helpers etc. all get loaded via reflection by name. Without these, R8
# strips the classes and the SDK silently fails to load ads in release.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class com.google.android.gms.internal.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.ads.**

# Keep the google_mobile_ads Flutter plugin (covered by the io.flutter.plugins
# rule above too, but called out here for clarity).
-keep class io.flutter.plugins.googlemobileads.** { *; }
-keep interface io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin$NativeAdFactory { *; }
-keep class * implements io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin$NativeAdFactory { *; }

# ── Easy Translate native ad factories ─────────────────────────────────────
# MainActivity registers these factories by string key. R8 can't trace the
# string-key registration, so without these keeps it strips the factory
# classes and the AppOpen / Native / Banner ads never render in release.
-keep class com.example.easy_translate.MainActivity { *; }
-keep class com.example.easy_translate.ListTileNativeAdFactory { *; }
-keep class com.example.easy_translate.ExpandedNativeAdFactory { *; }
-keep class com.example.easy_translate.** extends io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin$NativeAdFactory { *; }

# Keep the ad-layout R.id constants referenced by findViewById in the
# factories. Resource IDs are normally safe, but explicit keeps prevent
# accidental stripping by aggressive R8 passes.
-keepclassmembers class com.example.easy_translate.R$id { public static <fields>; }
-keepclassmembers class com.example.easy_translate.R$layout { public static <fields>; }
