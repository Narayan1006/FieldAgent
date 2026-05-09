# Flutter specific
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter deferred components use Play Core — not needed for sideloaded APK
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# MediaPipe / flutter_gemma — suppress missing proto classes
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
-dontwarn com.google.mediapipe.**
-keep class com.google.mediapipe.** { *; }
-keep interface com.google.mediapipe.** { *; }

# LiteRT / TFLite
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Google Protobuf
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Firebase / Firestore
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# SQLite
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# General Android
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# LiteRT / TFLite
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Google Protobuf
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Firebase / Firestore
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# SQLite
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# General Android
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
