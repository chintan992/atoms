# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class androidx.** { *; }
-keep class com.google.** { *; }

# Keep weather-related classes
-keep class com.example.atmos.** { *; }

# Keep widget-related classes
-keep class * extends android.appwidget.AppWidgetProvider { *; }
-keep class * extends android.app.Service { *; }

# Keep method channels and platform channels
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.EventChannel { *; }
-keep class io.flutter.plugin.common.BasicMessageChannel { *; }

# Keep HTTP client classes for API calls
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-keep class com.squareup.okhttp.** { *; }

# Keep JSON parsing classes
-keep class com.google.gson.** { *; }
-keep class org.json.** { *; }

# Keep shared preferences for settings storage
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$Editor { *; }

# Keep location services
-keep class android.location.** { *; }

# Keep notification classes if used
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }

# Keep work manager for background tasks
-keep class androidx.work.** { *; }

# General Flutter obfuscation rules
-dontwarn io.flutter.**
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep environment configuration classes
-keep class flutter_dotenv.** { *; }

# Keep enum values used in configuration
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Add any additional rules for your specific implementation
# -keep class your.specific.package.** { *; }