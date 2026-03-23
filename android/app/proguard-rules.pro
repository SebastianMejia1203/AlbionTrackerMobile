# Flutter webview and JS
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Firebase Core
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepnames class com.google.android.gms.measurement.AppMeasurement
-keep class com.google.android.gms.common.internal.safeparcel.SafeParcelable {
    public static final *** NULL;
}
-keepnames class * implements com.google.android.gms.common.internal.safeparcel.SafeParcelable
-keepclassmembers class * implements com.google.android.gms.common.internal.safeparcel.SafeParcelable {
    public static final *** CREATOR;
}

# Firebase Auth
-keepattributes Signature
-keepclassmembers class com.google.firebase.auth.** {*;}
-keep class com.google.android.gms.internal.firebase-auth.** { *; }

# Firestore
-keep class com.google.firebase.firestore.** { *; }

# Other common Firebase libraries
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.firebase.iid.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.remoteconfig.** { *; }
-keep class com.google.firebase.perf.** { *; }
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.database.** { *; }
-keep class com.google.firebase.storage.** { *; }

# Support for Parcelable
-keepclassmembers class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator CREATOR;
}
