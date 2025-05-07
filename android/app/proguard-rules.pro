# Keep TensorFlow Lite GPU delegate classes
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }
-keep class org.tensorflow.lite.support.** { *; }
# Keep ML Kit classes for text recognition
-keep class com.google.mlkit.vision.text.** { *; }

# Optional: Log more if debugging
-dontwarn org.tensorflow.**
