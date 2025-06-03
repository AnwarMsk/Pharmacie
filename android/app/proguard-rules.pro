# Flutter specific rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.webkit.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Rules for com.google.android.gms.auth.api.credentials (from smart_auth plugin issues)
# More aggressive keep rules to prevent obfuscation and ensure all members are kept.
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-keepnames class com.google.android.gms.auth.api.credentials.** { *; }
-keepclassmembers class com.google.android.gms.auth.api.credentials.** { *; }
-dontwarn com.google.android.gms.auth.api.credentials.**

# Fix for R8 compatibility with Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.internal.** { *; }

# Keep Google Maps classes
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-keep class com.google.maps.** { *; }

# Keep Geolocator plugin classes
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.googleapiavailability.** { *; }
-keep class com.baseflow.permissions.** { *; }

# Keep URL Launcher plugin classes
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep WebView related classes
-keep class android.webkit.** { *; }

# Keep Google Sign In classes
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Keep Kotlin Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.SerializationKt
-keep,includedescriptorclasses class com.example.dwaya_app.**$$serializer { *; }
-keepclassmembers class com.example.dwaya_app.** {
    *** Companion;
}
-keepclasseswithmembers class com.example.dwaya_app.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Security measures - remove logging and debug information in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Remove verbose and debug logs from Flutter
-assumenosideeffects class io.flutter.Log {
    public static *** v(...);
    public static *** d(...);
    public static *** i(...);
}

# General performance optimizations
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep our app-specific classes (modify the package name to match your actual app)
-keep class com.example.dwaya_app.models.** { *; }

# Add any project specific keep rules here below this line. 