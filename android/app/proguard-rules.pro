# Existing Firebase / Play Services rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google ML Kit (used by google_mlkit_text_recognition)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Specific text recognition sub-packages that R8 was removing
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**