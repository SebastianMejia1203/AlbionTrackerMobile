# Preserve the main activity and the entire package
-keep class com.albiontracker.mobile.** { *; }

# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }

# Fix for Play Core missing classes
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.tasks.**

# Flutter webview and JS
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Support for Parcelable
-keepclassmembers class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator CREATOR;
}
