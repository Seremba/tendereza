# ── flutter_local_notifications (uses Gson internally) ─────────────────
# R8 strips the generic type information Gson reads at runtime. That is what
# produces "RuntimeException: Missing type parameter" in release builds
# (debug builds are not shrunk, so they hide the problem).

-keepattributes Signature
-keepattributes *Annotation*

# Retain generic signatures of TypeToken and its subclasses
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# Gson adapters
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# The notifications plugin's own classes
-keep class com.dexterous.** { *; }