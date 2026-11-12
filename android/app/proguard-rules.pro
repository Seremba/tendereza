# ── flutter_local_notifications (reminders) ────────────────────────────
# R8 removes the generic type information that the plugin's Gson code reads
# at runtime. Without these rules the release build fails with
# "Missing type parameter" and reminders never appear.

-keepattributes Signature
-keepattributes *Annotation*

# Generic type tokens used by Gson
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

# The notifications plugin's own classes, including the scheduled and boot receivers
-keep class com.dexterous.** { *; }